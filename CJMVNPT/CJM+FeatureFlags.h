#import <Foundation/Foundation.h>
#import "CJM.h"

@protocol CleverTapFeatureFlagsDelegate <NSObject>
@optional
- (void)ctFeatureFlagsUpdated;
@end

@interface CJM (FeatureFlags)
@property (atomic, strong, readonly, nonnull) CJMFeatureFlags *featureFlags;
@end

@interface CJMFeatureFlags : NSObject

@property (nonatomic, weak) id<CleverTapFeatureFlagsDelegate> _Nullable delegate;

- (BOOL)get:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue;

@end
