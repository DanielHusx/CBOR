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
#import <objc/runtime.h>
#import "CBORConstant.h"

NS_ASSUME_NONNULL_BEGIN
/// 原生类类型
typedef NS_ENUM (NSUInteger, CBOREncodingNSType) {
    CBOREncodingTypeNSUnknown = 0,
    CBOREncodingTypeNSString,
    CBOREncodingTypeNSMutableString,
    CBOREncodingTypeNSValue,
    CBOREncodingTypeNSNumber,
    CBOREncodingTypeNSDecimalNumber,
    CBOREncodingTypeNSData,
    CBOREncodingTypeNSMutableData,
    CBOREncodingTypeNSDate,
    CBOREncodingTypeNSURL,
    CBOREncodingTypeNSArray,
    CBOREncodingTypeNSMutableArray,
    CBOREncodingTypeNSDictionary,
    CBOREncodingTypeNSMutableDictionary,
    CBOREncodingTypeNSSet,
    CBOREncodingTypeNSMutableSet,
};

/// 类型编码
typedef NS_OPTIONS(NSUInteger, CBOREncodingType) {
    CBOREncodingTypeMask       = 0xFF, ///< mask of type value
    CBOREncodingTypeUnknown    = 0, ///< unknown
    CBOREncodingTypeVoid       = 1, ///< void
    CBOREncodingTypeBool       = 2, ///< bool
    CBOREncodingTypeInt8       = 3, ///< char / BOOL
    CBOREncodingTypeUInt8      = 4, ///< unsigned char
    CBOREncodingTypeInt16      = 5, ///< short
    CBOREncodingTypeUInt16     = 6, ///< unsigned short
    CBOREncodingTypeInt32      = 7, ///< int
    CBOREncodingTypeUInt32     = 8, ///< unsigned int
    CBOREncodingTypeInt64      = 9, ///< long long
    CBOREncodingTypeUInt64     = 10, ///< unsigned long long
    CBOREncodingTypeFloat      = 11, ///< float
    CBOREncodingTypeDouble     = 12, ///< double
    CBOREncodingTypeLongDouble = 13, ///< long double
    CBOREncodingTypeObject     = 14, ///< id
    CBOREncodingTypeClass      = 15, ///< Class
    CBOREncodingTypeSEL        = 16, ///< SEL
    CBOREncodingTypeBlock      = 17, ///< block
    CBOREncodingTypePointer    = 18, ///< void*
    CBOREncodingTypeStruct     = 19, ///< struct
    CBOREncodingTypeUnion      = 20, ///< union
    CBOREncodingTypeCString    = 21, ///< char*
    CBOREncodingTypeCArray     = 22, ///< char[10] (for example)
    
    CBOREncodingTypeQualifierMask   = 0xFF00,   ///< mask of qualifier
    CBOREncodingTypeQualifierConst  = 1 << 8,  ///< const
    CBOREncodingTypeQualifierIn     = 1 << 9,  ///< in
    CBOREncodingTypeQualifierInout  = 1 << 10, ///< inout
    CBOREncodingTypeQualifierOut    = 1 << 11, ///< out
    CBOREncodingTypeQualifierBycopy = 1 << 12, ///< bycopy
    CBOREncodingTypeQualifierByref  = 1 << 13, ///< byref
    CBOREncodingTypeQualifierOneway = 1 << 14, ///< oneway
    
    CBOREncodingTypePropertyMask         = 0xFF0000, ///< mask of property
    CBOREncodingTypePropertyReadonly     = 1 << 16, ///< readonly
    CBOREncodingTypePropertyCopy         = 1 << 17, ///< copy
    CBOREncodingTypePropertyRetain       = 1 << 18, ///< retain
    CBOREncodingTypePropertyNonatomic    = 1 << 19, ///< nonatomic
    CBOREncodingTypePropertyWeak         = 1 << 20, ///< weak
    CBOREncodingTypePropertyCustomGetter = 1 << 21, ///< getter=
    CBOREncodingTypePropertyCustomSetter = 1 << 22, ///< setter=
    CBOREncodingTypePropertyDynamic      = 1 << 23, ///< @dynamic
};


/// 类的实例对象信息
@interface CBORClassIvarInfo : NSObject
/// 解析的原实例对象
@property (nonatomic, assign, readonly) Ivar ivar;
/// 实例对象名称
@property (nonatomic, strong, readonly) NSString *name;
/// 实例对象地址便宜
@property (nonatomic, assign, readonly) ptrdiff_t offset;
/// 实例对象类型编码
@property (nonatomic, strong, readonly) NSString *typeEncoding;
/// 实例对象编码类型
@property (nonatomic, assign, readonly) CBOREncodingType type;

/// 初始化解析实例对象
- (instancetype)initWithIvar:(Ivar)ivar;

@end


