#import <Foundation/Foundation.h>

@class CJMClassDescription;
@class CJMObjectSerializerContext;
@class CJMObjectSerializerConfig;
@class CJMObjectIdentityProvider;

@interface CJMObjectSerializer : NSObject

- (instancetype)initWithConfiguration:(CJMObjectSerializerConfig *)configuration
        objectIdentityProvider:(CJMObjectIdentityProvider *)objectIdentityProvider;

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject;

@end

