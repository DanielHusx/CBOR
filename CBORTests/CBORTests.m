#import <XCTest/XCTest.h>
#import "CBOR.h"
//#import "CBORConstant.h"
//#import "CBORModel.h"
//#import "CBORParser.h"

#define CBORData(bytes...) \
^{\
    Byte byte[] = {bytes}; \
    NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)]; \
    return data;\
}

/// 测试整数
#define CBORDecodeNumber(value, bytes...) \
{ \
Byte byte[] = {bytes}; \
NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)]; \
NSObject *ret = [CBORParser decodeData:data]; \
NSLog(@"比对: %@ => %@ => %@", data, ret, @(value)); \
XCTAssertTrue([ret isEqual:@(value)]); \
NSData *dataRet = [CBORParser encodeObject:@(value)]; \
NSLog(@"数据: %@ => %@", data, dataRet); \
XCTAssertTrue([data isEqualToData:dataRet]); \
}

/// 测试字节数组
#define CBORDecodeBytes(r, s) \
{ \
NSData *source = s(); \
NSData *result = r(); \
NSObject *ret = [CBORParser decodeData:source]; \
NSLog(@"比对: %@ => %@ => %@", source, ret, result); \
XCTAssertTrue([ret isEqual:result]); \
NSData *dataRet = [CBORParser encodeObject:result]; \
NSLog(@"数据: %@ => %@", source, dataRet); \
XCTAssertTrue([source isEqualToData:dataRet]); \
}

/// 测试字符串
#define CBORDecodeArray(value, bytes...) \
{ \
Byte byte[] = {bytes}; \
NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)]; \
NSObject *ret = [CBORParser decodeData:data]; \
NSLog(@"比对: %@ => %@ => %@", data, ret, value); \
XCTAssertTrue([ret isEqual:value]); \
NSData *dataRet = [CBORParser encodeObject:value]; \
NSLog(@"数据: %@ => %@", data, dataRet); \
XCTAssertTrue([data isEqualToData:dataRet]); \
}

/// 测试字符串
#define CBORDecodeDictionary(value, bytes...) \
{ \
Byte byte[] = {bytes}; \
NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)]; \
NSObject *ret = [CBORParser decodeClass:[NSDictionary class] fromData:data]; \
NSLog(@"比对: %@ => %@ => %@", data, ret, value); \
XCTAssertTrue([ret isEqual:value]); \
NSData *dataRet = [CBORParser encodeObject:value]; \
NSLog(@"数据: %@ => %@", data, dataRet); \
XCTAssertTrue([data isEqualToData:dataRet]); \
}

@interface CBORModel: NSObject <CBORModel>

@property (nonatomic, assign) NSUInteger uintValue;
@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, copy) NSDate *dateValue;

@end

@implementation CBORModel

+ (NSDictionary<NSString *,id> *)modelCustomPropertyMapper {
    return @{
        @"dateValue": @"dateValu1"
    };
}
/// 自定义主要类型 + 次要类型
+ (nullable NSDictionary<NSString *, NSNumber *> *)modelCustomMajor {
    return @{
        @"uintValue": @(CBORMajorTypeAdditional)
    };
}
///// 务必存在对应Major，不然此参数无效
//+ (nullable NSDictionary<NSString *, NSNumber *> *)modelCustomMinor {
//    
//}

- (NSString *)description {
    return [NSString stringWithFormat:@"[Model] uintValue: %zd; stringValue: %@; date: %@", _uintValue, _stringValue, _dateValue];
}

- (BOOL)isEqualTo:(id)object {
    if (![object isKindOfClass:[self class]]) return NO;
    CBORModel *model = object;
    return [self.dateValue isEqualToDate:model.dateValue] && [self.stringValue isEqualToString:model.stringValue] && (self.uintValue == model.uintValue);
}

- (nullable NSData *)modelCustomPropertyCBORDataForKey:(NSString *)key {
    if (![key isEqualToString:@"stringValue"]) { return nil; }
    Byte byte[] = {00};
    return [NSData dataWithBytes:&byte length:1];
}



@end

@interface CBORTests : XCTestCase

