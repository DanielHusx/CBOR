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

#import "NSDate+CBOR.h"
#import "NSString+CBOR.h"
#import "CBORNumber.h"
#import "CBORTag.h"
#import "CBORArray.h"

/// 判断浮点数是否是整数
static inline bool CBORIsInteger(float value) {
    int intValue = (int)floorf(value);
    // 确定没有小数点
    return intValue == value;
}

@implementation NSDate (CBOR)

- (nullable CBORObject *)cborObject {
    CBORObject *value;
    if (CBORIsInteger([self timeIntervalSince1970])) {
        value = [[CBORNumber alloc] initWithMajor:CBORMajorTypeUnsigned
                                    unsignedValue:[self timeIntervalSince1970]];
    } else {
        value = [[CBORNumber alloc] initWithMajor:CBORMajorTypeAdditional
                                            minor:CBORAdditionalTypeDouble
                                       floatValue:[self timeIntervalSince1970]];
    }
    return [[CBORTag alloc] initWithMajor:CBORMajorTypeTag
                                      tag:CBORTagTypeEpochBasedDateTime
                                    value:value];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major
                                       minor:(CBORMinorType)minor {
    if (CBORMajorTypeIsUnknown(major)) { return [self cborObject]; }
    
    CBORMajorType majorType = CBORTypeMajor(major);
    
    switch (majorType) {
        case CBORMajorTypeUnsigned: {
            return [[CBORNumber alloc] initWithMajor:majorType
                                               minor:minor
                                       unsignedValue:[self timeIntervalSince1970]];
        }
        case CBORMajorTypeString: {
            return [[CBORArray alloc] initWithMajor:majorType
                                              minor:minor
                                              value:[[CBORISODateFormatter() stringFromDate:self] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        case CBORMajorTypeAdditional: {
            CBORMinorType minorType = CBORTypeMinor(minor);
            
            switch (minorType) {
                case CBORAdditionalTypeFloat:
                case CBORAdditionalTypeDouble:
                    return [[CBORNumber alloc] initWithMajor:majorType
                                                       minor:minorType
                                                  floatValue:[self timeIntervalSince1970]];
                default:
                    return nil;
            }
        }
        case CBORMajorTypeTag: {
            CBORTagType tag = minor;
            CBORMinorType minorType = CBORTypeMinor(major);
            
            switch (tag) {
                case CBORTagTypeStandardDateTimeString: {
                    CBORObject *value = [[CBORISODateFormatter() stringFromDate:self] cborObjectWithMajor:CBORMajorTypeString
                                                                                                    minor:minorType];
                    return [[CBORTag alloc] initWithMajor:majorType
                                                      tag:tag
                                                    value:value];
                }
                case CBORTagTypeEpochBasedDateTime: {
                    CBORObject *value = [[CBORNumber alloc] initWithMajor:CBORMajorTypeAdditional
                                                                    minor:CBORAdditionalTypeDouble
                                                               floatValue:[self timeIntervalSince1970]];
                    return [[CBORTag alloc] initWithMajor:majorType
                                                      tag:tag
                                                    value:value];
                }
                default:
                    return nil;
            }
        }
        default:
            return nil;
    }
}

@end
