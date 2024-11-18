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
- (BOOL)popDataWithLength:(NSUInteger)length
                     data:(NSData * _Nullable * _Nullable)data;

- (BOOL)popUInt8:(UInt8 * _Nullable)value;
- (BOOL)popUInt16:(UInt16 * _Nullable)value;
- (BOOL)popUInt32:(UInt32 * _Nullable)value;
- (BOOL)popUInt64:(UInt64 * _Nullable)value;

- (BOOL)popFloat16:(Float16 *)value;
- (BOOL)popFloat32:(Float32 *)value;
- (BOOL)popFloat64:(Float64 *)value;

- (BOOL)popBytes:(UInt64 *)value length:(NSUInteger)length;

@end

NS_ASSUME_NONNULL_END
