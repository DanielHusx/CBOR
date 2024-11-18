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

#import "CBORClassInfo.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "CBORModel.h"

/// 通过类型编码获取定义的编码类型
static inline CBOREncodingType CBOREncodingGetType(const char *typeEncoding) {
    char *type = (char *)typeEncoding;
    if (!type) return CBOREncodingTypeUnknown;
    size_t len = strlen(type);
    if (len == 0) return CBOREncodingTypeUnknown;
    
    CBOREncodingType qualifier = 0;
    bool prefix = true;
    while (prefix) {
        switch (*type) {
            case 'r': {
                qualifier |= CBOREncodingTypeQualifierConst;
                type++;
            } break;
            case 'n': {
                qualifier |= CBOREncodingTypeQualifierIn;
                type++;
            } break;
            case 'N': {
                qualifier |= CBOREncodingTypeQualifierInout;
                type++;
            } break;
            case 'o': {
                qualifier |= CBOREncodingTypeQualifierOut;
                type++;
            } break;
            case 'O': {
                qualifier |= CBOREncodingTypeQualifierBycopy;
                type++;
            } break;
            case 'R': {
                qualifier |= CBOREncodingTypeQualifierByref;
                type++;
            } break;
            case 'V': {
                qualifier |= CBOREncodingTypeQualifierOneway;
                type++;
            } break;
            default: { prefix = false; } break;
        }
    }

    len = strlen(type);
    if (len == 0) return CBOREncodingTypeUnknown | qualifier;

    switch (*type) {
        case 'v': return CBOREncodingTypeVoid | qualifier;
        case 'B': return CBOREncodingTypeBool | qualifier;
        case 'c': return CBOREncodingTypeInt8 | qualifier;
        case 'C': return CBOREncodingTypeUInt8 | qualifier;
        case 's': return CBOREncodingTypeInt16 | qualifier;
        case 'S': return CBOREncodingTypeUInt16 | qualifier;
        case 'i': return CBOREncodingTypeInt32 | qualifier;
        case 'I': return CBOREncodingTypeUInt32 | qualifier;
        case 'l': return CBOREncodingTypeInt32 | qualifier;
        case 'L': return CBOREncodingTypeUInt32 | qualifier;
        case 'q': return CBOREncodingTypeInt64 | qualifier;
        case 'Q': return CBOREncodingTypeUInt64 | qualifier;
        case 'f': return CBOREncodingTypeFloat | qualifier;
        case 'd': return CBOREncodingTypeDouble | qualifier;
        case 'D': return CBOREncodingTypeLongDouble | qualifier;
        case '#': return CBOREncodingTypeClass | qualifier;
        case ':': return CBOREncodingTypeSEL | qualifier;
        case '*': return CBOREncodingTypeCString | qualifier;
        case '^': return CBOREncodingTypePointer | qualifier;
        case '[': return CBOREncodingTypeCArray | qualifier;
        case '(': return CBOREncodingTypeUnion | qualifier;
        case '{': return CBOREncodingTypeStruct | qualifier;
        case '@': {
            if (len == 2 && *(type + 1) == '?')
                return CBOREncodingTypeBlock | qualifier;
            else
                return CBOREncodingTypeObject | qualifier;
        }
        default: return CBOREncodingTypeUnknown | qualifier;
    }
}


