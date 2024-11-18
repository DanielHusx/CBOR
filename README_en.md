# CBOR

A [CBOR (RFC 7049 Concise Binary Object Representation)](http://cbor.io/) decoder and encoder in Objective-C.

- Support half floats.
- Support the best shortest encoding (default)
- Support object attribute construction encoding order control
- [cbor.me](http://cbor.me/) is recommended for viewing your CBOR-encoded data.
- Support native data types for CBOR encoding and decoding
  - Basic data types, such as: NSInteger, NSUInteger, float, double, BOOL, etc.
  - NSNumber
  - NSArray
  - NSDictionary
  - NSData (byte string)
  - NSString
  - NSDate
  - NSNull
- Support CBOR encoding and decoding by implementing CBORModel protocol objects

[Chinese README](./README.md)

## Installation

- CocoaPods

  ```objective-c
  pod 'CBORObjC'
  ```

  

## Decoding

#### Parse to nsobject

- `+[CBORParser decodeData:]`

```objective-c
Byte raw[] = {
  0x9f, // indefinite array
  0x18, 255, // unsigned 255
  0x9b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 2, // array length is 2
  0x18, 1, // unsigned 1
  0x79, 0x00, 3, // string length is 3
  0x41, 0x42, 0x43, // @"ABC"
  0x79, 0x00, 3, // string length is 3
  0x41, 0x42, 0x43, // @"ABC"
  0xff // indefinite end
};
id ret = [CBORParser decodeData:[NSData dataWithBytes:&raw length:sizeof(raw)]];
// ret is [@(255), @[@(1), @"ABC"], @"ABC"]          
```

#### Parse to the specified object

- `+[CBORParser decodeClass:fromData:]`

```objective-c
@interface MyModel: NSObject <CBORModel>
@property (nonatomic, assign) NSInteger value;
@end
@implementation MyModel
@end

Byte raw[] = {
  0x8f, // indefinite dictionary
  0xA1, // dictionary length is 1
  0x65, 0x76, 0x61, 0x6C, 0x75, 0x65, // key (string length is 5): "value"
  0x1, // value (unsigned 1): 1
  0xff // indefinite end
};

id ret = [CBORParser decodeClass:[MyModel class] fromData:[NSData dataWithBytes:&raw length:sizeof(raw)]];
// ret is MyModel instance and ret.value = 1
```



## Encoding

#### Custom encoding native objects

- `[CBORParser encodeObject:major:minor:]`

```objective-c
// obj canb be NSObject, NSData, NSDate, NSNumber, NSString, NSArray, NSDictionary, NSNull...
[CBORParser encodeObject:@(1)]; // 0x01
[CBORParser encodeObject:@(1) major:CBORMajorTypeUnsigned minor:CBORLengthTypeUInt8]; // 0x18, 0x01
[CBORParser encodeObject:@(1) major:CBORMajorTypeAdditional]; // 0xe1

```

### CBORModel Protocol

-   Custom major/minor type and property-ordered
-   JSON Codec refer [YYModel](https://github.com/ibireme/YYModel)

```objective-c
#import "CBOR.h"

@interface CBORModel: NSObject <CBORModel>

@property (nonatomic, assign) NSUInteger uintValue;
@property (nonatomic, assign) float floatValue;
@property (nonatomic, assign) double doubleValue;
@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, copy) NSDate *dateValue;
// rename to tagStringValue
@property (nonatomic, copy) NSString *tagValue;
@property (nonatomic, copy) NSString *ignoredValue;

@end

@implementation CBORModel

+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{
        @"tagValue": @"tagStringValue"
    };
}
/// 自定义主要类型
+ (NSDictionary<NSString *, NSNumber *> *)modelCustomPropertyMajor {
    return @{
        // 可以不加CBORLengthTypeUInt8，那么Tag的子元素将根据自身最小所需长度设置
        @"tagValue": @(CBORMajorTypeTag | CBORLengthTypeUInt8),
	      @"doubleValue": @(CBORMajorTypeAdditional)
    };
}

+ (NSDictionary<NSString *,NSNumber *> *)modelCustomPropertyMinor {
    return @{
        @"tagValue": @(CBORTagTypeStandardDateTimeString),
	      @"doubleValue": @(CBORAdditionalTypeDouble)
    };
}

+ (NSArray<NSString *> *)modelPropertyBlacklist {
    return @[@"ignoredValue"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[Model] u: %zd; f:%.2f, d:%.2f s: %@; d: %@, t: %@, i: %@", _uintValue, _floatValue, _doubleValue, _stringValue, _dateValue, _tagValue, _ignoredValue];
}

- (BOOL)isEqualTo:(id)object {
    if (![object isKindOfClass:[self class]]) return NO;
    CBORModel *model = object;
    return [self.stringValue isEqualToString:model.stringValue] && (self.uintValue == model.uintValue);
}

@end
  
  
CBORModel *model = [[CBORModel alloc] init];
model.uintValue = 1;
model.floatValue = 1.0f;
model.doubleValue = 1.0;
model.stringValue = @"s";
model.tagValue = @"t";
model.dateValue = nil;//[NSDate dateWithTimeIntervalSince1970:1363896240];
model.ignoredValue = @"ignored";

Byte raw[] = {
  			0xA6, // map(6)
     
        0x69, 0x64, 0x61, 0x74, 0x65, 0x56, 0x61, 0x6C, 0x75, 0x65, // key: "dateValue"
        0xf6, // value: null

        0x6E, 0x74, 0x61, 0x67, 0x53, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x56, 0x61, 0x6C, 0x75, 0x65, // key: "tagStringValue"
//        0xc0, 0x61, 0x74,// value: tag(0), text(1), "t",
        0xc0, 0x78, 0x01, 0x74, // value: tag(0), text(1) "t"

        0x69, 0x75, 0x69, 0x6E, 0x74, 0x56, 0x61, 0x6C, 0x75, 0x65,// key: "uintValue"
        0x01, // value: unsigned(1)

        0x6B, 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x56, 0x61, 0x6C, 0x75, 0x65, // key: "stringValue"
        0x61, 0x73, // value: "s"

        0x6A, 0x66, 0x6C, 0x6F, 0x61, 0x74, 0x56, 0x61, 0x6C, 0x75, 0x65,// key: "floatValue"
        0xF9, 0x3C, 0x00, // value: half(1.0)

        0x6B, 0x64, 0x6F, 0x75, 0x62, 0x6C, 0x65, 0x56, 0x61, 0x6C, 0x75, 0x65, // key: "doubleValue"
        0xfb, 0x3f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // value: double(1.0)
};
NSData *encodeData = [NSData dataWithBytes:&raw length:sizeof(raw)];

// Decode
[CBORParser decodeClass:[CBORModel class] fromData:encodeData]; // result is model
// Encode
[CBORParser encodeObject:model]; // result is encodeData
```



## License

[MIT LICENSE](./LICENSE)