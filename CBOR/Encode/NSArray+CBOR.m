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

extern CBORObject * CBOREncodeObject(NSObject *model, CBORMajorType major, CBORUInt64 minor);
@implementation NSArray (CBOR)

- (nullable CBORObject *)cborObject {
    return [self cborObjectWithMajor:CBORUnknownMajorType minor:CBORUnknownMajorType context:NULL];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major minor:(CBORUInt64)minor {
    return [self cborObjectWithMajor:major minor:minor context:NULL];
}

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major
                                       minor:(CBORUInt64)minor
                                     context:(CBORObject *(*)(NSObject *, CBORMajorType, CBORUInt64))context {
    if (CBORMajorTypeIsUnknown(major)) {
        return [self cborArrayWithContext:context];
    }
    
    switch (major) {
        case CBORMajorTypeArray:
            return [self cborArrayWithContext:context];
        case CBORMajorTypeTag: {
            switch (minor) {
                    // TODO: 枚举可能类型为数组的Tag
                case CBORTagTypePositiveBignum:
                case CBORTagTypeNegativeBignum: {
                    CBORObject *value = [self cborArrayWithContext:context];
                    return [[CBORTag alloc] initWithMajor:major tag:minor value:value];
                }
                default: break;
            }
        }
            
        default: break;
    }
    
    return nil;
}

- (CBORObject *)cborArrayWithContext:(CBORObject *(*)(NSObject *, CBORMajorType, CBORUInt64))context {
    CBORArray *ret = [[CBORArray alloc] initWithMajor:CBORMajorTypeArray
                                                minor:[self count]];
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

- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major minor:(CBORUInt64)minor {
    return [[self allObjects] cborObjectWithMajor:major minor:minor];
}

- (CBORObject *)cborObjectWithMajor:(CBORMajorType)major minor:(CBORUInt64)minor context:(CBORObject * _Nullable (*)(NSObject * _Nonnull __strong, CBORMajorType, CBORUInt64))context {
    return [[self allObjects] cborObjectWithMajor:major minor:minor context:context];
}

@end
