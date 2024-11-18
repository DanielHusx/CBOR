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

#import "CBOREncoder.h"
#import "CBORMap.h"
#import "NSNull+CBOR.h"
#import "NSString+CBOR.h"
#import "CBORClassInfo.h"
#import "CBOREncodable.h"
#import <objc/message.h>

extern NSNumber *CBORModelCreateNumberFromProperty(__unsafe_unretained id model,
                                                            __unsafe_unretained CBORModelPropertyMeta *meta);

/// 循环模型转CBOR对象
static CBORObject * CBOREncodeObject(NSObject *model, CBORMajorType major, CBORMinorType minor) {
    if (!model) { return nil; }
    if (model == (id)kCFNull) return [[NSNull null] cborObjectWithMajor:major minor:minor];
    if ([(id<CBOREncodable>)model respondsToSelector:@selector(cborObjectWithMajor:minor:context:)]) {
        return [(id<CBOREncodable>)model cborObjectWithMajor:major
                                                       minor:minor
                                                     context:CBOREncodeObject];
    }
    if ([(id<CBOREncodable>)model respondsToSelector:@selector(cborObjectWithMajor:minor:)]) {
        return [(id<CBOREncodable>)model cborObjectWithMajor:major
                                                       minor:minor];
    }
    
    // 对象类型枚举其属性
    CBORModelMeta *modelMeta = [CBORModelMeta metaWithClass:[model class]];
    if (!modelMeta || modelMeta->_keyMappedCount == 0) return nil;
    
    CBORMap *ret = [[CBORMap alloc] initWithMajor:CBORMajorTypeMap minor:0];
    __unsafe_unretained CBORMap *temp = ret;
    // 遍历属性
    [modelMeta->_allPropertyMetas enumerateObjectsUsingBlock:^(CBORModelPropertyMeta *propertyMeta, NSUInteger idx, BOOL * _Nonnull stop) {
        // 属性不可获取则跳过
        if (!propertyMeta->_getter) return;
        
        BOOL isCustom = propertyMeta->_isCustomCBORType;
        
        CBORMajorType major = isCustom ? propertyMeta->_major : CBORUnknownMajorType;
        CBORUInt64 minor = isCustom ? propertyMeta->_minor : CBORUnknownMinorType;
        
        CBORObject *value = nil;
        if (propertyMeta->_isCNumber) {
            // 数字类型创建数字对象
            NSNumber *number = CBORModelCreateNumberFromProperty(model, propertyMeta);
            value = CBOREncodeObject(number, major, minor);
        } else if (propertyMeta->_nsType) {
            // 原生对象再循环
            id v = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, propertyMeta->_getter);
            value = CBOREncodeObject(v, major, minor);
        } else {
            switch (propertyMeta->_type & CBOREncodingTypeMask) {
                case CBOREncodingTypeObject: {
                    // 对象类型再循环
                    id v = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, propertyMeta->_getter);
                    value = CBOREncodeObject(v, major, minor);
                } break;
                case CBOREncodingTypeClass: {
                    Class v = ((Class (*)(id, SEL))(void *) objc_msgSend)((id)model, propertyMeta->_getter);
                    value = v ? CBOREncodeObject(NSStringFromClass(v), major, minor) : nil;
                } break;
                case CBOREncodingTypeSEL: {
                    SEL v = ((SEL (*)(id, SEL))(void *) objc_msgSend)((id)model, propertyMeta->_getter);
                    value = v ? CBOREncodeObject(NSStringFromSelector(v), major, minor) : nil;
                } break;
                default: break;
            }
        }
        if (!value) return;
        
        if (propertyMeta->_mappedToKeyPath) {
            CBORMap *superCBOR = temp;
            CBORObject *subCBOR = nil;
            // 遍历替换的键值路径
            for (NSUInteger i = 0, max = propertyMeta->_mappedToKeyPath.count; i < max; i++) {
                CBORObject *key = [propertyMeta->_mappedToKeyPath[i] cborObject];
                
                if (i + 1 == max) { // end
                    if (!superCBOR[key]) { superCBOR[key] = value; }
                    break;
                }
                
                subCBOR = superCBOR[key];
                if (subCBOR) {
                    if ([subCBOR isKindOfClass:[CBORMap class]]) {
                        superCBOR[key] = subCBOR;
                    } else {
                        // 其他类型则无法进行下一步
                        break;
                    }
                } else {
                    subCBOR = [[CBORMap alloc] initWithMajor:CBORMajorTypeMap];
                    superCBOR[key] = subCBOR;
                }
                superCBOR = (CBORMap *)subCBOR;
                subCBOR = nil;
            }
        } else {
            CBORObject *key = [propertyMeta->_mappedToKey cborObject];
            if (!key) return;
            
            [temp setCBOR:value forKey:key];
        }
    }];
    
    return ret;
}

@implementation CBOREncoder

+ (CBORObject *)encodeObject:(id)object
                       major:(CBORMajorType)major
                       minor:(CBORUInt64)minor {
    CBORObject *ret = CBOREncodeObject(object, major, minor);
    
    return ret;
}

@end
