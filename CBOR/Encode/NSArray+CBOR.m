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

#import "NSArray+CBOR.h"
#import "CBORArray.h"
#import "CBORTag.h"

@implementation NSArray (CBOR)

- (nullable CBORObject *)cborObject {
    return [self cborObjectWithMajor:CBORUnknownMajorType
                               minor:CBORUnknownMinorType
                             context:NULL];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major
                                       minor:(CBORMinorType)minor {
    return [self cborObjectWithMajor:major
                               minor:minor
                             context:NULL];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major
                                       minor:(CBORUInt64)minor
                                     context:(CBORObject *(*)(NSObject *, CBORMajorType, CBORUInt64))context {
    if (CBORMajorTypeIsUnknown(major)) {
        return [self cborArrayWithMinor:CBORUnknownMinorType
                                context:context];
    }
    
    CBORMajorType majorType = CBORTypeMajor(major);
    
    switch (majorType) {
        case CBORMajorTypeArray:
            return [self cborArrayWithMinor:minor
                                    context:context];
        case CBORMajorTypeTag: {
            CBORTagType tag = minor;
            CBORMinorType minorType = CBORTypeMinor(major);
            
            switch (tag) {
                    // 枚举可能类型为数组的Tag
                case CBORTagTypeDecimalFraction:
                case CBORTagTypeBigfloat: {
                    CBORObject *value = [self cborArrayWithMinor:minorType
                                                         context:context];
                    return [[CBORTag alloc] initWithMajor:majorType
                                                      tag:tag
                                                    value:value];
                }
                default: break;
            }
        }
            
        default: break;
    }
    
    return nil;
}

- (CBORObject *)cborArrayWithMinor:(CBORMinorType)minor
                           context:(CBORObject *(*)(NSObject *, CBORMajorType, CBORUInt64))context {
    CBORArray *ret = [[CBORArray alloc] initWithMajor:CBORMajorTypeArray
                                                minor:minor];
    for (NSObject *item in self) {
        CBORObject *cbor = context(item, CBORUnknownMajorType, CBORUnknownMinorType);
        if (!cbor) { return nil; }
        
        [ret addCBOR:cbor];
    }
    
    return ret;
}


@end

@implementation NSSet (CBOR)

- (nullable CBORObject *)cborObject {
    return [[self allObjects] cborObject];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major
                                       minor:(CBORMinorType)minor {
    return [[self allObjects] cborObjectWithMajor:major
                                            minor:minor];
}

- (CBORObject *)cborObjectWithMajor:(CBORMajorType)major
                              minor:(CBORMinorType)minor
                            context:(CBORObject * _Nullable (*)(NSObject * _Nonnull __strong, CBORMajorType, CBORUInt64))context {
    return [[self allObjects] cborObjectWithMajor:major
                                            minor:minor
                                          context:context];
}

@end
