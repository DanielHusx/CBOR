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

/// 半精度
typedef UInt16 Float16;

NS_ASSUME_NONNULL_BEGIN
/// 数据输入输出流（相当于简单的管理器）
@interface CBORStream : NSObject
/// 初始化数据
- (instancetype)initWithData:(NSData *)data;

/// 弹出数据
- (nullable NSData *)popDataWithLength:(NSUInteger)length;


- (UInt8)popUInt8;
/// 已处理大端转小端
- (UInt16)popUInt16;
- (UInt32)popUInt32;
- (UInt64)popUInt64;

- (Float16)popFloat16;
- (Float32)popFloat32;
- (Float64)popFloat64;

@end

NS_ASSUME_NONNULL_END