/// Get the Foundation class type from property info.
/// 根据原生类获取类类型
static inline CBOREncodingNSType CBORClassGetNSType(Class cls) {
    if (!cls) return CBOREncodingTypeNSUnknown;
    if ([cls isSubclassOfClass:[NSMutableString class]]) return CBOREncodingTypeNSMutableString;
    if ([cls isSubclassOfClass:[NSString class]]) return CBOREncodingTypeNSString;
    if ([cls isSubclassOfClass:[NSDecimalNumber class]]) return CBOREncodingTypeNSDecimalNumber;
    if ([cls isSubclassOfClass:[NSNumber class]]) return CBOREncodingTypeNSNumber;
    if ([cls isSubclassOfClass:[NSValue class]]) return CBOREncodingTypeNSValue;
    if ([cls isSubclassOfClass:[NSMutableData class]]) return CBOREncodingTypeNSMutableData;
    if ([cls isSubclassOfClass:[NSData class]]) return CBOREncodingTypeNSData;
    if ([cls isSubclassOfClass:[NSDate class]]) return CBOREncodingTypeNSDate;
    if ([cls isSubclassOfClass:[NSURL class]]) return CBOREncodingTypeNSURL;
    if ([cls isSubclassOfClass:[NSMutableArray class]]) return CBOREncodingTypeNSMutableArray;
    if ([cls isSubclassOfClass:[NSArray class]]) return CBOREncodingTypeNSArray;
    if ([cls isSubclassOfClass:[NSMutableDictionary class]]) return CBOREncodingTypeNSMutableDictionary;
    if ([cls isSubclassOfClass:[NSDictionary class]]) return CBOREncodingTypeNSDictionary;
    if ([cls isSubclassOfClass:[NSMutableSet class]]) return CBOREncodingTypeNSMutableSet;
    if ([cls isSubclassOfClass:[NSSet class]]) return CBOREncodingTypeNSSet;
    return CBOREncodingTypeNSUnknown;
}

/// Whether the type is c number.
/// 判断数据类型是否是数字类型
static inline BOOL CBOREncodingTypeIsCNumber(CBOREncodingType type) {
    switch (type & CBOREncodingTypeMask) {
        case CBOREncodingTypeBool:
        case CBOREncodingTypeInt8:
        case CBOREncodingTypeUInt8:
        case CBOREncodingTypeInt16:
        case CBOREncodingTypeUInt16:
        case CBOREncodingTypeInt32:
        case CBOREncodingTypeUInt32:
        case CBOREncodingTypeInt64:
        case CBOREncodingTypeUInt64:
        case CBOREncodingTypeFloat:
        case CBOREncodingTypeDouble:
        case CBOREncodingTypeLongDouble: return YES;
        default: return NO;
    }
}





@implementation CBORClassIvarInfo

- (instancetype)initWithIvar:(Ivar)ivar {
    if (!ivar) return nil;
    self = [super init];
    _ivar = ivar;
    const char *name = ivar_getName(ivar);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    _offset = ivar_getOffset(ivar);
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    if (typeEncoding) {
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
        _type = CBOREncodingGetType(typeEncoding);
    }
    return self;
}

@end

@implementation CBORClassMethodInfo

- (instancetype)initWithMethod:(Method)method {
    if (!method) return nil;
    self = [super init];
    _method = method;
    _sel = method_getName(method);
    _imp = method_getImplementation(method);
    const char *name = sel_getName(_sel);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    const char *typeEncoding = method_getTypeEncoding(method);
    if (typeEncoding) {
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
    }
    char *returnType = method_copyReturnType(method);
    if (returnType) {
        _returnTypeEncoding = [NSString stringWithUTF8String:returnType];
        free(returnType);
    }
    unsigned int argumentCount = method_getNumberOfArguments(method);
    if (argumentCount > 0) {
        NSMutableArray *argumentTypes = [NSMutableArray new];
        for (unsigned int i = 0; i < argumentCount; i++) {
            char *argumentType = method_copyArgumentType(method, i);
            NSString *type = argumentType ? [NSString stringWithUTF8String:argumentType] : nil;
            [argumentTypes addObject:type ? type : @""];
            if (argumentType) free(argumentType);
        }
        _argumentTypeEncodings = argumentTypes;
    }
    return self;
}

@end

@implementation CBORClassPropertyInfo

