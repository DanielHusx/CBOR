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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (CBORModel)

/// JSON（`NSDictionary`, `NSString` or `NSData`.）转模型
+ (nullable instancetype)cbor_modelWithJSON:(id)json;
/// 字典转模型
+ (nullable instancetype)cbor_modelWithDictionary:(NSDictionary *)dictionary;

/// JSON（`NSDictionary`, `NSString` or `NSData`）设置模型
- (BOOL)cbor_modelSetWithJSON:(id)json;
/// 字典设置模型
- (BOOL)cbor_modelSetWithDictionary:(NSDictionary *)dic;

/// 模型转JSON
- (nullable id)cbor_modelToJSONObject;
/// 模型转JSON数据
- (nullable NSData *)cbor_modelToJSONData;
/// 模型转JSON字符串
- (nullable NSString *)cbor_modelToJSONString;

/// 模型深拷贝
- (nullable id)cbor_modelCopy;

/// 模型编码
- (void)cbor_modelEncodeWithCoder:(NSCoder *)aCoder;
/// 模型解码
- (id)cbor_modelInitWithCoder:(NSCoder *)aDecoder;

/// 模型哈希值
- (NSUInteger)cbor_modelHash;

/// 模型是否相等
- (BOOL)cbor_modelIsEqual:(id)model;

/// 模型描述
- (NSString *)cbor_modelDescription;

@end


@interface NSArray (CBORModel)

/// JSON(`NSArray`, `NSString` or `NSData`)转模型数组
+ (nullable NSArray *)cbor_modelArrayWithClass:(Class)cls json:(id)json;

@end

@interface NSDictionary (CBORModel)

/// JSON（`NSDictionary`, `NSString` or `NSData`）转字典
+ (nullable NSDictionary *)cbor_modelDictionaryWithClass:(Class)cls json:(id)json;

@end


NS_ASSUME_NONNULL_END
