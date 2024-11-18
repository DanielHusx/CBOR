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

#import "CBORSimple.h"
#import "CBORUndefined.h"
#import "CBORBreak.h"

@implementation CBORSimple

+ (instancetype)simpleWithMinor:(CBORMinorType)minor {
    return [[self alloc] initWithMajor:CBORMajorTypeAdditional minor:minor];
}

+ (instancetype)cborBreak { return [self simpleWithMinor:CBORAdditionalTypeBreak]; }
+ (instancetype)cborNull { return [self simpleWithMinor:CBORAdditionalTypeNull]; }
+ (instancetype)cborYES { return [self simpleWithMinor:CBORAdditionalTypeTrue]; }
+ (instancetype)cborNO { return [self simpleWithMinor:CBORAdditionalTypeFalse]; }


- (BOOL)isNull {
    return self.minorType == CBORAdditionalTypeNull;
}

- (BOOL)isYES {
    return self.minorType == CBORAdditionalTypeTrue;
}

- (BOOL)isNO {
    return self.minorType == CBORAdditionalTypeFalse;
}

- (BOOL)isBool {
    return [self isYES] || [self isNO];
}

- (BOOL)isUndefined {
    return self.minorType == CBORAdditionalTypeUndefined;
}

- (BOOL)isBreak {
    return [super isBreak];
}

/// CBOR对象转化为原生对象
- (nullable NSObject *)nsObject {
    if (self.majorType != CBORMajorTypeAdditional) return nil;
    
    switch (self.minorType) {
        case CBORAdditionalTypeTrue: return @(YES);
        case CBORAdditionalTypeFalse: return @(NO);
        case CBORAdditionalTypeNull: return [NSNull null];
        case CBORAdditionalTypeUndefined: return [CBORUndefined new];
        case CBORAdditionalTypeBreak: return [CBORBreak new];
        default:
            return nil;
    }
}

/// CBOR对象编码为数据
- (nullable NSData *)cborData {
    if (self.majorType != CBORMajorTypeAdditional) return nil;
    
    switch (self.minorType) {
        case CBORAdditionalTypeTrue:
        case CBORAdditionalTypeFalse:
        case CBORAdditionalTypeNull:
        case CBORAdditionalTypeUndefined:
        case CBORAdditionalTypeBreak: {
            CBORByte value = self.majorType | self.minorType;
            NSUInteger length = sizeof(value);
            return [NSData dataWithBytes:&value length:length];
        }
            // 浮点数/简单值的类型在CBORNumber中处理
        default:
            return nil;
    }
}


@end