@end

@implementation CBORTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

/// 测试整数
- (void)testDecodeNumber {
    for (CBORByte i = 0; i < CBORLengthTypeUInt8; i++) {
        CBORDecodeNumber(i, i)
    }
    CBORDecodeNumber(24, 0x18, 0x18)
    CBORDecodeNumber(255, 0x18, 0xff)
    CBORDecodeNumber(1000, 0x19, 0x03, 0xe8)
    CBORDecodeNumber(1000000000000, 0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00)
    CBORDecodeNumber(65535, 0x19, 0xff, 0xff)
    CBORDecodeNumber(4294967295, 0x1a, 0xff, 0xff, 0xff, 0xff)
    CBORDecodeNumber(18446744073709551615, 0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff)
    
    CBORDecodeNumber(-1, 0x20)
    CBORDecodeNumber(-2, 0x21)
    CBORDecodeNumber(-24, 0x37)
    
    CBORDecodeNumber(-256, 0x38, 0xff)
    CBORDecodeNumber(-1000, 0x39, 0x03, 0xe7)
    CBORDecodeNumber(-1000000, 0x3a, 0x00, 0x0f, 0x42, 0x3f)
    CBORDecodeNumber(-1000000000000, 0x3b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x0f, 0xff)
    
//    @try {
//        CBORDecodeNumber(false, 0x1a)
//    } @catch(NSException *e) {
//        NSLog(@"捕捉异常才正常: %@", e);
//        XCTAssertTrue(true);
//    }
}

/// 测试字节数组
- (void)te1stDecodeByteString {
    CBORDecodeBytes(^{ return [NSData data]; }, CBORData(0x40))
    CBORDecodeBytes(CBORData(0xf0), CBORData(0x41, 0xf0))
    CBORDecodeBytes(CBORData(0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xaa), CBORData(0x57, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xaa))

    // FIXME: 很特殊的一种，兼容这种情况需要额外配置，比如minor长度控制，要细化到CBORArray中去🤔
    CBORDecodeBytes(^{ return [NSData data]; }, CBORData(0x58, 0x00))
    CBORDecodeBytes(CBORData(0xf0), CBORData(0x58, 1, 0xf0))
    CBORDecodeBytes(CBORData(0xc0, 0xff, 0xee), CBORData(0x59, 0x00, 3, 0xc0, 0xff, 0xee))
    CBORDecodeBytes(CBORData(0xc0, 0xff, 0xee), CBORData(0x5a, 0x00, 0x00, 0x00, 3, 0xc0, 0xff, 0xee))
    CBORDecodeBytes(CBORData(0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee), CBORData(0x5f, 0x58, 0x03, 0xc0, 0xff, 0xee, 0x43, 0xc0, 0xff, 0xee, 0xff))
}

/// 测试字符串
- (void)testDecodeStrings {
//    CBORDecodeArray(@"stringValue", 0x6b, 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x56, 0x61, 0x6C, 0x75, 0x65)
//    CBORDecodeArray(@"", 0x60)
//    CBORDecodeArray(@"B", 0x61, 0x42)
//    CBORDecodeArray(@"ABC", 0x63, 0x41, 0x42, 0x43)
//    
//    // FIXME: 很特殊的一种，兼容这种情况需要额外配置，比如minor长度控制，要细化到CBORArray中去🤔
//    CBORDecodeArray(@"", 0x78, 0x00)
//    CBORDecodeArray(@"B", 0x78, 0x01, 0x42)
//    CBORDecodeArray(@"ABC", 0x79, 0x00, 3, 0x41, 0x42, 0x43)
//    CBORDecodeArray(@"ABCABC", 0x7f, 0x78, 3, 0x41, 0x42, 0x43, 0x63, 0x41, 0x42, 0x43, 0xff)
    
    {
        NSString *value = @"B";
    Byte byte[] = {0x78, 0x01, 0x42}; \
    NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)]; \
    NSObject *ret = [CBORParser decodeData:data]; \
    NSLog(@"比对: %@ => %@ => %@", data, ret, value); \
    XCTAssertTrue([ret isEqual:value]); \
        NSData *dataRet = [CBORParser encodeObject:value major:CBORMajorTypeString]; \
    NSLog(@"数据: %@ => %@", data, dataRet); \
    XCTAssertTrue([data isEqualToData:dataRet]); \
    }
}

