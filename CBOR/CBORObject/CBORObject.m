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

#import "CBORObject.h"
#import "CBORNumber.h"
#import "CBORArray.h"
#import "CBORMap.h"
#import "CBORTag.h"
#import "CBORSimple.h"


@implementation CBORObject

- (instancetype)initWithMajor:(CBORMajorType)major
                        minor:(CBORMinorType)minor {
    self = [super init];
    if (self) {
        _majorType = major;
        _minorType = minor;
    }
    return self;
}

- (instancetype)initWithMajor:(CBORMajorType)major {
    return [self initWithMajor:major minor:0];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone { 
    return [[[self class] allocWithZone:zone] initWithMajor:_majorType
                                                      minor:_minorType];
}

/// 转化为NS原生对象
- (nullable NSObject *)nsObject {
    NSAssert(false, @"子类实现");
    return nil;
}

/// 转化为CBOR数据
- (nullable NSData *)cborData {
    NSAssert(false, @"子类实现");
    return nil;
}


// MARK: - 扩展方法
- (NSData *)dataWithLengthOrValue:(CBORUInt64)lengthOrValue
                    minorMaxValue:(CBORByte)minorMaxValue {
    return [self dataWithLengthOrValue:lengthOrValue
                                 major:self.majorType
                                 minor:self.minorType
                         minorMaxValue:minorMaxValue
                                   raw:nil];
}

- (NSData *)dataWithLengthOrValue:(CBORUInt64)lengthOrValue
                              raw:(nullable NSData *)raw {
    return [self dataWithLengthOrValue:lengthOrValue
                                 major:self.majorType
                                 minor:self.minorType
                         minorMaxValue:CBORLengthTypeMaxValue
                                   raw:raw];
}

- (NSData *)dataWithLengthOrValue:(CBORUInt64)lengthOrValue {
    return [self dataWithLengthOrValue:lengthOrValue
                                 major:self.majorType
                                 minor:self.minorType
                         minorMaxValue:CBORLengthTypeMaxValue
                                   raw:nil];
}

- (NSData *)dataWithRaw:(NSData *)raw {
    return [self dataWithLengthOrValue:[raw length]
                                 major:self.majorType
                                 minor:self.minorType
                         minorMaxValue:CBORLengthTypeMaxValue
                                   raw:raw];
}


- (BOOL)isBreak {
    return _majorType == CBORMajorTypeAdditional && _minorType == CBORAdditionalTypeBreak;
}

- (BOOL)isEqualToCBOR:(CBORObject *)cbor {
    if (![cbor isKindOfClass:[self class]]) { return NO; }
    return self.majorType == cbor.majorType && self.minorType == self.minorType;
}


// MARK: - Private
/// 构建CBOR数据方法
///
/// - Parameters:
///   - lengthOrValue: 长度或者就是值
///   - major: 主要类型
///   - minorMaxValue: 次要类型单字节后五位最大可表示的值（定义后续长度之前）
///   - raw: 补充数据
- (NSData *)dataWithLengthOrValue:(CBORUInt64)lengthOrValue
                            major:(CBORMajorType)major
                            minor:(CBORMinorType)minor
                    minorMaxValue:(CBORByte)minorMaxValue
                              raw:(nullable NSData *)raw {
    NSMutableData *ret = [NSMutableData data];
    
    /// 此处长度类型即次要类型
    CBORLengthType minorType = CBORLengthTypeWithLengthOrMinor(lengthOrValue, minorMaxValue, minor);
    // 校验是否超出可显示范围
    if (!CBORIsLengthTypeValid(minor)) { return nil; }
    
    /// 主要类型 + 次要类型定义后续数据长度
    CBORByte type = major | minorType;
    
    [ret appendBytes:&type length:1];
    // 大端数据或长度
    [ret appendData:[self unsignedIntegerDataWithType:minorType value:lengthOrValue]];
    
    if (raw) { [ret appendData:raw]; }
    
    return ret;
}

- (NSData *)unsignedIntegerDataWithType:(CBORLengthType)type
                                  value:(CBORUInt64)value {
    NSUInteger length = CBORByteWithLenghtType(type);
    
    switch (type) {
        case CBORLengthTypeUInt8: {
            UInt8 ret = value;
            return [NSData dataWithBytes:&ret length:length];
        }
        case CBORLengthTypeUInt16: {
            UInt16 ret = CFSwapInt16HostToBig((UInt16)value);
            return [NSData dataWithBytes:&ret length:length];
        }
        case CBORLengthTypeUInt32: {
            UInt32 ret = CFSwapInt32HostToBig((UInt32)value);
            return [NSData dataWithBytes:&ret length:length];
        }
        case CBORLengthTypeUInt64: {
            UInt64 ret = CFSwapInt64HostToBig((UInt64)value);
            return [NSData dataWithBytes:&ret length:length];
        }
        default:
            return [NSData data];
    }
}


@end



