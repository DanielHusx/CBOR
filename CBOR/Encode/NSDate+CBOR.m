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

@implementation NSDate (CBOR)

- (nullable CBORObject *)cborObject {
//    return [[CBORNumber alloc] initWithMajor:CBORMajorTypeAdditional
//                                       minor:CBORAdditionalTypeDouble
//                                  floatValue:[self timeIntervalSince1970]];
    CBORObject *value = [[CBORNumber alloc] initWithMajor:CBORMajorTypeUnsigned
                                            unsignedValue:[self timeIntervalSince1970]];
    return [[CBORTag alloc] initWithMajor:CBORMajorTypeTag
                                      tag:CBORTagTypeEpochBasedDateTime
                                    value:value];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major minor:(CBORUInt64)minor {
    if (CBORMajorTypeIsUnknown(major)) { return [self cborObject]; }
    
    switch (major) {
        case CBORMajorTypeUnsigned: {
            // 特殊类型只为了让NSDate作为Epoch时间可以为整数类型
            CBORObject *value = [[CBORNumber alloc] initWithMajor:major
                                                    unsignedValue:[self timeIntervalSince1970]];
            return [[CBORTag alloc] initWithMajor:CBORMajorTypeTag
                                              tag:CBORTagTypeEpochBasedDateTime
                                            value:value];
        }
        case CBORMajorTypeAdditional: {
            CBORMinorType minorType = CBORTypeMinor(minor);
            
            switch (minorType) {
                case CBORAdditionalTypeFloat:
                case CBORAdditionalTypeDouble:
                    return [[CBORNumber alloc] initWithMajor:major
                                                       minor:minorType
                                                  floatValue:[self timeIntervalSince1970]];
                default:
                    return nil;
            }
        }
        case CBORMajorTypeTag: {
            switch (minor) {
                case CBORTagTypeStandardDateTimeString: {
                    CBORObject *value = [[CBORISODateFormatter() stringFromDate:self] cborObjectWithMajor:major
                                                                                                    minor:minor];
                    return [[CBORTag alloc] initWithMajor:major
                                                      tag:minor
                                                    value:value];
                }
                case CBORTagTypeEpochBasedDateTime: {
                    CBORObject *value = [[CBORNumber alloc] initWithMajor:CBORMajorTypeAdditional
                                                                    minor:CBORAdditionalTypeDouble
                                                               floatValue:[self timeIntervalSince1970]];
                    return [[CBORTag alloc] initWithMajor:major
                                                      tag:minor
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
