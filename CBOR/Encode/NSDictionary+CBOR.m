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

#import "NSDictionary+CBOR.h"
#import "CBORMap.h"

@implementation NSDictionary (CBOR)

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
        return [self cborMapWithMinor:minor
                              context:context];
    }
    
    CBORMajorType majorType = CBORTypeMajor(major);
    
    switch (majorType) {
        case CBORMajorTypeMap:
            return [self cborMapWithMinor:minor context:context];
            // 后续可能有Tag也能使用此类型
        default:
            return nil;
    }
}

- (CBORObject *)cborMapWithMinor:(CBORMinorType)minor context:(CBORObject *(*)(NSObject *, CBORMajorType, CBORUInt64))context {
    __block CBORMap *ret = [[CBORMap alloc] initWithMajor:CBORMajorTypeMap
                                                    minor:minor];
    
    [self enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        CBORObject *cborKey = context(key, CBORUnknownMajorType, CBORUnknownMinorType);
        if (!cborKey) return;
        CBORObject *cborValue = context(obj, CBORUnknownMajorType, CBORUnknownMinorType);
        if (!cborValue) return;
        
        ret[cborKey] = cborValue;
    }];
    
    return ret;
}

@end
