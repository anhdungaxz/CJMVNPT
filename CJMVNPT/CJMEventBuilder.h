#import <Foundation/Foundation.h>

@class CJMValidationResult;
@class CJMInAppNotification;
@class CJMInboxMessage;
@class CJMDisplayUnit;

@interface CJMEventBuilder : NSObject

+ (void)build:(NSString * _Nonnull)eventName completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)build:(NSString * _Nonnull)eventName withEventActions:(NSDictionary * _Nullable)eventActions completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)buildChargedEventWithDetails:(NSDictionary * _Nonnull)chargeDetails
                            andItems:(NSArray * _Nullable)items completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CJMValidationResult*> * _Nullable errors))completion;

+ (void)buildPushNotificationEvent:(BOOL)clicked
                   forNotification:(NSDictionary * _Nonnull)notification
                 completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)buildInAppNotificationStateEvent:(BOOL)clicked
                         forNotification:(CJMInAppNotification * _Nonnull)notification
                      andQueryParameters:(NSDictionary * _Nullable)params
                       completionHandler:(void(^ _Nonnull)(NSDictionary* _Nullable event, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)buildInboxMessageStateEvent:(BOOL)clicked
                         forMessage:(CJMInboxMessage * _Nonnull)message
                 andQueryParameters:(NSDictionary * _Nullable)params
                  completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CJMValidationResult*> * _Nullable errors))completion;

+ (void)buildDisplayViewStateEvent:(BOOL)clicked
                    forDisplayUnit:(CJMDisplayUnit * _Nonnull)displayUnit
                andQueryParameters:(NSDictionary * _Nullable)params
                 completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CJMValidationResult*> * _Nullable errors))completion;

+ (void)buildGeofenceStateEvent:(BOOL)entered
                 forGeofenceDetails:(NSDictionary * _Nonnull)geofenceDetails
              completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CJMValidationResult*> * _Nullable errors))completion;

@end
