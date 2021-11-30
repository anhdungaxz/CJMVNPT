#import <Foundation/Foundation.h>
#import "CJM+ProductConfig.h"

@protocol CJMPrivateProductConfigDelegate <NSObject>
@required

@property (atomic, weak) id<CleverTapProductConfigDelegate> _Nullable productConfigDelegate;

- (void)fetchProductConfig;

- (void)activateProductConfig;

- (void)fetchAndActivateProductConfig;

- (void)resetProductConfig;

- (void)setDefaultsProductConfig:(NSDictionary<NSString *, NSObject *> *_Nullable)defaults;

- (void)setDefaultsFromPlistFileNameProductConfig:(NSString *_Nullable)fileName;

- (CJMConfigValue *_Nullable)getProductConfig:(NSString* _Nonnull)key;

@end

@interface CJMConfigValue() {}

- (instancetype _Nullable )initWithData:(NSData *_Nullable)data;

@end


@interface CJMProductConfig () {}

@property(nonatomic, assign) NSInteger fetchConfigCalls;
@property(nonatomic, assign) NSInteger fetchConfigWindowLength;
@property(nonatomic, assign) NSTimeInterval minimumFetchConfigInterval;
@property(nonatomic, assign) NSTimeInterval lastFetchTs;

@property (nonatomic, weak) id<CJMPrivateProductConfigDelegate> _Nullable privateDelegate;

- (instancetype _Nullable)init __unavailable;

- (instancetype _Nonnull)initWithConfig:(CJMInstanceConfig *_Nonnull)config
                         privateDelegate:(id<CJMPrivateProductConfigDelegate>_Nonnull)delegate;

- (void)updateProductConfigWithOptions:(NSDictionary *_Nullable)options;

- (void)updateProductConfigWithLastFetchTs:(NSTimeInterval)lastFetchTs;

- (void)resetProductConfigSettings;
@end
