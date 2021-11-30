#import <Foundation/Foundation.h>
#import "CJM+ProductConfig.h"

@protocol CJMProductConfigDelegate <NSObject>
@required
- (void)productConfigDidFetch;
- (void)productConfigDidActivate;
- (void)productConfigDidInitialize;
@end

@class CJMInstanceConfig;

@interface CJMProductConfigController : NSObject

@property (nonatomic, assign, readonly) BOOL isInitialized;

- (instancetype _Nullable ) init __unavailable;

// blocking, call off main thread
- (instancetype _Nullable)initWithConfig:(CJMInstanceConfig *_Nonnull)config
                                    guid:(NSString *_Nonnull)guid
                                delegate:(id<CJMProductConfigDelegate>_Nonnull)delegate;

- (void)updateProductConfig:(NSArray<NSDictionary*> *_Nullable)productConfig;

- (void)activate;

- (void)fetchAndActivate;

- (void)reset;

- (void)setDefaults:(NSDictionary<NSString *, NSObject *> *_Nullable)defaults;

- (void)setDefaultsFromPlistFileName:(NSString *_Nullable)fileName;

- (CJMConfigValue *_Nullable)get:(NSString* _Nonnull)key;

@end
