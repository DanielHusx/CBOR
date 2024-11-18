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

#import "CBORObject.h"

NS_ASSUME_NONNULL_BEGIN
/// 键值对类型
@interface CBORMap : CBORObject

/// 存储CBOR键值对
- (void)setCBOR:(CBORObject *)value forKey:(CBORObject *)key;
/// 获取已存储的CBOR
- (nullable CBORObject *)cborForKey:(CBORObject *)key;

/// 下标读取
- (nullable CBORObject *)objectForKeyedSubscript:(CBORObject *)key;
/// 下标设置
- (void)setObject:(CBORObject *)object forKeyedSubscript:(CBORObject *)aKey;

@end

NS_ASSUME_NONNULL_END
