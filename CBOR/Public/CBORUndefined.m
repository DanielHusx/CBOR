#import "CBORUndefined.h"
#import "CBOREncodable.h"
#import "CBORSimple.h"

@interface CBORUndefined () <CBOREncodable>

@end

@implementation CBORUndefined

- (CBORObject *)cborObject {
    return [[CBORSimple alloc] initWithMajor:CBORMajorTypeAdditional minor:CBORAdditionalTypeUndefined];
}

- (CBORObject *)cborObjectWithMajor:(CBORMajorType)major minor:(CBORUInt64)minor {
    return [self cborObject];
}

- (BOOL)isEqualTo:(id)object {
    return [object isKindOfClass:[self class]];
}

@end
