#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CJMObjectSerializerConfig;
@class CJMObjectIdentityProvider;

@interface CJMApplicationStateSerializer : NSObject

- (instancetype)initWithApplication:(UIApplication *)application               configuration:(CJMObjectSerializerConfig *)configuration objectIdentityProvider:(CJMObjectIdentityProvider *)objectIdentityProvider;

- (UIImage *)snapshotForWindowAtIndex:(NSUInteger)index;

- (NSDictionary *)objectHierarchyForWindowAtIndex:(NSUInteger)index;

@end

