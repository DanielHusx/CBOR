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

#import "CBORMap.h"

/// 字典存储模型
@interface CBORMapModel: NSObject

@property (nonatomic, strong) CBORObject *key;
@property (nonatomic, strong) CBORObject *value;

- (instancetype)initWithKey:(CBORObject *)key value:(CBORObject *)value;

@end

@implementation CBORMapModel

- (instancetype)initWithKey:(CBORObject *)key value:(CBORObject *)value {
    self = [super init];
    if (self) {
        _key = key;
        _value = value;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[(key)%@: (value)%@]", _key, _value];
}

@end



@interface CBORMap ()

/// 缓存数据对象列表
@property (nonatomic, strong) NSMutableArray *cbors;

@end

@implementation CBORMap

- (void)setCBOR:(CBORObject *)value forKey:(CBORObject *)key {
    // FIXME: 理论上应该排除同个Key的情况
    [self.cbors addObject:[[CBORMapModel alloc] initWithKey:key value:value]];
}

- (nullable CBORObject *)cborForKey:(CBORObject *)key {
    for (CBORMapModel *model in self.cbors) {
        if (![model.key isEqualToCBOR:key]) continue;
        return model.value;
    }
    return nil;
}

- (nullable CBORObject *)objectForKeyedSubscript:(CBORObject *)key {
    if (![key isKindOfClass:[CBORObject class]]) return nil;
    return [self cborForKey:key];
}

- (void)setObject:(CBORObject *)object forKeyedSubscript:(CBORObject *)aKey {
    if (![aKey isKindOfClass:[CBORObject class]] || ![object isKindOfClass:[CBORObject class]]) return;
    [self setCBOR:object forKey:aKey];
}

- (NSMutableArray *)cbors {
    if (!_cbors) {
        _cbors = [NSMutableArray array];
    }
    return _cbors;
}

/// CBOR对象转化为原生对象
- (NSObject *)nsObject {
    if (self.majorType != CBORMajorTypeMap) { return nil; }
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:[self.cbors count]];
    for (CBORMapModel *model in self.cbors) {
        if (![model isKindOfClass:[CBORMapModel class]]) continue;
        
        NSObject *key = [model.key nsObject];
        if (!key) continue;
        NSObject *value = [model.value nsObject];
        if (!value) continue;
        
        if ([key conformsToProtocol:@protocol(NSCopying)]) {
            ret[(id<NSCopying>)key] = value;
        } else {
            ret[[NSString stringWithFormat:@"%@", key]] = value;
        }
    }
    
    return ret;
}

/// CBOR对象编码为数据
- (NSData *)cborData {
    if (self.majorType != CBORMajorTypeMap) { return nil; }
    
    NSMutableData *ret = [NSMutableData data];
    [ret appendData:[self dataWithLengthOrValue:[self.cbors count]]];
    
    for (CBORMapModel *model in self.cbors) {
        if (![model isKindOfClass:[CBORMapModel class]]) continue;
        
        NSData *key = [model.key cborData];
        if (!key) continue;
        NSData *value = [model.value cborData];
        if (!value) continue;
        
        [ret appendData:key];
        [ret appendData:value];
    }
    
    return ret;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[CBORMap] %@", self.cbors];
}

@end

