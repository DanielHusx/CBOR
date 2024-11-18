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

#import "CBORArray.h"

@interface CBORArray ()

/// 缓存CBOR数据对象列表 `@[CBORObject]`
@property (nonatomic, strong) NSMutableArray *cborObjects;
/// 数据资源
@property (nonatomic, nullable, copy) NSData *value;

@end

@implementation CBORArray

- (instancetype)initWithMajor:(CBORMajorType)major
                        minor:(CBORByte)minor
                        value:(NSData *)value {
    self = [super initWithMajor:major minor:minor];
    if (self) {
        _value = value;
    }
    return self;
}

- (instancetype)initWithMajor:(CBORMajorType)major
                        value:(NSData *)value {
    return [self initWithMajor:major
                         minor:CBORMinorWithValue([value length])
                         value:value];
}

- (void)addCBOR:(CBORObject *)cbor {
    [self.cborObjects addObject:cbor];
}


- (NSMutableArray *)cborObjects {
    if (!_cborObjects) {
        _cborObjects = [NSMutableArray array];
    }
    return _cborObjects;
}

/// CBOR对象转化为原生对象
- (nullable NSObject *)nsObject {
    switch (self.majorType) {
        case CBORMajorTypeBytes: {
            if (_value) return _value;
            
            NSMutableData *ret = [NSMutableData data];
            for (CBORObject *cbor in self.cborObjects) {
                if (![cbor isKindOfClass:[CBORArray class]]) continue;
                
                [ret appendData:[(CBORArray *)cbor value]];
            }
            return ret;
        }
        case CBORMajorTypeString: {
            if (_value) return [[NSString alloc] initWithData:_value encoding:NSUTF8StringEncoding];
            
            NSMutableString *ret = [NSMutableString string];
            for (CBORObject *cbor in self.cborObjects) {
                if (![cbor isKindOfClass:[CBORArray class]]) continue;
                
                [ret appendString:[[NSString alloc] initWithData:[(CBORArray *)cbor value] encoding:NSUTF8StringEncoding]];
            }
            return ret;
        }
        case CBORMajorTypeArray: {
            NSMutableArray *ret = [NSMutableArray array];
            for (CBORObject *cbor in self.cborObjects) {
                if (![cbor isKindOfClass:[CBORObject class]]) continue;
                
                [ret addObject:[cbor nsObject]];
            }
            return ret;
        }
        default:
            return nil;
    }
}

/// CBOR对象编码为数据
- (nullable NSData *)cborData {
    switch (self.majorType) {
        case CBORMajorTypeBytes:
        case CBORMajorTypeString:
            if (_value) { return [self dataWithRaw:_value]; }
            return [self dataWithRaw:(NSData *)[self nsObject]];
        case CBORMajorTypeArray: {
            NSMutableData *ret = [NSMutableData data];
            [ret appendData:[self dataWithLengthOrValue:[self.cborObjects count]]];
            
            for (CBORObject *cbor in self.cborObjects) {
                if (![cbor isKindOfClass:[CBORObject class]]) continue;
                
                [ret appendData:[cbor cborData]];
            }
            return ret;
        }
        default:
            return nil;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[CBORArray] major: %hhu, minor: %llu; source: %@, %@; nsObject: %@; data: %@", self.majorType, self.minorType, _value, _cborObjects, [self nsObject], [self cborData]];
}

@end
