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

#import "CBORParser.h"
#import "CBORDecoder.h"
#import "CBOREncoder.h"
#import "CBORObject.h"
#import "CBORMap.h"
#import "NSObject+CBORModel.h"

@implementation CBORParser


// MARK: - Encode
+ (NSData *)encodeObject:(id)obj {
    return [self encodeObject:obj
                        major:CBORUnknownMajorType
                        minor:CBORUnknownMinorType];
}

+ (NSData *)encodeObject:(id)obj major:(CBORMajorType)major {
    return [self encodeObject:obj
                        major:major
                        minor:CBORUnknownMinorType];
}

+ (NSData *)encodeObject:(id)obj major:(CBORMajorType)major minor:(CBORMinorType)minor {
    CBORObject *cbor = [CBOREncoder encodeObject:obj
                                           major:major
                                           minor:minor];
    
    return [cbor cborData];
}


// MARK: - Decode
+ (nullable id)decodeData:(NSData *)data {
    CBORObject *cbor = [CBORDecoder decodeData:data];
    if (!cbor) { return nil; }
    
    return [cbor nsObject];
}

+ (nullable id)decodeClass:(Class)aClass fromData:(NSData *)data {
    id obj = [self decodeData:data];
    if (!obj) { return nil; }
    
    // 数组模型
    if ([obj isKindOfClass:[NSArray class]] && ![aClass isSubclassOfClass:[NSArray class]]) {
        return [NSArray cbor_modelArrayWithClass:aClass json:obj];
    }
    // 期望字典
    if ([aClass isSubclassOfClass:[NSDictionary class]]) {
        return [obj isKindOfClass:[NSDictionary class]] ? obj : nil;
    }
    
    return [aClass cbor_modelWithJSON:obj];
}
@end
