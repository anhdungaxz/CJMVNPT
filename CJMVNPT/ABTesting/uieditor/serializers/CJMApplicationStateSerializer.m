#import "CJMApplicationStateSerializer.h"
#import "CJMConstants.h"
#import "CJMObjectSerializer.h"
#import "CJMClassDescription.h"
#import "CJMObjectSerializerConfig.h"
#import "CJMObjectIdentityProvider.h"

@implementation CJMApplicationStateSerializer {
    CJMObjectSerializer *_serializer;
    UIApplication *_application;
}

- (instancetype)initWithApplication:(UIApplication *)application configuration:(CJMObjectSerializerConfig *)configuration objectIdentityProvider:(CJMObjectIdentityProvider *)objectIdentityProvider {
    
    if (application == nil || configuration == nil) return nil;
    
    self = [super init];
    if (self) {
        _application = application;
        _serializer = [[CJMObjectSerializer alloc] initWithConfiguration:configuration
                                                 objectIdentityProvider:objectIdentityProvider];
    }
    return self;
}

- (UIImage *)snapshotForWindowAtIndex:(NSUInteger)index {
    UIImage *snapshotImage = nil;
    UIWindow *window = [self windowAtIndex:index];
    if (window && !CGRectEqualToRect(window.frame, CGRectZero)) {
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, window.screen.scale);
        if ([window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO] == NO) {
            CJMLogStaticInternal(@"Failed to get the snapshot for window at index: %d.", (int)index);
        }
        snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return snapshotImage;
}

- (NSDictionary *)objectHierarchyForWindowAtIndex:(NSUInteger)index {
    UIWindow *window = [self windowAtIndex:index];
    if (window) {
        return [_serializer serializedObjectsWithRootObject:window];
    }
    return @{};
}

- (UIWindow *)windowAtIndex:(NSUInteger)index {
    if (index > _application.windows.count) return nil;
    return _application.windows[index];
}

@end
