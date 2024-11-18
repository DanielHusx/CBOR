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

#import "NSNumber+CBOR.h"
#import "CBORNumber.h"
#import "CBORSimple.h"
#import "CBORTag.h"

/// NSNumber内值编码类型
typedef NS_ENUM(NSUInteger, CBORNumberEncodingType) {
    /// 未知类型
    CBORNumberEncodingTypeUnknown,
    /// (signed) char, Bool
    CBORNumberEncodingTypeCharOrBool,
    /// unsigned char, UInt8
    CBORNumberEncodingTypeUnsignedChar,
    
    /// (signed) short
    CBORNumberEncodingTypeShort,
    /// unsigned short, UInt16
    CBORNumberEncodingTypeUnsignedShort,
    
    /// (signed) int
    CBORNumberEncodingTypeInt,
    /// unsigned int
    CBORNumberEncodingTypeUnsignedInt,
    
    /// long, long long, NSInteger
    CBORNumberEncodingTypeLong,
    /// unsigned long, UInt32, UInt64
    CBORNumberEncodingTypeUnsignedLong,
    
    /// float Float32
    CBORNumberEncodingTypeFloat,
    /// double Float64
    CBORNumberEncodingTypeDouble,
};

/// 读取NSNumber内的值类型
static CBORNumberEncodingType CBORNumberEncodingTypeWithNumber(NSNumber *number) {
    NSString *typeString = [NSString stringWithFormat:@"%s", [number objCType]];
    
    static NSDictionary *typeMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        typeMap = @{
            [NSString stringWithFormat:@"%s", @encode(char)]: @(CBORNumberEncodingTypeCharOrBool),
            [NSString stringWithFormat:@"%s", @encode(unsigned char)]: @(CBORNumberEncodingTypeUnsignedChar),
            
            [NSString stringWithFormat:@"%s", @encode(short)]: @(CBORNumberEncodingTypeShort),
            [NSString stringWithFormat:@"%s", @encode(unsigned short)]: @(CBORNumberEncodingTypeUnsignedShort),
            
            [NSString stringWithFormat:@"%s", @encode(int)]: @(CBORNumberEncodingTypeInt),
            [NSString stringWithFormat:@"%s", @encode(unsigned int)]: @(CBORNumberEncodingTypeUnsignedInt),
            
            [NSString stringWithFormat:@"%s", @encode(long)]: @(CBORNumberEncodingTypeLong),
            [NSString stringWithFormat:@"%s", @encode(unsigned long)]: @(CBORNumberEncodingTypeUnsignedLong),
            
            [NSString stringWithFormat:@"%s", @encode(float)]: @(CBORNumberEncodingTypeFloat),
            [NSString stringWithFormat:@"%s", @encode(double)]: @(CBORNumberEncodingTypeDouble),
            
        };
    });
    
    NSNumber *type = typeMap[typeString];
    if (type) { return [type unsignedLongValue]; }
    
    return CBORNumberEncodingTypeUnknown;
}


@implementation NSNumber (CBOR)

- (nullable CBORObject *)cborObject {
    return [self cborObjectWithMinor:CBORUnknownMinorType];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major minor:(CBORMinorType)minor {
    if (CBORMajorTypeIsUnknown(major)) { return [self cborObject]; }
    
    CBORMajorType majorType = CBORTypeMajor(major);
    
    switch (majorType) {
        case CBORMajorTypeUnsigned: {
            // 正整数
            UInt64 value = [self unsignedLongLongValue];
            return [[CBORNumber alloc] initWithMajor:majorType
                                               minor:minor
                                       unsignedValue:value];
        case CBORMajorTypeNegative: {
            UInt64 value = [self unsignedLongLongValue];
            
            if ([self longLongValue] >= 0) {
                // 正整数
                return [[CBORNumber alloc] initWithMajor:CBORMajorTypeUnsigned
                                           unsignedValue:value];
            } else {
                // 负整数
                value = ~value;
                return [[CBORNumber alloc] initWithMajor:CBORMajorTypeNegative
                                           unsignedValue:value];
            }
        }
        case CBORMajorTypeAdditional: {
            CBORMinorType minorType = CBORTypeMinor(minor);
            
            switch (minorType) {
                case CBORAdditionalTypeTrue:
                case CBORAdditionalTypeFalse:
                    // 布尔
                    return [[CBORSimple alloc] initWithMajor:majorType
                                                       minor:[self boolValue] ? CBORAdditionalTypeTrue: CBORAdditionalTypeFalse];
                case CBORAdditionalTypeHalf:
                case CBORAdditionalTypeFloat:
                    return [[CBORNumber alloc] initWithMajor:majorType
                                                       minor:minorType
                                                  floatValue:[self floatValue]];
                case CBORAdditionalTypeDouble:
                    return [[CBORNumber alloc] initWithMajor:majorType
                                                       minor:minorType
                                                  floatValue:[self doubleValue]];
                default: {
                    UInt64 value = [self unsignedLongLongValue];
                    if (!CBORIsSimpleValue(value)) { return nil; }
                    // 简单值
                    return [[CBORNumber alloc] initWithMajor:majorType
                                               unsignedValue:value];
                }
            }
        }
        case CBORMajorTypeTag: {
            CBORTagType tag = minor;
            CBORMinorType minorType = CBORTypeMinor(major);
            
            switch (tag) {
                case CBORTagTypeEpochBasedDateTime: // 时间戳
                case CBORTagTypeDaysSinceEpochDate: /* 自1970-1-1天数差 */ {
                    return [[CBORTag alloc] initWithMajor:majorType
                                                      tag:tag
                                                    value:[self cborObjectWithMinor:minorType]];
                }
                    // 后续可能更多Tag需要用到此类型
                default:
                    return nil;
            }
        }
        default:
            return nil;
        }
            
    }
}

- (nullable CBORObject *)cborObjectWithMinor:(CBORMinorType)minor {
    CBORNumberEncodingType type = CBORNumberEncodingTypeWithNumber(self);
    if (type == CBORNumberEncodingTypeUnknown) { return nil; }
    
    switch (type) {
        case CBORNumberEncodingTypeFloat:
        case CBORNumberEncodingTypeDouble:
            return [[CBORNumber alloc] initWithMajor:CBORMajorTypeAdditional
                                          floatValue:[self doubleValue]];
        case CBORNumberEncodingTypeCharOrBool:
            return [[CBORSimple alloc] initWithMajor:CBORMajorTypeAdditional
                                               minor:[self boolValue] ? CBORAdditionalTypeTrue: CBORAdditionalTypeFalse];
        case CBORNumberEncodingTypeUnsignedChar:
        case CBORNumberEncodingTypeUnsignedShort:
        case CBORNumberEncodingTypeUnsignedInt:
        case CBORNumberEncodingTypeUnsignedLong: {
            // 正整数
            UInt64 value = [self unsignedLongLongValue];
            return [[CBORNumber alloc] initWithMajor:CBORMajorTypeUnsigned
                                               minor:minor
                                       unsignedValue:value];
        }
        default: {
            UInt64 value = [self unsignedLongLongValue];
            if ([self longLongValue] >= 0) {
                // 正整数
                return [[CBORNumber alloc] initWithMajor:CBORMajorTypeUnsigned
                                                   minor:minor
                                           unsignedValue:value];
            } else {
                // 负整数
                value = ~value;
                return [[CBORNumber alloc] initWithMajor:CBORMajorTypeNegative
                                                   minor:minor
                                           unsignedValue:value];
            }
        }
        
    }
    return nil;
}


@end
