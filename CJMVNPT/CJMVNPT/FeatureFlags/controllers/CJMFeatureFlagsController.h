#import <Foundation/Foundation.h>

@protocol CJMFeatureFlagsDelegate <NSObject>
@required
- (void)featureFlagsDidUpdate;
@end

@class CleverTapInstanceConfig;

@interface CJMFeatureFlagsController : NSObject

@property (nonatomic, assign, readonly) BOOL isInitialized;

- (instancetype _Nullable ) init __unavailable;

// blocking, call off main thread
- (instancetype _Nullable)initWithConfig:(CleverTapInstanceConfig *_Nonnull)config
                                    guid:(NSString *_Nonnull)guid
                                delegate:(id<CJMFeatureFlagsDelegate>_Nonnull)delegate;

- (void)updateFeatureFlags:(NSArray<NSDictionary*> *_Nullable)featureFlags;

- (BOOL)get:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue;

@end
