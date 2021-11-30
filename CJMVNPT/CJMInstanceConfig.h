#import <Foundation/Foundation.h>
#import "CJM.h"

@interface CJMInstanceConfig : NSObject

@property (nonatomic, strong, readonly, nonnull) NSString *accountId;
@property (nonatomic, strong, readonly, nonnull) NSString *accountToken;
@property (nonatomic, strong, readonly, nonnull) NSString *accountPasscode;
@property (nonatomic, strong, readonly, nullable) NSString *accountRegion;

@property (nonatomic, assign) BOOL analyticsOnly;
@property (nonatomic, assign) BOOL disableAppLaunchedEvent;
@property (nonatomic, assign) BOOL enablePersonalization;
@property (nonatomic, assign) BOOL useCustomCJMId;
@property (nonatomic, assign) CJMLogLevel logLevel;

- (instancetype _Nonnull) init __unavailable;

- (instancetype _Nonnull)initWithAccountId:(NSString* _Nonnull)accountId
                              accountToken:(NSString* _Nonnull)accountToken
                           accountPasscode:(NSString* _Nonnull)accountPasscode;

- (instancetype _Nonnull)initWithAccountId:(NSString* _Nonnull)accountId
                              accountToken:(NSString* _Nonnull)accountToken
                           accountPasscode:(NSString* _Nonnull)accountPasscode
                             accountRegion:(NSString* _Nonnull)accountRegion;

@end
