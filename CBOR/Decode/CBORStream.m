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

#import "CBORStream.h"

#define CBOR_POP_VALUE(type) \
NSUInteger length = sizeof(type); \
NSData *reversed = [self reversedWithData:[self popDataWithLength:length]]; \
if (![reversed length]) return 0; \
type ret = 0; \
[reversed getBytes:&ret length:length]; \
return ret;

@interface CBORStream()

/// 数据源
@property (nonatomic, copy) NSData *source;
/// 指向数据源的位置
@property (nonatomic, assign) NSUInteger index;

@end

@implementation CBORStream

// MARK: - Public
/// 初始化数据
- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        _source = [data copy];
        _index = 0;
    }
    return self;
}

/// 弹出数据
- (nullable NSData *)popDataWithLength:(NSUInteger)length {
    if ([self isOverflowWithLength:length]) return nil;
    
    NSData *ret = [_source subdataWithRange:NSMakeRange(_index, length)];
    
    // 读取完数据后移动偏移长度
    _index += length;
    
    return ret;
}

- (UInt8)popUInt8 { CBOR_POP_VALUE(UInt8) }
- (UInt16)popUInt16 { CBOR_POP_VALUE(UInt16) }
- (UInt32)popUInt32 { CBOR_POP_VALUE(UInt32) }
- (UInt64)popUInt64 { CBOR_POP_VALUE(UInt64) }

- (Float16)popFloat16 { return [self popUInt16]; }
- (Float32)popFloat32 { CBOR_POP_VALUE(Float32) }
- (Float64)popFloat64 { CBOR_POP_VALUE(Float64) }


// MARK: - Private
/// 校验读取区间是否溢出数据长度
- (BOOL)isOverflowWithLength:(NSUInteger)length {
    return [_source length] < _index + length;
}

/// 倒序数据
- (NSData *)reversedWithData:(NSData *)data {
    NSUInteger length = [data length];
    if (length <= 1) { return data; }
    
    const char *bytes = [data bytes];
    char *reversedBytes = malloc(sizeof(char) * length);
    
    for (NSUInteger index = length; index > 0; index--)
        reversedBytes[length - index] = bytes[index - 1];
    
    return [NSData dataWithBytesNoCopy:reversedBytes length:length];
}

@end
