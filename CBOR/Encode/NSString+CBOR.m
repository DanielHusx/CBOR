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

#import "NSString+CBOR.h"
#import "CBORArray.h"
#import "CBORTag.h"

@implementation NSString (CBOR)

- (nullable CBORObject *)cborObject {
    return [[CBORArray alloc] initWithMajor:CBORMajorTypeString
                                      value:[self dataUsingEncoding:NSUTF8StringEncoding]];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major minor:(CBORUInt64)minor {
    if (CBORMajorTypeIsUnknown(major)) { return [self cborObject]; }
    
    CBORObject *value = [[CBORArray alloc] initWithMajor:CBORMajorTypeString
                                                   value:[self dataUsingEncoding:NSUTF8StringEncoding]];
    switch (major) {
        case CBORMajorTypeString:
            return value;
        case CBORMajorTypeTag: {
            switch (minor) {
                case CBORTagTypeStandardDateTimeString:
                case CBORTagTypeURI:
                case CBORTagTypeBase64URL:
                case CBORTagTypeBase64:
                case CBORTagTypeRegularExpression:
                case CBORTagTypeMIMEMessage:
                case CBORTagTypeSelfDescribeCBOR:
                    return [[CBORTag alloc] initWithMajor:CBORMajorTypeTag
                                                      tag:minor
                                                    value:value];
                default:
                    return nil;
            }
        }
        default:
            return nil;
    }
}

@end


@implementation NSAttributedString (CBOR)

- (nullable CBORObject *)cborObject {
    return [[self string] cborObject];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major minor:(CBORUInt64)minor {
    return [[self string] cborObjectWithMajor:major minor:minor];
}

@end


@implementation NSURL (CBOR)

- (nullable CBORObject *)cborObject {
    return [[self absoluteString] cborObjectWithMajor:CBORMajorTypeTag
                                                minor:CBORTagTypeURI];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major minor:(CBORUInt64)minor {
    if (CBORMajorTypeIsUnknown(major)) { return [self cborObject]; }
    
    switch (major) {
        case CBORMajorTypeTag: {
            switch (minor) {
                case CBORTagTypeURI:
                case CBORTagTypeBase64URL:
                    return [[self absoluteString] cborObjectWithMajor:major
                                                                minor:minor];
                    
                default:
                    return nil;
            }
        }
        default:
            return nil;
    }
}

@end