/// 类的方法信息
@interface CBORClassMethodInfo : NSObject
/// 解析的原方法
@property (nonatomic, assign, readonly) Method method;
/// 方法名称
@property (nonatomic, strong, readonly) NSString *name;
/// 方法选择器
@property (nonatomic, assign, readonly) SEL sel;
/// 方法实现
@property (nonatomic, assign, readonly) IMP imp;
/// 方法参数以及返回类型编码
@property (nonatomic, strong, readonly) NSString *typeEncoding;
/// 方法返回类型编码
@property (nonatomic, strong, readonly) NSString *returnTypeEncoding;
/// 方法参数编码
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *argumentTypeEncodings;

/// 初始化解析方法
- (instancetype)initWithMethod:(Method)method;

@end


/// 类的属性信息
@interface CBORClassPropertyInfo : NSObject
/// 解析的原属性
@property (nonatomic, assign, readonly) objc_property_t property;
/// 属性名称
@property (nonatomic, strong, readonly) NSString *name;
/// 属性类型
@property (nonatomic, assign, readonly) CBOREncodingType type;
/// 属性类型编码
@property (nonatomic, strong, readonly) NSString *typeEncoding;
/// 属性对象名称
@property (nonatomic, strong, readonly) NSString *ivarName;
/// 属性类
@property (nullable, nonatomic, assign, readonly) Class cls;
/// 属性遵循的协议
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *protocols;
/// 属性Get选择器
@property (nonatomic, assign, readonly) SEL getter;
/// 属性Set选择器
@property (nonatomic, assign, readonly) SEL setter;

/// 初始化解析属性
- (instancetype)initWithProperty:(objc_property_t)property;

@end



/// 类信息
@interface CBORClassInfo : NSObject
/// 类
@property (nonatomic, assign, readonly) Class cls;
/// 父类
@property (nullable, nonatomic, assign, readonly) Class superCls;
/// 元类
@property (nullable, nonatomic, assign, readonly) Class metaCls;
/// 是否是元类
@property (nonatomic, readonly) BOOL isMeta;
/// 类名称
@property (nonatomic, strong, readonly) NSString *name;
/// 父类信息
@property (nullable, nonatomic, strong, readonly) CBORClassInfo *superClassInfo;
/// 实例对象信息
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, CBORClassIvarInfo *> *ivarInfos;
/// 方法信息
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, CBORClassMethodInfo *> *methodInfos;
/// 属性信息
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, CBORClassPropertyInfo *> *propertyInfos;

/// 标记需要更新类信息
- (void)setNeedUpdate;
/// 是否需要更新类信息
- (BOOL)needUpdate;

/// 初始化类信息
+ (nullable instancetype)classInfoWithClass:(Class)cls;

/// 初始化类信息
+ (nullable instancetype)classInfoWithClassName:(NSString *)className;

@end


/// 模型属性信息
@interface CBORModelPropertyMeta : NSObject {
    @package
    /// 属性名称
    NSString *_name;
    /// 属性类型
    CBOREncodingType _type;
    /// 属性NS类型
    CBOREncodingNSType _nsType;
    /// 是否是数字类型
    BOOL _isCNumber;
    /// 属性类
    Class _cls;
    /// 通用类
    Class _genericCls;
    /// 属性对象Get选择器
    SEL _getter;
    /// 属性对象Set选择器
    SEL _setter;
    /// 是否允许KVC
    BOOL _isKVCCompatible;
    /// 是否允许结构体编解码
    BOOL _isStructAvailableForKeyedArchiver;
    /// 是否存在自定义字典解析`+modelCustomClassForDictionary:`
    BOOL _hasCustomClassFromDictionary;
    
    NSString *_mappedToKey;      ///< the key mapped to
    NSArray *_mappedToKeyPath;   ///< the key path mapped to (nil if the name is not key path)
    NSArray *_mappedToKeyArray;  ///< the key(NSString) or keyPath(NSArray) array (nil if not mapped to multiple keys)
    /// 属性信息
    CBORClassPropertyInfo *_info;
    /// 映射信息
    CBORModelPropertyMeta *_next;
    
    /// 是否自定义CBOR的主要与次要类型
    BOOL _isCustomCBORType;
    /// CBOR主要类型
    CBORMajorType _major;
    /// CBOR次要类型
    CBORUInt64 _minor;
}
@end

/// 模型类信息
@interface CBORModelMeta : NSObject {
    @package
    /// 类信息
    CBORClassInfo *_classInfo;
    /// Key:匹配的key或keyPath, Value:`CBORModelPropertyMeta`
    NSDictionary *_mapper;
    /// 所有属性信息列表 `[CBORModelPropertyMeta]`
    NSArray *_allPropertyMetas;
    /// 属性映射KeyPath `CBORModelPropertyMeta]`
    NSArray *_keyPathPropertyMetas;
    /// 属性映射多Key `[CBORModelPropertyMeta]`
    NSArray *_multiKeysPropertyMetas;
    /// `_mapper`数量
    NSUInteger _keyMappedCount;
    /// 模型类类型
    CBOREncodingNSType _nsType;
    
    BOOL _hasCustomWillTransformFromDictionary;
    BOOL _hasCustomTransformFromDictionary;
    BOOL _hasCustomTransformToDictionary;
    BOOL _hasCustomClassFromDictionary;
}

+ (instancetype)metaWithClass:(Class)cls;

@end

NS_ASSUME_NONNULL_END
