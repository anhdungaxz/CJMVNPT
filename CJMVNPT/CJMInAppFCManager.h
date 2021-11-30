#import <Foundation/Foundation.h>

@class CJMInstanceConfig;
@class CJMInAppNotification;

@interface CJMInAppFCManager : NSObject

- (instancetype)initWithConfig:(CJMInstanceConfig *)config guid:(NSString *)guid;

- (void)checkUpdateDailyLimits;

- (BOOL)canShow:(CJMInAppNotification *)inapp;

- (void)didDismiss:(CJMInAppNotification *)inapp;

- (void)resetSession;

- (void)changeUserWithGuid:(NSString *)guid;

- (void)didShow:(CJMInAppNotification *)inapp;

- (void)updateLimitsPerDay:(int)perDay andPerSession:(int)perSession;

- (void)attachToHeader:(NSMutableDictionary *)header;

- (void)processResponse:(NSDictionary *)response;

- (BOOL)hasLifetimeCapacityMaxedOut:(CJMInAppNotification *)dictionary;

- (BOOL)hasDailyCapacityMaxedOut:(CJMInAppNotification *)dictionary;

@end
