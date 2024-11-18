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

#import "CBORTag.h"

@interface CBORTag ()

/// 扩展标记
@property (nonatomic, assign) CBORTagType tag;
/// 扩展数据
@property (nonatomic, strong) CBORObject *value;

@end

@implementation CBORTag

- (instancetype)initWithMajor:(CBORMajorType)major
                          tag:(CBORTagType)tag
                        value:(CBORObject *)value {
    self = [super initWithMajor:major minor:0];
    if (self) {
        _tag = tag;
        _value = value;
    }
    return self;
}

/// CBOR对象转化为原生对象
- (nullable NSObject *)nsObject {
    if (self.majorType != CBORMajorTypeTag) { return nil; }
    
    switch (self.tag) {
        case CBORTagTypeBase64:
        case CBORTagTypeBase64URL: {
            NSObject *value = [_value nsObject];
            if (![value isKindOfClass:[NSString class]]) { return nil; }
            
            // Base64解码
            NSData *data = [[NSData alloc] initWithBase64EncodedString:(NSString *)value options:NSDataBase64DecodingIgnoreUnknownCharacters];
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        default: break;
    }
    
    return [_value nsObject];
}

/// CBOR对象转化为数据
- (nullable NSData *)cborData {
    if (self.majorType != CBORMajorTypeTag) { return nil; }
    
    NSMutableData *ret = [NSMutableData data];
    [ret appendData:[self dataWithLengthOrValue:self.tag]];
    
    NSData *value = [_value cborData];
    if (!value) { return nil; }
    [ret appendData:value];
    
    return ret;
}



@end
