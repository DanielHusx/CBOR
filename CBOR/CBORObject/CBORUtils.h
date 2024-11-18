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

/// 简单值可用区间
static inline bool CBORIsSimpleValue(UInt64 value) {
    return (value >= CBORAdditionalTypeSimpleMinMinValue && value <= CBORAdditionalTypeSimpleMinMaxValue)
            || (value >= CBORAdditionalTypeSimpleMaxMinValue && value <= CBORAdditionalTypeSimpleMaxMaxValue);
}


static inline CBORByte CBORMajorTypeIsUnknown(CBORByte type) {
    return type == CBORUnknownMajorType;
}

static inline CBORByte CBORMinorTypeIsUnknown(CBORByte type) {
    return type == CBORUnknownMinorType;
}

static inline CBORMajorType CBORTypeMajor(CBORByte type) {
    return type & CBORMaskMajor;
}

static inline CBORMinorType CBORTypeMinor(CBORByte type) {
    return type & CBORMaskMinor;
}

/// 根据次要类型获取长度类型
static inline CBORLengthType CBORLengthTypeWithMinor(CBORMinorType minor) {
    return minor & CBORLengthTypeMask;
}

/// 长度类型对应字节长度（同样用于浮点数类型）
/// - Returns: 异常时返回 CBORLengthTypeUndefined
static inline CBORByte CBORByteWithLenghtType(CBORUInt64 type) {
    CBORLengthType lengthType = type & CBORLengthTypeMask;
    
    switch (lengthType) {
        case CBORLengthTypeUInt8: return 1;
        case CBORLengthTypeUInt16: return 2;
        case CBORLengthTypeUInt32: return 4;
        case CBORLengthTypeUInt64: return 8;
        default: return CBORLengthTypeUndefined;
    }
}

/// 根据具体值获取长度类型
static inline CBORLengthType CBORLengthTypeWithLength(CBORUInt64 length, CBORByte max) {
    if (max != 0 && length <= max) { return length; }
    
    if (length <= CBORLengthMaxValue8) return CBORLengthTypeUInt8;
    if (length <= CBORLengthMaxValue16) return CBORLengthTypeUInt16;
    if (length <= CBORLengthMaxValue32) return CBORLengthTypeUInt32;
    if (length <= CBORLengthMaxValue64) return CBORLengthTypeUInt64;
    
    return CBORLengthTypeUndefined;
}

/// 根据长度获取次要值类型
static inline CBORMinorType CBORMinorWithValue(CBORUInt64 value) {
    return CBORLengthTypeWithLength(value, CBORLengthTypeMaxValue);
}


/// 长度类型是否有效
static inline bool CBORIsLengthTypeValid(CBORLengthType type) {
    return type != CBORLengthTypeUndefined;
}

/// 字节长度是否有效
static inline bool CBORIsByteLengthValid(CBORUInt64 length) {
    return length != CBORLengthTypeUndefined;
}

/// 根据具体值获取长度类型
static inline CBORLengthType CBORLengthTypeWithLengthOrMinor(CBORUInt64 length, CBORByte max, CBORMinorType minor) {
    switch (minor) {
        case CBORLengthTypeUInt8:
        case CBORLengthTypeUInt16:
        case CBORLengthTypeUInt32:
        case CBORLengthTypeUInt64: {
            // 得到最适合的长度
            CBORLengthType ret = CBORLengthTypeWithLength(length, max);
            // 当得到的最适合的长度不非法时，取用最大值
            // 例如：长度为3，但要求1字节存储，则返回`CBORLengthTypeUInt8`
            if (!CBORIsLengthTypeValid(ret)) { return minor; }
            return MAX(minor, ret);
        }
        default:
            return CBORLengthTypeWithLength(length, max);
    }
}

/// 时间格式化方法
static inline NSDateFormatter *CBORISODateFormatter(void) {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    });
    return formatter;
}