- (instancetype)initWithProperty:(objc_property_t)property {
    if (!property) return nil;
    self = [super init];
    _property = property;
    const char *name = property_getName(property);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    
    CBOREncodingType type = 0;
    unsigned int attrCount;
    objc_property_attribute_t *attrs = property_copyAttributeList(property, &attrCount);
    for (unsigned int i = 0; i < attrCount; i++) {
        switch (attrs[i].name[0]) {
            case 'T': { // Type encoding
                if (attrs[i].value) {
                    _typeEncoding = [NSString stringWithUTF8String:attrs[i].value];
                    type = CBOREncodingGetType(attrs[i].value);
                    
                    if ((type & CBOREncodingTypeMask) == CBOREncodingTypeObject && _typeEncoding.length) {
                        NSScanner *scanner = [NSScanner scannerWithString:_typeEncoding];
                        if (![scanner scanString:@"@\"" intoString:NULL]) continue;
                        
                        NSString *clsName = nil;
                        if ([scanner scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString:@"\"<"] intoString:&clsName]) {
                            if (clsName.length) _cls = objc_getClass(clsName.UTF8String);
                        }
                        
                        NSMutableArray *protocols = nil;
                        while ([scanner scanString:@"<" intoString:NULL]) {
                            NSString* protocol = nil;
                            if ([scanner scanUpToString:@">" intoString: &protocol]) {
                                if (protocol.length) {
                                    if (!protocols) protocols = [NSMutableArray new];
                                    [protocols addObject:protocol];
                                }
                            }
                            [scanner scanString:@">" intoString:NULL];
                        }
                        _protocols = protocols;
                    }
                }
            } break;
            case 'V': { // Instance variable
                if (attrs[i].value) {
                    _ivarName = [NSString stringWithUTF8String:attrs[i].value];
                }
            } break;
            case 'R': {
                type |= CBOREncodingTypePropertyReadonly;
            } break;
            case 'C': {
                type |= CBOREncodingTypePropertyCopy;
            } break;
            case '&': {
                type |= CBOREncodingTypePropertyRetain;
            } break;
            case 'N': {
                type |= CBOREncodingTypePropertyNonatomic;
            } break;
            case 'D': {
                type |= CBOREncodingTypePropertyDynamic;
            } break;
            case 'W': {
                type |= CBOREncodingTypePropertyWeak;
            } break;
            case 'G': {
                type |= CBOREncodingTypePropertyCustomGetter;
                if (attrs[i].value) {
                    _getter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                }
            } break;
            case 'S': {
                type |= CBOREncodingTypePropertyCustomSetter;
                if (attrs[i].value) {
                    _setter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                }
            } // break; commented for code coverage in next line
            default: break;
        }
    }
    if (attrs) {
        free(attrs);
        attrs = NULL;
    }
    
    _type = type;
    if (_name.length) {
        if (!_getter) {
            _getter = NSSelectorFromString(_name);
        }
        if (!_setter) {
            _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [_name substringToIndex:1].uppercaseString, [_name substringFromIndex:1]]);
        }
    }
    return self;
}

@end

@implementation CBORClassInfo {
    BOOL _needUpdate;
}

- (instancetype)initWithClass:(Class)cls {
    if (!cls) return nil;
    self = [super init];
    _cls = cls;
    _superCls = class_getSuperclass(cls);
    _isMeta = class_isMetaClass(cls);
    if (!_isMeta) {
        _metaCls = objc_getMetaClass(class_getName(cls));
    }
    _name = NSStringFromClass(cls);
    [self _update];

    _superClassInfo = [self.class classInfoWithClass:_superCls];
    return self;
}

