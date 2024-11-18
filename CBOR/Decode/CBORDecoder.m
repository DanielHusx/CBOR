// refer: https://github.com/DanielHusx/CBOR
//
// MIT License
//
// Copyright (c) 2024 Daniel
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "CBORDecoder.h"
#import "CBORConstant.h"
#import "CBORStream.h"
#import "CBORNumber.h"
#import "CBORArray.h"
#import "CBORMap.h"
#import "CBORTag.h"
#import "CBORSimple.h"

/// 次要类型是否是不定长
static inline bool CBORMinorIsIndefinite(CBORByte minor) {
    return minor == CBORAdditionalTypeIndefinite;
}

/// 次要类型是否处于可用数据区间内
static inline bool CBORMinorIsInValueRange(CBORByte minor) {
    // 0x00~0x1b
    return minor >= 0 && minor <= CBORLengthTypeMaxDefined;
}


/// 根据次要类型读取长度或实际值
static BOOL CBORReadValueOrLength(CBORStream *stream, CBORMinorType minor, CBORUInt64 *value) {
    if (minor <= CBORLengthTypeMaxValue) {
        if (value) *value = minor;
        return YES;
    }
    
    CBORLengthType type = CBORLengthTypeWithMinor(minor);
    switch (type) {
        case CBORLengthTypeUInt8:
        case CBORLengthTypeUInt16:
        case CBORLengthTypeUInt32:
        case CBORLengthTypeUInt64:
            return [stream popBytes:value length:(type & 0x3) + 1];
        default:
            return NO;
    }
}

static CBORObject * CBORMapUntilBreak(CBORStream *stream, CBORMajorType major);
static CBORObject * CBORArrayUntilBreak(CBORStream *stream, CBORMajorType major, BOOL shouldElementEqualToMajor);


