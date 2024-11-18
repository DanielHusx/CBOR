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

NS_ASSUME_NONNULL_BEGIN
/// 模型无需遵循协议`CBORModel`，在自身实现即可
@protocol CBORModel <NSObject>
@optional
/// 自定义属性指定主要类型；参考`CBORMajorType`
+ (nullable NSDictionary<NSString *, NSNumber *> *)modelCustomPropertyMajor;
/// 自定义属性指定次要类型；参考`CBORTagType, CBORAdditionalType`
///
/// - Attentions: 务必存在对应Major，否则设置无效
+ (nullable NSDictionary<NSString *, NSNumber *> *)modelCustomPropertyMinor;
/// 自定义属性构建CBOR时的顺序
+ (nullable NSArray <NSString *> *)modelCustomPropertySequeue;

/// 自定义属性替换对应JSON的Key列表，例如： `@{@"desc"  : @"ext.desc", @"bookID": @[@"id", @"ID", @"book_id"]};`
+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper;

/// 定义属性指定的对象类，例如： `@{@"borders" : YYBorder.class, @"attachments" : @"YYAttachment" };`
+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass;

/// JSON字典转模型时，需要自定义特定的类
+ (nullable Class)modelCustomClassForDictionary:(NSDictionary *)dictionary;

/// 黑名单——忽略的属性名称
+ (nullable NSArray<NSString *> *)modelPropertyBlacklist;

/// 白名单——不在白名单的将忽略
+ (nullable NSArray<NSString *> *)modelPropertyWhitelist;

/// JSON字典转模型时，将字典提前转化为自定义字典
- (NSDictionary *)modelCustomWillTransformFromDictionary:(NSDictionary *)dic;

/// JSON字典转模型时，自定义转化字典为自身模型
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic;

/// JSON字典转模型时，自定义设置属性值
- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