- (void)_update {
    _ivarInfos = nil;
    _methodInfos = nil;
    _propertyInfos = nil;
    
    Class cls = self.cls;
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    if (methods) {
        NSMutableDictionary *methodInfos = [NSMutableDictionary new];
        _methodInfos = methodInfos;
        for (unsigned int i = 0; i < methodCount; i++) {
            CBORClassMethodInfo *info = [[CBORClassMethodInfo alloc] initWithMethod:methods[i]];
            if (info.name) methodInfos[info.name] = info;
        }
        free(methods);
    }
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    if (properties) {
        NSMutableDictionary *propertyInfos = [NSMutableDictionary new];
        _propertyInfos = propertyInfos;
        for (unsigned int i = 0; i < propertyCount; i++) {
            CBORClassPropertyInfo *info = [[CBORClassPropertyInfo alloc] initWithProperty:properties[i]];
            if (info.name) propertyInfos[info.name] = info;
        }
        free(properties);
    }
    
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(cls, &ivarCount);
    if (ivars) {
        NSMutableDictionary *ivarInfos = [NSMutableDictionary new];
        _ivarInfos = ivarInfos;
        for (unsigned int i = 0; i < ivarCount; i++) {
            CBORClassIvarInfo *info = [[CBORClassIvarInfo alloc] initWithIvar:ivars[i]];
            if (info.name) ivarInfos[info.name] = info;
        }
        free(ivars);
    }
    
    if (!_ivarInfos) _ivarInfos = @{};
    if (!_methodInfos) _methodInfos = @{};
    if (!_propertyInfos) _propertyInfos = @{};
    
    _needUpdate = NO;
}

- (void)setNeedUpdate {
    _needUpdate = YES;
}

- (BOOL)needUpdate {
    return _needUpdate;
}

+ (instancetype)classInfoWithClass:(Class)cls {
    if (!cls) return nil;
    static CFMutableDictionaryRef classCache;
    static CFMutableDictionaryRef metaCache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        classCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        metaCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    CBORClassInfo *info = CFDictionaryGetValue(class_isMetaClass(cls) ? metaCache : classCache, (__bridge const void *)(cls));
    if (info && info->_needUpdate) {
        [info _update];
    }
    dispatch_semaphore_signal(lock);
    if (!info) {
        info = [[CBORClassInfo alloc] initWithClass:cls];
        if (info) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(info.isMeta ? metaCache : classCache, (__bridge const void *)(cls), (__bridge const void *)(info));
            dispatch_semaphore_signal(lock);
        }
    }
    return info;
}

+ (instancetype)classInfoWithClassName:(NSString *)className {
    Class cls = NSClassFromString(className);
    return [self classInfoWithClass:cls];
}

@end



@implementation CBORModelPropertyMeta

