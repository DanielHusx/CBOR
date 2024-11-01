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

#import "NSData+CBOR.h"
#import "CBORArray.h"
#import "CBORTag.h"

@implementation NSData (CBOR)

- (nullable CBORObject *)cborObject {
    return [[CBORArray alloc] initWithMajor:CBORMajorTypeBytes
                                      value:self];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major
                                       minor:(CBORMinorType)minor {
    if (CBORMajorTypeIsUnknown(major)) { return [self cborObject]; }
    
    CBORMajorType majorType = CBORTypeMajor(major);
    
    switch (majorType) {
        case CBORMajorTypeBytes:
            return [[CBORArray alloc] initWithMajor:majorType
                                              minor:minor
                                              value:self];
        case CBORMajorTypeTag: {
            CBORTagType tag = minor;
            CBORMinorType minorType = CBORTypeMinor(major);
            
            switch (tag) {
                case CBORTagTypePositiveBignum:
                case CBORTagTypeNegativeBignum:
                case CBORTagTypeEncodedCBORDataItem:
                case CBORTagTypeUUID: {
                    CBORObject *value = [[CBORArray alloc] initWithMajor:CBORMajorTypeBytes
                                                                   minor:minorType
                                                                   value:self];
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