/// 数据转CBOR
static CBORObject * CBORDecodeData(CBORStream *stream) {
    CBORByte byte = 0;
    if (![stream popUInt8:&byte]) { return nil; }
    
    CBORMajorType majorType = CBORTypeMajor(byte);
    CBORByte minorType = CBORTypeMinor(byte);
    
    switch (majorType) {
            // 非负整数，负整数
        case CBORMajorTypeUnsigned:
        case CBORMajorTypeNegative: {
            if (!CBORMinorIsInValueRange(minorType)) { return nil; }
            
            CBORUInt64 value;
            if (!CBORReadValueOrLength(stream, minorType, &value)) { return nil; }
            
            return [[CBORNumber alloc] initWithMajor:majorType
                                               minor:minorType
                                       unsignedValue:value];
        }
        
            // 字节数组 & UTF8字符串
        case CBORMajorTypeBytes:
        case CBORMajorTypeString: {
            // 不定长
            if (CBORMinorIsIndefinite(minorType)) {
                return CBORArrayUntilBreak(stream, majorType, YES);
            }
            
            if (!CBORMinorIsInValueRange(minorType)) { return nil; }
            
            CBORUInt64 length;
            if (!CBORReadValueOrLength(stream, minorType, &length)) { return nil; }
            
            NSData *value;
            if (![stream popDataWithLength:length data:&value]) { return nil; }
            if (!value) { return nil; }
            
            return [[CBORArray alloc] initWithMajor:majorType
                                              minor:minorType
                                              value:value];
        }
            // 数组
        case CBORMajorTypeArray: {
            // 不定长
            if (CBORMinorIsIndefinite(minorType)) {
                return CBORArrayUntilBreak(stream, majorType, NO);
            }
            
            CBORUInt64 length;
            if (!CBORReadValueOrLength(stream, minorType, &length)) { return nil; }
            
            CBORArray *ret = [[CBORArray alloc] initWithMajor:majorType
                                                        minor:minorType];
            
            for (UInt64 index = 0; index < length; index++) {
                CBORObject *cbor = CBORDecodeData(stream);
                
                if (!cbor) { return nil; }
                [ret addCBOR:cbor];
            }
            
            return ret;
        }
            // 键值对
        case CBORMajorTypeMap: {
            // 不定长
            if (CBORMinorIsIndefinite(minorType)) {
                return CBORMapUntilBreak(stream, majorType);
            }
            
            if (!CBORMinorIsInValueRange(minorType)) { return nil; }
            
            CBORUInt64 length = 0;
            if (!CBORReadValueOrLength(stream, minorType, &length)) { return nil; }
            
            CBORMap *ret = [[CBORMap alloc] initWithMajor:majorType minor:minorType];
            
            for (CBORUInt64 index = 0; index < length; index++) {
                CBORObject *key = CBORDecodeData(stream);
                if (!key) { return nil; }
                
                CBORObject *value = CBORDecodeData(stream);
                if (!value) { return nil; }
                
                ret[key] = value;
            }
            
            return ret;
        }
            // 扩展类型
        case CBORMajorTypeTag: {
            if (!CBORMinorIsInValueRange(minorType)) { return nil; }
            
            CBORTagType tag;
            if (!CBORReadValueOrLength(stream, minorType, &tag)) { return nil; }
            
            CBORObject *value = CBORDecodeData(stream);
            
            if (!value) { return nil; }
            
            return [[CBORTag alloc] initWithMajor:majorType
                                              tag:tag
                                            value:value];
        }
            // 浮点数或简单类型
        case CBORMajorTypeAdditional: {
            switch (minorType) {
                case CBORAdditionalTypeHalf: {
                    Float16 value = 0;
                    if (![stream popFloat16:&value]) { return nil; }
                    
                    // 解码时的值需要转化，所以传无符号整数进一步内部转化为半精度
                    return [[CBORNumber alloc] initWithMajor:majorType
                                                       minor:minorType
                                               unsignedValue:value];
                }
                case CBORAdditionalTypeFloat: {
                    Float32 value = 0;
                    if (![stream popFloat32:&value]) { return nil; }
                    
                    return [[CBORNumber alloc] initWithMajor:majorType
                                                       minor:minorType
                                                  floatValue:value];
                }
                case CBORAdditionalTypeDouble: {
                    Float64 value = 0;
                    if (![stream popFloat64:&value]) { return nil; }
                    
                    return [[CBORNumber alloc] initWithMajor:majorType
                                                       minor:minorType
                                                  floatValue:value];
                }
                case CBORAdditionalTypeBreak:
                case CBORAdditionalTypeNull:
                case CBORAdditionalTypeFalse:
                case CBORAdditionalTypeTrue:
                case CBORAdditionalTypeUndefined:
                    return  [[CBORSimple alloc] initWithMajor:majorType
                                                        minor:minorType];
                default: {
                    // 简单值
                    CBORUInt64 value;
                    if (!CBORReadValueOrLength(stream, minorType, &value)) { return nil; }
                    // 是否处于简单值区间
                    if (!CBORIsSimpleValue(value)) { return nil; }
                    
                    return [[CBORNumber alloc] initWithMajor:majorType
                                                       minor:minorType
                                               unsignedValue:value];
                    
                }
                    
            }
        }
        default:
            return nil;
    }
    return nil;
}

/// 读取不定长
static NSArray * CBORObjectsUntilBreak(CBORStream *stream) {
    NSMutableArray *ret = [NSMutableArray array];
    CBORObject *cbor;
    
    do {
        cbor = CBORDecodeData(stream);
        
        if (!cbor) { return nil; }
        if ([cbor isBreak]) { break; }
        
        [ret addObject:cbor];
        
    } while (YES);
    
    return ret;
}

/// 读取不定长键值对
/// - Parameters:
///   - stream: 输入流
///   - major: 主要类型
static CBORObject * CBORMapUntilBreak(CBORStream *stream, CBORMajorType major) {
    CBORMap *ret = [[CBORMap alloc] initWithMajor:major];
    
    CBORObject *key;
    CBORObject *value;
    
    do {
        key = CBORDecodeData(stream);
        if (!key) { return nil; }
        // Key识别终止则不定长结束循环
        if ([key isBreak]) { break; }
        
        value = CBORDecodeData(stream);
        // Value终止属于异常情况
        if (!value || [value isBreak]) { return nil; }
        
        ret[key] = value;
        
    } while (YES);
    
    return ret;
}

/// 读取不定长数组
/// - Parameters:
///   - stream: 输入流
///   - major: 主要类型
///   - shouldElementEqualToMajor: 是否限制子元素必须与主要类型一致
static CBORObject * CBORArrayUntilBreak(CBORStream *stream, CBORMajorType major, BOOL shouldElementEqualToMajor) {
    NSArray *items = CBORObjectsUntilBreak(stream);
    CBORArray *ret = [[CBORArray alloc] initWithMajor:major];
    
    for (CBORArray *item in items) {
        // 字节数组限制子元素必须与主要类型一致
        if (shouldElementEqualToMajor && [item majorType] != major) { return nil; }
        
        [ret addCBOR:item];
    }
    
    return ret;
}