+ (instancetype)metaWithClassInfo:(CBORClassInfo *)classInfo propertyInfo:(CBORClassPropertyInfo *)propertyInfo generic:(Class)generic {
    
    // support pseudo generic class with protocol name
    if (!generic && propertyInfo.protocols) {
        for (NSString *protocol in propertyInfo.protocols) {
            Class cls = objc_getClass(protocol.UTF8String);
            if (cls) {
                generic = cls;
                break;
            }
        }
    }
    
    CBORModelPropertyMeta *meta = [self new];
    meta->_name = propertyInfo.name;
    meta->_type = propertyInfo.type;
    meta->_info = propertyInfo;
    meta->_genericCls = generic;
    
    if ((meta->_type & CBOREncodingTypeMask) == CBOREncodingTypeObject) {
        meta->_nsType = CBORClassGetNSType(propertyInfo.cls);
    } else {
        meta->_isCNumber = CBOREncodingTypeIsCNumber(meta->_type);
    }
    if ((meta->_type & CBOREncodingTypeMask) == CBOREncodingTypeStruct) {
        /*
         It seems that NSKeyedUnarchiver cannot decode NSValue except these structs:
         */
        static NSSet *types = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableSet *set = [NSMutableSet new];
            // 32 bit
            [set addObject:@"{CGSize=ff}"];
            [set addObject:@"{CGPoint=ff}"];
            [set addObject:@"{CGRect={CGPoint=ff}{CGSize=ff}}"];
            [set addObject:@"{CGAffineTransform=ffffff}"];
            [set addObject:@"{UIEdgeInsets=ffff}"];
            [set addObject:@"{UIOffset=ff}"];
            // 64 bit
            [set addObject:@"{CGSize=dd}"];
            [set addObject:@"{CGPoint=dd}"];
            [set addObject:@"{CGRect={CGPoint=dd}{CGSize=dd}}"];
            [set addObject:@"{CGAffineTransform=dddddd}"];
            [set addObject:@"{UIEdgeInsets=dddd}"];
            [set addObject:@"{UIOffset=dd}"];
            types = set;
        });
        if ([types containsObject:propertyInfo.typeEncoding]) {
            meta->_isStructAvailableForKeyedArchiver = YES;
        }
    }
    meta->_cls = propertyInfo.cls;
    
    if (generic) {
        meta->_hasCustomClassFromDictionary = [generic respondsToSelector:@selector(modelCustomClassForDictionary:)];
    } else if (meta->_cls && meta->_nsType == CBOREncodingTypeNSUnknown) {
        meta->_hasCustomClassFromDictionary = [meta->_cls respondsToSelector:@selector(modelCustomClassForDictionary:)];
    }
    
    if (propertyInfo.getter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.getter]) {
            meta->_getter = propertyInfo.getter;
        }
    }
    if (propertyInfo.setter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.setter]) {
            meta->_setter = propertyInfo.setter;
        }
    }
    
    if (meta->_getter && meta->_setter) {
        /*
         KVC invalid type:
         long double
         pointer (such as SEL/CoreFoundation object)
         */
        switch (meta->_type & CBOREncodingTypeMask) {
            case CBOREncodingTypeBool:
            case CBOREncodingTypeInt8:
            case CBOREncodingTypeUInt8:
            case CBOREncodingTypeInt16:
            case CBOREncodingTypeUInt16:
            case CBOREncodingTypeInt32:
            case CBOREncodingTypeUInt32:
            case CBOREncodingTypeInt64:
            case CBOREncodingTypeUInt64:
            case CBOREncodingTypeFloat:
            case CBOREncodingTypeDouble:
            case CBOREncodingTypeObject:
            case CBOREncodingTypeClass:
            case CBOREncodingTypeBlock:
            case CBOREncodingTypeStruct:
            case CBOREncodingTypeUnion: {
                meta->_isKVCCompatible = YES;
            } break;
            default: break;
        }
    }
    
    
    
    return meta;
}
@end




