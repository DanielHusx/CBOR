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
/// 数字类型（整数/浮点数/简单值）
@interface CBORNumber : CBORObject

/// 构建浮点数
- (instancetype)initWithMajor:(CBORMajorType)major
                        minor:(CBORMinorType)minor
                   floatValue:(CBORFloat64)value;
- (instancetype)initWithMajor:(CBORMajorType)major
                   floatValue:(CBORFloat64)value;

/// 构建整数 或 半精度浮点数
- (instancetype)initWithMajor:(CBORMajorType)major
                        minor:(CBORMinorType)minor
                unsignedValue:(CBORUInt64)value;
- (instancetype)initWithMajor:(CBORMajorType)major
                unsignedValue:(CBORUInt64)value;

@end

NS_ASSUME_NONNULL_END
