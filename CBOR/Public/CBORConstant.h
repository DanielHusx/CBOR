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

/// 字节
typedef UInt8 CBORByte;
/// 次要数据类型
typedef UInt64 CBORMinorType;

typedef UInt64 CBORUInt64;
typedef Float64 CBORFloat64;

#define CBOR_HALF_MAX 65504.0f
#define CBOR_HALF_MIN -65504.0f

/// 未知CBOR类型
static const CBORByte CBORUnknownMajorType = UINT8_MAX;
/// 未知次要类型
static const CBORUInt64 CBORUnknownMinorType = UINT64_MAX;

/// 掩码类型
typedef NS_ENUM(CBORByte, CBORMask) {
    /// 主要类型掩码
    CBORMaskMajor       = 0b11100000,
    /// 次要类型掩码
    CBORMaskMinor       = 0b00011111,
};

/// 主要数据类型
typedef NS_ENUM(CBORByte, CBORMajorType) {
    /// 0 整数
    CBORMajorTypeUnsigned       = 0b00000000, // 0x00
    /// 1 负整数
    CBORMajorTypeNegative       = 0b00100000, // 0x20
    /// 2 字节数组 eg: `h'010203', (_ h'01020304',h'01020304')`
    CBORMajorTypeBytes          = 0b01000000, // 0x40
    /// 3 字符串
    CBORMajorTypeString         = 0b01100000, // 0x60
    /// 4 数组
    CBORMajorTypeArray          = 0b10000000, // 0x80
    /// 5 键值对
    CBORMajorTypeMap            = 0b10100000, // 0xa0
    /// 6 扩展类型
    CBORMajorTypeTag            = 0b11000000, // 0xc0
    /// 7 额外类型（浮点数与简单类型）
    CBORMajorTypeAdditional     = 0b11100000, // 0xe0
};

/// 长度类型定义
typedef NS_ENUM(CBORByte, CBORLengthType) {
    /// 后续1字节表示长度
    CBORLengthTypeUInt8             = 0b00011000, // 0x18(24)
    /// 后续2字节表示长度
    CBORLengthTypeUInt16            = 0b00011001, // 0x19(25)
    /// 后续3字节表示长度
    CBORLengthTypeUInt32            = 0b00011010, // 0x1a(26)
    /// 后续4字节表示长度
    CBORLengthTypeUInt64            = 0b00011011, // 0x1b(27)
    
    /// 长度类型掩码
    CBORLengthTypeMask              = 0b00011111,
    /// 长度未定义
    CBORLengthTypeUndefined         = 0b00011111,
    
    /// 长度单字节可直接表达数据的最大长度
    /// `0b00000000(0) - 0b00010111(23)`
    CBORLengthTypeMaxValue          = CBORLengthTypeUInt8 - 1, // 0x17(23)
    /// 定义整数长度的最大长度
    /// `0b00011000(0x18)(24) - 0b00011011(0x1b)(27)`
    CBORLengthTypeMaxDefined        = CBORLengthTypeUInt64,
};

/// 长度类型对应最大值
typedef NS_ENUM(CBORUInt64, CBORLengthMaxValue) {
    /// 1字节
    CBORLengthMaxValue8    = UINT8_MAX,
    /// 2字节
    CBORLengthMaxValue16   = UINT16_MAX,
    /// 4字节
    CBORLengthMaxValue32   = UINT32_MAX,
    /// 8字节
    CBORLengthMaxValue64   = UINT64_MAX,
};

