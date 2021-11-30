#import "CJMObjectIdentityProvider.h"
#import "CJMObjectSequenceGenerator.h"

@implementation CJMObjectIdentityProvider {
    NSMapTable *_objectToIdentifierMap;
    CJMObjectSequenceGenerator *_objectSequence;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _objectToIdentifierMap = [NSMapTable weakToStrongObjectsMapTable];
        _objectSequence = [[CJMObjectSequenceGenerator alloc] init];
    }
    return self;
}

- (NSString *)identifierForObject:(id)object {
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    NSString *identifier = [_objectToIdentifierMap objectForKey:object];
    if (identifier == nil) {
        identifier = [NSString stringWithFormat:@"$%" PRIi32, [_objectSequence nextValue]];
        [_objectToIdentifierMap setObject:identifier forKey:object];
    }
    return identifier;
}

@end
