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

#import "CBORNumber.h"


union Fp32 {
    uint32_t u;
    float f;
};

float uint16_to_float(uint16_t value) {
    const union Fp32 magic = { (254U - 15U) << 23 };
    const union Fp32 was_infnan = { (127U + 16U) << 23 };
    union Fp32 output;
    
    output.u = (value & 0x7FFFU) << 13;
    output.f *= magic.f;
    if (output.f >= was_infnan.f) {
        output.u |= 255U << 23;
    }
    output.u |= (value & 0x8000U) << 16;
    
    return output.f;
};

uint16_t float_to_uint16(float value) {
    const union Fp32 f32infty = { 255U << 23 };
    const union Fp32 f16infty = { 31U << 23 };
    const union Fp32 magic = { 15U << 23 };
    const uint32_t sign_mask = 0x80000000U;
    const uint32_t round_mask = ~0xFFFU;
    
    union Fp32 input;
    uint16_t output;
    
    input.f = value;
    
    uint32_t sign = input.u & sign_mask;
    input.u ^= sign;
    
    if (input.u >= f32infty.u) {
        // CBOR中0x7E00U-0x7FFFU都表示NAN，为符合最小值使用0x7E00
        // NaN : Inf
        output = (input.u > f32infty.u) ? 0x7E00U : 0x7C00U;
//        output = (input.u > f32infty.u) ? 0x7FFFU : 0x7C00U;
    } else {
        input.u &= round_mask;
        input.f *= magic.f;
        input.u -= round_mask;
        if (input.u > f16infty.u) input.u = f16infty.u;
        
        output = (uint16_t)(input.u >> 13);
    }
    
    output = (uint16_t)(output | (sign >> 16));
    
    return output;
}

/// 校验浮点数类型
CBORMinorType check_floating_type(CBORFloat64 value) {
    if (isnan(value) || isinf(value)) {
        // 非法值只用半精度浮点数表示
        return CBORAdditionalTypeHalf;
    }
    
    float halfValue = uint16_to_float(float_to_uint16(value));
    if ((double)halfValue == value) {
        // 显然是个半精度浮点数
        return CBORAdditionalTypeHalf;
    }
    
    float floatValue = (float)value;
    if ((double)floatValue == value) {
        // 显然是个单精度浮点数
        return CBORAdditionalTypeFloat;
    }
    
    return CBORAdditionalTypeDouble;
}

@interface CBORNumber ()

/// 无符号整数
@property (nonatomic, assign) UInt64 unsignedIntegerValue;
/// 浮点数
@property (nonatomic, assign) Float64 floatValue;

@end

@implementation CBORNumber

- (instancetype)initWithMajor:(CBORMajorType)major
                        minor:(CBORMinorType)minor
                   floatValue:(CBORFloat64)value {
    self = [super initWithMajor:major minor:minor];
    if (self) {
        _floatValue = value;
    }
    return self;
}

- (instancetype)initWithMajor:(CBORMajorType)major
                   floatValue:(CBORFloat64)value {
    return [self initWithMajor:major
                         minor:check_floating_type(value)
                    floatValue:value];
}

- (instancetype)initWithMajor:(CBORMajorType)major
                        minor:(CBORMinorType)minor
                unsignedValue:(CBORUInt64)value {
    self = [super initWithMajor:major minor:minor];
    if (self) {
        if (major == CBORMajorTypeAdditional && minor == CBORAdditionalTypeHalf) {
            // 半精度
            _floatValue = uint16_to_float(value);
        } else {
            // 整数
            _unsignedIntegerValue = value;
        }
    }
    return self;
}

- (instancetype)initWithMajor:(CBORMajorType)major
                unsignedValue:(CBORUInt64)value {
    return [self initWithMajor:major
                         minor:CBORMinorWithValue(value)
                 unsignedValue:value];
   
}

/// CBOR对象转化为原生对象
- (nullable NSObject *)nsObject {
    switch (self.majorType) {
        case CBORMajorTypeNegative:
            return @((SInt64)(-(_unsignedIntegerValue + 1)));
        case CBORMajorTypeUnsigned:
            return @(_unsignedIntegerValue);
        case CBORMajorTypeAdditional: {
            switch (self.minorType) {
                case CBORAdditionalTypeHalf:
                case CBORAdditionalTypeFloat:
                case CBORAdditionalTypeDouble:
                    return @(_floatValue);
                default:
                    return @(_unsignedIntegerValue);
            }
        }
        default:
            return nil;
    }
}

/// CBOR对象转化为数据
- (nullable NSData *)cborData {
    switch (self.majorType) {
        case CBORMajorTypeUnsigned:
        case CBORMajorTypeNegative: {
            return [self dataWithLengthOrValue:_unsignedIntegerValue];
        }
        case CBORMajorTypeAdditional: {
            switch (self.minorType) {
                case CBORAdditionalTypeHalf:
                case CBORAdditionalTypeFloat:
                case CBORAdditionalTypeDouble:
                    return [self dataWithFloatValue];;
                default:
                    return [self dataWithLengthOrValue:_unsignedIntegerValue
                                         minorMaxValue:CBORAdditionalTypeSimpleMinMaxValue];
            }
        }
        default: return nil;
    }
}

/// 构建CBOR浮点数数据
- (NSData *)dataWithFloatValue {
    NSMutableData *ret = [NSMutableData data];
    
    CBORAdditionalType minor = CBORTypeMinor(self.minorType);
    NSData *value = [self floatDataWithType:minor];
    if (![value length]) { return nil; }
    
    CBORByte type = self.majorType | minor;
    
    [ret appendBytes:&type length:1];
    [ret appendData:value];
    
    return ret;
}

- (NSData *)floatDataWithType:(CBORAdditionalType)type {
    NSUInteger length = CBORByteWithLenghtType(type);
    
    switch (type) {
        case CBORAdditionalTypeHalf: {
            UInt16 ret = CFSwapInt16HostToBig(float_to_uint16(_floatValue));
            return [NSData dataWithBytes:&ret length:length];
        }
        case CBORAdditionalTypeFloat: {
            CFSwappedFloat32 ret = CFConvertFloat32HostToSwapped(_floatValue);
            return [NSData dataWithBytes:&ret length:length];
        }
        case CBORAdditionalTypeDouble: {
            CFSwappedFloat64 ret = CFConvertFloat64HostToSwapped(_floatValue);
            return [NSData dataWithBytes:&ret length:length];
        }
        default:
            return [NSData data];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[CBORNumber] major: %d, minor: %llu; source: %llu, %.2f; nsobject: %@; data: %@", self.majorType, self.minorType, _unsignedIntegerValue, _floatValue, [self nsObject], [self cborData]];
}

@end