/// 额外类型的具体次要类型
typedef NS_ENUM(CBORByte, CBORAdditionalType) {
    // 0x00(0)...0x13(19) 简单值（值0~19)
    
    /// 布尔值 NO
    CBORAdditionalTypeFalse             = 0x14, // 20
    /// 布尔值 YES
    CBORAdditionalTypeTrue              = 0x15, // 21
    /// 空类型
    CBORAdditionalTypeNull              = 0x16, // 22
    /// 未定义，不明确的
    CBORAdditionalTypeUndefined         = 0x17, // 23
    
    // 0x18(24) 简单值（以下字节值为0x20(32)-0xFF(255)）
    
    /// 半精度 Float16
    CBORAdditionalTypeHalf              = 0x19, // 25
    /// 单精度 Float32
    CBORAdditionalTypeFloat             = 0x1A, // 26
    /// 双精度 Float64
    CBORAdditionalTypeDouble            = 0x1B, // 27
    
    // 28...30 保留
    
    /// 无限长度停止符
    CBORAdditionalTypeBreak             = 0x1F, // 31
    
    /// 次要类型不定长（无限）标识
    /// 支持数组，键值对，字符数组，字符串等
    CBORAdditionalTypeIndefinite        = CBORAdditionalTypeBreak,
    
    /// 简单值小区间
    CBORAdditionalTypeSimpleMinMinValue    = 0x00, // 0
    CBORAdditionalTypeSimpleMinMaxValue    = 0x13, // 19
    /// 简单值大区间
    CBORAdditionalTypeSimpleMaxMinValue    = 0x20, // 32
    CBORAdditionalTypeSimpleMaxMaxValue    = 0xFF, // 255
};

/// 扩展类型具体类型
/// 参考：https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml
typedef NS_ENUM(CBORUInt64, CBORTagType) {
    /// 标准时间（基于地球自转的时间）（非负值）（字符串）  例如："1985-04-12T23:20:50.52Z"
    CBORTagTypeStandardDateTimeString   = 0,
    /// 纪元时间(Epoch/UNIX/POSIX)（整数或浮点数）；自1970-01-01T00:00:00Z UTC以秒为单位进行计数
    CBORTagTypeEpochBasedDateTime       = 1,
    
    /// 正大数(2^n)
    /// 通常是0/1的Byte数组，从右边到左计算1所在位置之和
    /// 例如: 0xc2 42 0100 => 2^8 = 256
    CBORTagTypePositiveBignum           = 2,
    /// 负大数(-2^n - 1)
    /// 通常是0/1的Byte数组，从右边到左计算1所在位置之和
    /// 例如: 0xc3 42 0100  => -2^8 - 1 => -257
    CBORTagTypeNegativeBignum           = 3,
    
    /// 十进制分数`(尾数m*10^指数e)`
    /// 通常是长度为2的数组，`@[指数e（主要类型必须是0或1）,尾数m（可以是Bignum）]`
    /// 例如：0xc4 82 21 196ab3 => `27315*(10^-2)` => 273.15
    CBORTagTypeDecimalFraction          = 4,
    /// 大浮点数`(尾数m*2^指数e)`
    /// 通常是长度为2的数组，`@[指数e（主要类型必须是0或1）,尾数m（可以是Bignum）]`
    /// 例如：0xc5 82 20 03 => `3*(2^-1)` => 1.5
    CBORTagTypeBigfloat                 = 5,

    // 6...20 unassigned

    /// 预期后续编码方式为Base64地址编码
    /// 我的理解是：告诉接收方后续的字符串需要Base64地址编码
    CBORTagTypeExpectedConversionToBase64URLEncoding    = 21,
    /// 预期后续编码方式为Base64编码
    CBORTagTypeExpectedConversionToBase64Encoding       = 22,
    /// 预期后续编码方式为Base16编码
    CBORTagTypeExpectedConversionToBase16Encoding       = 23,
    /// 编码数据格式
    CBORTagTypeEncodedCBORDataItem                      = 24,

    // 25...31 unassigned
    /// 统一资源标识符
    CBORTagTypeURI                  = 32,
    /// Base64地址编码
    CBORTagTypeBase64URL            = 33,
    /// Base64编码
    CBORTagTypeBase64               = 34,
    /// 正则
    CBORTagTypeRegularExpression    = 35,
    /// MIME
    CBORTagTypeMIMEMessage          = 36,
    /// UUID
    CBORTagTypeUUID                 = 37,

    // 38...55798 unassigned
    /// 自1970-01-01开始计算天数差（整数）
    CBORTagTypeDaysSinceEpochDate   = 100,
    
    /// 自我描述
    CBORTagTypeSelfDescribeCBOR     = 55799,
};