@implementation CBORModelMeta
- (instancetype)initWithClass:(Class)cls {
    CBORClassInfo *classInfo = [CBORClassInfo classInfoWithClass:cls];
    if (!classInfo) return nil;
    self = [super init];
    
    // Get black list
    NSSet *blacklist = nil;
    if ([cls respondsToSelector:@selector(modelPropertyBlacklist)]) {
        NSArray *properties = [(id<CBORModel>)cls modelPropertyBlacklist];
        if (properties) {
            blacklist = [NSSet setWithArray:properties];
        }
    }
    
    // Get white list
    NSSet *whitelist = nil;
    if ([cls respondsToSelector:@selector(modelPropertyWhitelist)]) {
        NSArray *properties = [(id<CBORModel>)cls modelPropertyWhitelist];
        if (properties) {
            whitelist = [NSSet setWithArray:properties];
        }
    }
    
    // Get container property's generic class
    NSDictionary *genericMapper = nil;
    if ([cls respondsToSelector:@selector(modelContainerPropertyGenericClass)]) {
        genericMapper = [(id<CBORModel>)cls modelContainerPropertyGenericClass];
        if (genericMapper) {
            NSMutableDictionary *tmp = [NSMutableDictionary new];
            [genericMapper enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (![key isKindOfClass:[NSString class]]) return;
                Class meta = object_getClass(obj);
                if (!meta) return;
                if (class_isMetaClass(meta)) {
                    tmp[key] = obj;
                } else if ([obj isKindOfClass:[NSString class]]) {
                    Class cls = NSClassFromString(obj);
                    if (cls) {
                        tmp[key] = cls;
                    }
                }
            }];
            genericMapper = tmp;
        }
    }
    
    // Create all property metas.
    NSMutableDictionary *allPropertyMetas = [NSMutableDictionary new];
    CBORClassInfo *curClassInfo = classInfo;
    while (curClassInfo && curClassInfo.superCls != nil) { // recursive parse super class, but ignore root class (NSObject/NSProxy)
        for (CBORClassPropertyInfo *propertyInfo in curClassInfo.propertyInfos.allValues) {
            if (!propertyInfo.name) continue;
            if (blacklist && [blacklist containsObject:propertyInfo.name]) continue;
            if (whitelist && ![whitelist containsObject:propertyInfo.name]) continue;
            CBORModelPropertyMeta *meta = [CBORModelPropertyMeta metaWithClassInfo:classInfo
                                                                    propertyInfo:propertyInfo
                                                                         generic:genericMapper[propertyInfo.name]];
            if (!meta || !meta->_name) continue;
            if (!meta->_getter || !meta->_setter) continue;
            if (allPropertyMetas[meta->_name]) continue;
            allPropertyMetas[meta->_name] = meta;
        }
        curClassInfo = curClassInfo.superClassInfo;
    }
    
    if (allPropertyMetas.count) {
        NSArray *sequeueNames;
        
        if ([cls respondsToSelector:@selector(modelCustomPropertySequeue)]) {
            sequeueNames = [(id <CBORModel>)cls modelCustomPropertySequeue];
        }
        
        if (sequeueNames.count) {
            NSArray *sortedKeys = [allPropertyMetas.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                NSUInteger index1 = [sequeueNames indexOfObject:obj1];
                NSUInteger index2 = [sequeueNames indexOfObject:obj2];
                
                if (index1 != NSNotFound && index2 != NSNotFound) {
                    // 存在顺序则按照此顺序
                    return (index1 < index2) ? NSOrderedAscending : NSOrderedDescending;
                } else if (index1 == NSNotFound) {
                    // 当排在前面的不存在顺序则置后
                    return NSOrderedDescending;
                } else {
                    // 排在后面不存在顺序或都不存在顺序则保持不变
                    return NSOrderedAscending;
                }
            }];
            
            NSMutableArray *sortedAllPropertyMetas = [NSMutableArray arrayWithCapacity:sortedKeys.count];
            for (NSString *key in sortedKeys) {
                [sortedAllPropertyMetas addObject:allPropertyMetas[key]];
            }
            
            _allPropertyMetas = sortedAllPropertyMetas.copy;
        } else {
            _allPropertyMetas = allPropertyMetas.allValues.copy;
        }
    }
    
    // create mapper
    NSMutableDictionary *mapper = [NSMutableDictionary new];
    NSMutableArray *keyPathPropertyMetas = [NSMutableArray new];
    NSMutableArray *multiKeysPropertyMetas = [NSMutableArray new];
    
    if ([cls respondsToSelector:@selector(modelCustomPropertyMajor)]) {
        NSDictionary *customMapper = [(id <CBORModel>)cls modelCustomPropertyMajor];
        [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSNumber *major, BOOL *stop) {
            CBORModelPropertyMeta *propertyMeta = allPropertyMetas[propertyName];
            if (!propertyMeta) return;
            
            CBORByte type = [major unsignedCharValue];
            propertyMeta->_isCustomCBORType = true;
            propertyMeta->_major = type;
        }];
    }
    
    if ([cls respondsToSelector:@selector(modelCustomPropertyMinor)]) {
        NSDictionary *customMapper = [(id <CBORModel>)cls modelCustomPropertyMinor];
        [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSNumber *minor, BOOL *stop) {
            CBORModelPropertyMeta *propertyMeta = allPropertyMetas[propertyName];
            if (!propertyMeta) return;
            
            propertyMeta->_minor = [minor unsignedLongLongValue];
        }];
    }
    
    if ([cls respondsToSelector:@selector(modelCustomPropertyMapper)]) {
        NSDictionary *customMapper = [(id <CBORModel>)cls modelCustomPropertyMapper];
        [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *mappedToKey, BOOL *stop) {
            CBORModelPropertyMeta *propertyMeta = allPropertyMetas[propertyName];
            if (!propertyMeta) return;
            [allPropertyMetas removeObjectForKey:propertyName];
            
            if ([mappedToKey isKindOfClass:[NSString class]]) {
                if (mappedToKey.length == 0) return;
                
                propertyMeta->_mappedToKey = mappedToKey;
                NSArray *keyPath = [mappedToKey componentsSeparatedByString:@"."];
                for (NSString *onePath in keyPath) {
                    if (onePath.length == 0) {
                        NSMutableArray *tmp = keyPath.mutableCopy;
                        [tmp removeObject:@""];
                        keyPath = tmp;
                        break;
                    }
                }
                if (keyPath.count > 1) {
                    propertyMeta->_mappedToKeyPath = keyPath;
                    [keyPathPropertyMetas addObject:propertyMeta];
                }
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
                
            } else if ([mappedToKey isKindOfClass:[NSArray class]]) {
                
                NSMutableArray *mappedToKeyArray = [NSMutableArray new];
                for (NSString *oneKey in ((NSArray *)mappedToKey)) {
                    if (![oneKey isKindOfClass:[NSString class]]) continue;
                    if (oneKey.length == 0) continue;
                    
                    NSArray *keyPath = [oneKey componentsSeparatedByString:@"."];
                    if (keyPath.count > 1) {
                        [mappedToKeyArray addObject:keyPath];
                    } else {
                        [mappedToKeyArray addObject:oneKey];
                    }
                    
                    if (!propertyMeta->_mappedToKey) {
                        propertyMeta->_mappedToKey = oneKey;
                        propertyMeta->_mappedToKeyPath = keyPath.count > 1 ? keyPath : nil;
                    }
                }
                if (!propertyMeta->_mappedToKey) return;
                
                propertyMeta->_mappedToKeyArray = mappedToKeyArray;
                [multiKeysPropertyMetas addObject:propertyMeta];
                
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
            }
        }];
    }
    
    [allPropertyMetas enumerateKeysAndObjectsUsingBlock:^(NSString *name, CBORModelPropertyMeta *propertyMeta, BOOL *stop) {
        propertyMeta->_mappedToKey = name;
        propertyMeta->_next = mapper[name] ?: nil;
        mapper[name] = propertyMeta;
    }];
    
    if (mapper.count) _mapper = mapper;
    if (keyPathPropertyMetas) _keyPathPropertyMetas = keyPathPropertyMetas;
    if (multiKeysPropertyMetas) _multiKeysPropertyMetas = multiKeysPropertyMetas;
    
    _classInfo = classInfo;
    _keyMappedCount = _allPropertyMetas.count;
    _nsType = CBORClassGetNSType(cls);
    _hasCustomWillTransformFromDictionary = ([cls instancesRespondToSelector:@selector(modelCustomWillTransformFromDictionary:)]);
    _hasCustomTransformFromDictionary = ([cls instancesRespondToSelector:@selector(modelCustomTransformFromDictionary:)]);
    _hasCustomTransformToDictionary = ([cls instancesRespondToSelector:@selector(modelCustomTransformToDictionary:)]);
    _hasCustomClassFromDictionary = ([cls respondsToSelector:@selector(modelCustomClassForDictionary:)]);
    
    return self;
}

/// Returns the cached model class meta
+ (instancetype)metaWithClass:(Class)cls {
    if (!cls) return nil;
    static CFMutableDictionaryRef cache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    CBORModelMeta *meta = CFDictionaryGetValue(cache, (__bridge const void *)(cls));
    dispatch_semaphore_signal(lock);
    if (!meta || meta->_classInfo.needUpdate) {
        meta = [[CBORModelMeta alloc] initWithClass:cls];
        if (meta) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache, (__bridge const void *)(cls), (__bridge const void *)(meta));
            dispatch_semaphore_signal(lock);
        }
    }
    return meta;
}

@end
