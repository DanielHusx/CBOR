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
/// 自定义CBOR对象
@interface CBORObject : NSObject <NSCopying>

/// 主要类型
@property (nonatomic, assign, readonly) CBORMajorType majorType;
/// 次要类型；不限于定义第一字节的后五位，亦可表示为Tag类型
@property (nonatomic, assign, readonly) CBORMinorType minorType;

/// 初始化类型
- (instancetype)initWithMajor:(CBORMajorType)major
                        minor:(CBORMinorType)minor;
/// 初始化类型
- (instancetype)initWithMajor:(CBORMajorType)major;

/// CBOR对象转化为原生对象
- (nullable NSObject *)nsObject;
/// CBOR对象编码为数据
- (nullable NSData *)cborData;



- (NSData *)dataWithLengthOrValue:(CBORUInt64)lengthOrValue
                    minorMaxValue:(CBORByte)minorMaxValue;
- (NSData *)dataWithLengthOrValue:(CBORUInt64)lengthOrValue
                              raw:(nullable NSData *)raw ;
- (NSData *)dataWithLengthOrValue:(CBORUInt64)lengthOrValue;
- (NSData *)dataWithRaw:(NSData *)raw;


/// 是否是终止符
- (BOOL)isBreak;

/// 两个CBOR是否相等
- (BOOL)isEqualToCBOR:(CBORObject *)cbor;

@end



NS_ASSUME_NONNULL_END
