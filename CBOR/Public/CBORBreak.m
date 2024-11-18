#import "CBORBreak.h"
#import "CBOREncodable.h"
#import "CBORSimple.h"

@interface CBORBreak () <CBOREncodable>

@end

@implementation CBORBreak

- (CBORObject *)cborObject {
    return [[CBORSimple alloc] initWithMajor:CBORMajorTypeAdditional minor:CBORAdditionalTypeBreak];
}

- (CBORObject *)cborObjectWithMajor:(CBORMajorType)major minor:(CBORUInt64)minor {
    return [self cborObject];
}

- (BOOL)isEqualTo:(id)object {
    return [object isKindOfClass:[self class]];
}

@end
