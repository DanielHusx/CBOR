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
#import "CBORUtils.h"

NS_ASSUME_NONNULL_BEGIN
@class CBORObject;

/// CBOR编码协议
@protocol CBOREncodable <NSObject>

/// 使用默认类型转化CBOR
- (nullable CBORObject *)cborObject;

/// 使用指定类型转化CBOR
/// - Parameters:
///   - major: 指定主要类型
///   - minor: 指定次要类型；宽泛为UInt64是为了兼容Tag的定义
- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major
                                       minor:(CBORUInt64)minor;


@optional
- (nullable CBORObject *)cborObjectWithMajor:(CBORMajorType)major
                                       minor:(CBORUInt64)minor
                                     context:(CBORObject * _Nullable (* _Nullable) (NSObject *, CBORMajorType, CBORUInt64))context;

@end

NS_ASSUME_NONNULL_END
