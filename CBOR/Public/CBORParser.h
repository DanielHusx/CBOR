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
#import "CBORConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface CBORParser : NSObject

// MARK: - Encode
/// 编码对象
/// - Parameter obj: 模型对象
/// - Returns: CBOR数据（大端）
+ (nullable NSData *)encodeObject:(id)obj;
/// 编码对象
/// - Parameters:
///   - obj: 对象
///   - major: 主要类型
+ (nullable NSData *)encodeObject:(id)obj
                            major:(CBORMajorType)major;
/// 编码对象
/// - Parameters:
///   - obj: 对象
///   - major: 主要类型
///   - minor: 次要类型
+ (nullable NSData *)encodeObject:(id)obj
                            major:(CBORMajorType)major
                            minor:(CBORUInt64)minor;


// MARK: - Decode
/// 解码数据
/// - Parameter data: CBOR数据（大端）
/// - Returns: 解析后的原生对象
+ (nullable id)decodeData:(NSData *)data;
/// 解码数据
/// - Parameters:
///   - aClass: 解析成指定类实例对象
///   - data: CBOR数据（大端）
/// - Returns: 
+ (nullable id)decodeClass:(Class)aClass fromData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