/// 测试数组
- (void)te1stDecodeArray {
    NSArray *ret = @[];
    CBORDecodeArray(@[], 0x80)
    ret = @[@(1), @"ABC"]; CBORDecodeArray(ret, 0x82, 0x01, 0x63, 0x41, 0x42, 0x43);
    ret = @[@(2), @(2), @"ABC"]; CBORDecodeArray(ret, 0x98, 3, 0x18, 2, 0x18, 2, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0xff)
    ret = @[@[@1], @[@2, @3], @[@4, @5]]; CBORDecodeArray(ret, 0x9f, 0x81, 0x01, 0x82, 0x02, 0x03, 0x9f, 0x04, 0x05, 0xff, 0xff);
    
    
    // FIXME: 很特殊的一种，兼容这种情况需要额外配置，比如minor长度控制，要细化到CBORArray中去🤔
    ret = @[@(1), @"ABC"]; CBORDecodeArray(ret, 0x82, 0x18, 1, 0x79, 0x00, 3, 0x41, 0x42, 0x43);
    ret = @[@(255), @[@1, @"ABC"], @"ABC"]; CBORDecodeArray(ret, 0x9f, 0x18, 255, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 2, 0x18, 1, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0xff);
    
    CBORDecodeArray(@[], 0x98, 0)
}

/// 测试字典
- (void)testDecodeMap {
    NSDictionary *ret = @{};
//    CBORDecodeDictionary(@{}, 0xa0)
    // FIXME: 字典类型如何确定我要的是字典类型还是模型呢
//    ret = @{@"key": @(-24)}; CBORDecodeDictionary(ret, 0xa1, 0x63, 0x6b, 0x65, 0x79, 0x37)
//    ret = @{@"key": @[@(-24)]}; CBORDecodeDictionary(ret, 0xa1, 0x63, 0x6b, 0x65, 0x79, 0x81, 0x37)
    
//    ret = @{@"key": @{@"key": @(-24)}}; CBORDecodeDictionary(ret, 0xbf, 0x63, 0x6b, 0x65, 0x79, 0xa1, 0x63, 0x6b, 0x65, 0x79, 0x37, 0xff)
//    ret = @{@"key": @{@"key": @(-24)}}; CBORDecodeDictionary(ret, 0xbf, 0x63, 0x6b, 0x65, 0x79, 0xa1, 0x63, 0x6b, 0x65, 0x79, 0x37, 0xff)
    
    ret = @{@"_id": @"aaa", @"category": @"cake", @"ordinal": @(12.0)}; CBORDecodeDictionary(ret, 0xa3, 0x63, 0x5f, 0x69, 0x64, 0x63, 0x61, 0x61, 0x61, 0x68, 0x63, 0x61, 0x74, 0x65, 0x67, 0x6f, 0x72, 0x79, 0x64, 0x63, 0x61, 0x6b, 0x65, 0x67, 0x6f, 0x72, 0x64, 0x69, 0x6e, 0x61, 0x6c, 0xfa, 0x41, 0x40, 0x00, 0x00);
}

- (void)testDecodeTag {
    NSString *value = @"1985-04-12T23:20:50.52Z";
    NSData *data = [CBORParser encodeObject:value major:CBORMajorTypeTag minor:CBORTagTypeStandardDateTimeString];
//    Byte byte[] = {0xc0, 0x79, 0x00, 3, 0x41, 0x42, 0x43};
//    NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)];
    NSObject *ret = [CBORParser decodeData:data];
    NSLog(@"比对: %@ => %@ => %@", data, ret, value);
    XCTAssertTrue([ret isEqual:value]);
//    NSData *dataRet = [value cborData]; \
//    NSLog(@"数据: %@ => %@", data, dataRet); \
//    XCTAssertTrue([data isEqualToData:dataRet]);
}