@implementation CBORDecoder

+ (CBORObject *)decodeData:(NSData *)aData {
    CBORStream *stream = [[CBORStream alloc] initWithData:aData];
    CBORObject *ret = CBORDecodeData(stream);
    
    return ret;
}


/*
/// 循环解码
- (nullable CBORObject *)decodeCBOR:(CBORStream *)stream {
    CBORByte byte = [stream popUInt8];
    CBORMajorType majorType = byte & CBORMaskMajor;
    CBORByte minorType = byte & CBORMaskMinor;
    
    switch (majorType) {
            // 非负整数，负整数
        case CBORMajorTypeUnsigned:
        case CBORMajorTypeNegative: {
            if (!CBORMinorIsInValueRange(minorType)) { return nil; }
            
            UInt64 value = [self readValueOrLength:stream minor:minorType];
            return [[CBORNumber alloc] initWithMajor:majorType
                                               minor:minorType
                                       unsignedValue:value];
        }
        
            // 字节数组 & UTF8字符串
        case CBORMajorTypeBytes:
        case CBORMajorTypeString: {
            // 不定长
            if (CBORMinorIsIndefinite(minorType)) {
                return [self readArrayUntilBreak:stream
                                           major:majorType
                       shouldElementEqualToMajor:YES];
            }
            
            return [self readContent:stream major:majorType minor:minorType];
        }
            // 数组
        case CBORMajorTypeArray: {
            // 不定长
            if (CBORMinorIsIndefinite(minorType)) {
                return [self readArrayUntilBreak:stream
                                           major:majorType
                       shouldElementEqualToMajor:NO];;
            }
            
            return [self readArray:stream major:majorType minor:minorType];
        }
            // 键值对
        case CBORMajorTypeMap: {
            // 不定长
            if (CBORMinorIsIndefinite(minorType)) {
                return [self readMapUntilBreak:stream major:majorType];
            }
            
            return [self readMap:stream major:majorType minor:minorType];
        }
            // 扩展类型
        case CBORMajorTypeTag: {
            return [self readTag:stream major:majorType minor:minorType];
        }
            // 浮点数或简单类型
        case CBORMajorTypeAdditional: {
            return [self readAdditional:stream major:majorType minor:minorType];
        }
        default:
            return nil;
    }
}

/// 读取无符号整数或长度数据
- (UInt64)readValueOrLength:(CBORStream *)stream minor:(CBORByte)value {
    if (value <= CBORLengthTypeMaxValue) { return value; }
    
    CBORLengthType type = CBORLengthTypeWithMinor(value);
    switch (type) {
        case CBORLengthTypeUInt8: return [stream popUInt8];
        case CBORLengthTypeUInt16: return [stream popUInt16];
        case CBORLengthTypeUInt32: return [stream popUInt32];
        case CBORLengthTypeUInt64: return [stream popUInt64];
        default:
            NSLog(@"daniel: [Decode] 长度类型不支持: %llu", value);
            return 0;
    }
}

/// 一直读取到结束符
- (NSArray <CBORObject *> *)readUntilBreak:(CBORStream *)stream {
    NSMutableArray *ret = [NSMutableArray array];
    CBORObject *cbor;
    
    do {
        cbor = [self decodeCBOR:stream];
        
        if (!cbor) { return nil; }
        if ([cbor isBreak]) { break; }
        
        [ret addObject:cbor];
        
    } while (YES);
    
    return ret;
}


// MARK: - 数组
/// 读取字节数组或字符串
- (nullable CBORObject *)readContent:(CBORStream *)stream
                               major:(CBORMajorType)major
                               minor:(CBORByte)minor {
    if (!CBORMinorIsInValueRange(minor)) { return nil; }
    
    UInt64 length = [self readValueOrLength:stream minor:minor];
    NSData *value = [stream popDataWithLength:length];
    if (!value) { return nil; }
    
    return [[CBORArray alloc] initWithMajor:major
                                      minor:minor
                                      value:value];
}

/// 读取数组
- (nullable CBORObject *)readArray:(CBORStream *)stream
                             major:(CBORMajorType)major
                             minor:(CBORByte)minor {
    if (!CBORMinorIsInValueRange(minor)) { return nil; }
    
    UInt64 length = [self readValueOrLength:stream minor:minor];
    CBORArray *ret = [[CBORArray alloc] initWithMajor:major minor:minor];
    
    for (UInt64 index = 0; index < length; index++) {
        CBORObject *cbor = [self decodeCBOR:stream];
        if (!cbor) { return nil; }
        
        [ret addCBOR:cbor];
    }
    return ret;
}

/// 不定长数组（字节/字符串/其他内容）
/// - Parameters:
///   - major: 主要类型
///   - shouldElementEqualToMajor: 是否要求子元素与主要类型一致
- (nullable CBORObject *)readArrayUntilBreak:(CBORStream *)stream
                                       major:(CBORMajorType)major
                           shouldElementEqualToMajor:(BOOL)shouldElementEqualToMajor {
    NSArray *items = [self readUntilBreak:stream];
    CBORArray *ret = [[CBORArray alloc] initWithMajor:major];
    
    for (CBORArray *item in items) {
        // 字节数组限制子元素必须是自身
        if (shouldElementEqualToMajor && [item majorType] != major) { return nil; }
        
        [ret addCBOR:item];
    }
    
    return ret;
}


// MARK - 键值对
/// 读取键值对
- (nullable CBORObject *)readMap:(CBORStream *)stream
                           major:(CBORMajorType)major
                           minor:(CBORByte)minor {
    if (!CBORMinorIsInValueRange(minor)) { return nil; }
    
    UInt64 length = [self readValueOrLength:stream minor:minor];
    CBORMap *ret = [[CBORMap alloc] initWithMajor:major minor:minor];
    
    for (UInt64 index = 0; index < length; index++) {
        CBORObject *key = [self decodeCBOR:stream];
        if (!key) { return nil; }
        
        CBORObject *value = [self decodeCBOR:stream];
        if (!value) { return nil; }
       
        ret[key] = value;
    }
    
    return ret;
}

/// 读取不定长键值对
- (nullable CBORObject *)readMapUntilBreak:(CBORStream *)stream
                                     major:(CBORMajorType)major {
    CBORMap *ret = [[CBORMap alloc] initWithMajor:major];
    
    CBORObject *key;
    CBORObject *value;
    
    do {
        key = [self decodeCBOR:stream];
        if (!key) { return nil; }
        if ([key isBreak]) { break; }
        
        value = [self decodeCBOR:stream];
        if (!value || [value isBreak]) { return nil; }
        
        ret[key] = value;
    } while (YES);
    
    return ret;
}


// MARK: - 扩展类型
/// 读取扩展类型
- (nullable CBORObject *)readTag:(CBORStream *)stream
                           major:(CBORMajorType)major
                           minor:(CBORByte)minor {
    if (!CBORMinorIsInValueRange(minor)) { return nil; }
    
    CBORTagType tag = [self readValueOrLength:stream minor:minor];
    CBORObject *value = [self decodeCBOR:stream];
    
    if (!value) { return nil; }
    
    return [[CBORTag alloc] initWithMajor:major tag:tag value:value];
}


// MARK: - 附加类型
/// 读取附加类型（浮点数或简单类型）
- (nullable CBORObject *)readAdditional:(CBORStream *)stream
                                  major:(CBORMajorType)major
                                  minor:(CBORByte)minor {
    switch (minor) {
        case CBORAdditionalTypeHalf:
            return [[CBORNumber alloc] initWithMajor:major
                                               minor:minor
                                       unsignedValue:[stream popFloat16]];
        case CBORAdditionalTypeFloat:
            return [[CBORNumber alloc] initWithMajor:major
                                               minor:minor
                                          floatValue:[stream popFloat32]];
        case CBORAdditionalTypeDouble:
            return [[CBORNumber alloc] initWithMajor:major
                                               minor:minor
                                          floatValue:[stream popFloat64]];
        default: {
            // 简单值
            CBORUInt64 value = [self readValueOrLength:stream minor:minor];
            // 是否处于简单值区间
            if (CBORIsSimpleValue(value)) {
                return [[CBORNumber alloc] initWithMajor:major
                                                   minor:minor
                                           unsignedValue:value];
            }
            
            // 其他已定义也好未定义也好都可以构建成简单类型
            return [[CBORSimple alloc] initWithMajor:major
                                               minor:minor];
        }
            
    }
}
*/


@end
