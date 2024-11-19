#import <XCTest/XCTest.h>
#import "CBOR.h"

#define CBORData(bytes...) \
^{\
    Byte byte[] = {bytes}; \
    NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)]; \
    return data;\
}()
// MARK: - 测试模型
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

+ (NSArray<NSString *> *)modelCustomPropertySequeue {
    return @[
        @"dateValue", @"tagValue", @"uintValue", @"stringValue", @"floatValue", @"doubleValue"
    ];
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


@interface CBORModelTests : XCTestCase

@end

@implementation CBORModelTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDecodeObject {
    CBORModel *value = [[CBORModel alloc] init];
    value.uintValue = 1;
    value.floatValue = 1.0f;
    value.doubleValue = 1.0;
    value.stringValue = @"s";
    value.tagValue = @"t";
    value.dateValue = [NSNull null];//[NSDate dateWithTimeIntervalSince1970:1363896240];
    value.ignoredValue = @"ignored";
    
    NSData *data = CBORData
    (
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
     
//        // 已忽略的Key即便加上也不会解析
//        0x6C, 0x69, 0x67, 0x6E, 0x6F, 0x72, 0x65, 0x64, 0x56, 0x61, 0x6C, 0x75, 0x65, // key: "ignoredValue"
//        0x67, 0x69, 0x67, 0x6E, 0x6F, 0x72, 0x65, 0x64,// "ignored"

     );
    
    NSObject *decodedObject = [CBORParser decodeClass:[CBORModel class] fromData:data];
    NSLog(@"数据: %@ => 解码对象： %@ => 期望对象 %@", data, decodedObject, value);
    XCTAssertTrue([decodedObject isEqualTo:value]);
    
    NSData *encodedData = [CBORParser encodeObject:value];
    NSLog(@"对象：%@ => 加密对象: %@ => 期望数据 ：%@", value, encodedData, data);
    XCTAssertTrue([data isEqualTo:encodedData]);
}


@end
