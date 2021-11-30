#import <Foundation/Foundation.h>
#import "CJM+FeatureFlags.h"

@protocol CJMPrivateFeatureFlagsDelegate <NSObject>
@required

@property (atomic, weak) id<CleverTapFeatureFlagsDelegate> _Nullable featureFlagsDelegate;

- (BOOL)getFeatureFlag:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue;

@end

@interface CJMFeatureFlags () {}

@property (nonatomic, weak) id<CJMPrivateFeatureFlagsDelegate> _Nullable privateDelegate;

- (instancetype _Nullable)init __unavailable;

- (instancetype _Nonnull)initWithPrivateDelegate:(id<CJMPrivateFeatureFlagsDelegate> _Nonnull)delegate;

@end