- (void)te1stDecodeSimple {
    NSObject *value = [NSNull null];
    Byte byte[] = {0xf6};
    NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)];
    NSObject *ret = [CBORParser decodeData:data];
    NSLog(@"比对: %@ => %@ => %@", data, ret, value);
    XCTAssertTrue([ret isEqual:value]);
}

- (void)testDecodeFloat {
    float floatValue = -4.0;
//    float floatValue = 12.0;
    NSObject *value = @(floatValue);
    Byte byte[] = {0xf9, 0xc4, 0x00};
//    Byte byte[] = {0xf9, 0x4a, 0x00};
    NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)];
    NSObject *ret = [CBORParser decodeData:data];
    NSLog(@"比对: %@ => %@ => %@", data, ret, value);
    XCTAssertTrue([ret isEqual:value]);
    
    NSData *dataRet = [CBORParser encodeObject:value];// major:CBORMajorTypeAdditional minor:CBORAdditionalTypeHalf];
    NSLog(@"数据: %@ => %@", data, dataRet);
    XCTAssertTrue([data isEqual:dataRet]);
//    Float32 floatValue = 100000.0;
//    NSObject *value = @(floatValue);
//    Byte byte[] = {0xfa, 0x47, 0xc3, 0x50, 0x00};
//    NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)];
//    NSObject *ret = [NSObject cborWithData:data];
//    NSLog(@"比对: %@ => %@ => %@", data, ret, value);
//    XCTAssertTrue([ret isEqualTo:value]);
//    
//    NSData *dataRet = [value cborData];
//    NSLog(@"数据: %@ => %@", data, dataRet);
//    XCTAssertTrue([data isEqualTo:dataRet]);
}


- (void)te1stDecodeDate {
    NSObject *value = [NSDate dateWithTimeIntervalSince1970:1363896240];
    Byte byte[] = {0xc1, 0x1a, 0x51, 0x4b, 0x67, 0xb0};
    NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)];
    NSObject *ret = [CBORParser decodeData:data];
    NSLog(@"比对: %@ => %@ => %@", data, ret, value);
    XCTAssertTrue([ret isEqual:value]);
    
    NSData *dataRet = [CBORParser encodeObject:value];
    NSLog(@"数据: %@ => %@", data, dataRet);
    XCTAssertTrue([data isEqual:dataRet]);
}


- (void)testDecodeObject {
//    ret = @{@"_id": @"aaa", @"category": @"cake", @"ordinal": @(12.0)}; CBORDecodeDictionary(ret, 0xa3, 0x63, 0x5f, 0x69, 0x64, 0x63, 0x61, 0x61, 0x61, 0x68, 0x63, 0x61, 0x74, 0x65, 0x67, 0x6f, 0x72, 0x79, 0x64, 0x63, 0x61, 0x6b, 0x65, 0x67, 0x6f, 0x72, 0x64, 0x69, 0x6e, 0x61, 0x6c, 0xfa, 0x41, 0x40, 0x00, 0x00);
    CBORModel *value = [[CBORModel alloc] init];
    value.uintValue = 1;
    value.stringValue = @"a";
    value.dateValue = [NSDate dateWithTimeIntervalSince1970:1363896240];
    
    Byte byte[] = {0xa3, 0x69, 0x75, 0x69, 0x6E, 0x74, 0x56, 0x61, 0x6C, 0x75, 0x65, 0x01, 0x6b, 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x56, 0x61, 0x6C, 0x75, 0x65, 0x61, 0x61, 0x69, 0x64, 0x61, 0x74, 0x65, 0x56, 0x61, 0x6C, 0x75, 0x31,//0x65,
        0xc1, 0x1a, 0x51, 0x4B, 0x67, 0xB0};
    NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)];
    NSObject *ret = [CBORParser decodeClass:[CBORModel class] fromData:data];
    NSLog(@"比对: %@ => %@ => %@", data, ret, value);
    XCTAssertTrue([ret isEqualTo:value]);
    
    NSData *dataRet = [CBORParser encodeObject:value];
    NSLog(@"数据: %@ => %@", data, dataRet);
    XCTAssertTrue([data isEqualTo:dataRet]);
}

@end
