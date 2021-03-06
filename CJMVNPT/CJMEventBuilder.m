#import <UIKit/UIKit.h>
#import "CJMEventBuilder.h"
#import "CJMValidationResult.h"
#import "CJMValidator.h"
#import "CJMConstants.h"
#import "CJMPreferences.h"
#import "CJMUtils.h"
#import "CJMInAppNotification.h"
#import "CJM+Inbox.h"
#import "CJM+DisplayUnit.h"

NSString *const kCHARGED_EVENT = @"Charged";

@implementation CJMEventBuilder

+ (NSMutableDictionary *)getErrorObject:(CJMValidationResult *)vr {
    NSMutableDictionary *error = [[NSMutableDictionary alloc] init];
    @try {
        error[@"c"] = @([vr errorCode]);
        error[@"d"] = [vr errorDesc];
    } @catch (NSException *e) {
        // no-op
    }
    return error;
}

/**
 * Build a basic event.
 *
 * @param eventName The name of the event
 */
+ (void)build:(NSString *)eventName completionHandler:(void(^)(NSDictionary* event, NSArray<CJMValidationResult*> *errors))completion {
    [self build:eventName withEventActions:nil completionHandler:completion];
}

/**
 * Build an event with a set of attribute pairs.
 *
 */
+ (void)build:(NSString *)eventName withEventActions:(NSDictionary *)eventActions completionHandler:(void(^)(NSDictionary* event, NSArray<CJMValidationResult*> *errors))completion {
    NSMutableArray<CJMValidationResult*> *errors = [NSMutableArray new];
    
    if (eventName == nil || [eventName isEqualToString:@""]) {
        completion(nil, errors);
        return;
    }
    // Check for a restricted event name
    if ([CJMValidator isRestrictedEventName:eventName]) {
        [errors addObject:[CJMValidationResult resultWithErrorCode:512 andMessage:[NSString stringWithFormat:@"Restricted event name - %@", eventName]]];
        CJMLogStaticDebug(@"Restricted event name: %@", eventName);
        completion(nil, errors);
        return;
    }
    
    // Check for a discarded event name
    if ([CJMValidator isDiscaredEventName:eventName]) {
        [errors addObject:[CJMValidationResult resultWithErrorCode:512 andMessage:[NSString stringWithFormat:@"Discarded event name - %@", eventName]]];
        CJMLogStaticDebug(@"%@%@%@", eventName, @" is a discarded event, dropping event: ", eventName);
        completion(nil, errors);
        return;
    }
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    @try {
        // Validate
        CJMValidationResult *vr = [CJMValidator cleanEventName:eventName];
        if ([vr object] == nil || [((NSString *) [vr object]) isEqualToString:@""]) {
            [errors addObject:[CJMValidationResult resultWithErrorCode:512 andMessage:[NSString stringWithFormat:@"Invalid event name - %@", eventName]]];
            CJMLogStaticDebug(@"Invalid event name: %@", eventName);
            // Abort
            completion(nil, errors);
            return;
        }
        // Check for an error
        if ([vr errorCode] != 0) {
            event[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
            if ([vr errorDesc] != nil) {
                CJMLogStaticDebug(@"%@", [vr errorDesc]);
            }
        }
        eventName = (NSString *) [vr object];
        
        NSMutableDictionary *actions = [[NSMutableDictionary alloc] init];
        NSMutableArray *eventActionsAllKeys;
        if (eventActions) {
            eventActionsAllKeys = [NSMutableArray arrayWithArray:[eventActions allKeys]];
        } else {
            eventActionsAllKeys = [NSMutableArray new];
        }
        for (int i = 0; i < [eventActionsAllKeys count]; i++) {
            NSString *key = eventActionsAllKeys[(NSUInteger) i];
            vr = [CJMValidator cleanObjectKey:key];
            if ([vr object] == nil || [((NSString *) [vr object]) isEqualToString:@""]) {
                [errors addObject:[CJMValidationResult resultWithErrorCode:512 andMessage:[NSString stringWithFormat:@"Invalid event property key: %@", key]]];
                CJMLogStaticDebug(@"Invalid event property key: %@", key);
                // Skip
                continue;
            }
            key = (NSString *) [vr object];
            id value = eventActions[key];
            // Check for an error
            if ([vr errorCode] != 0) {
                event[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                if ([vr errorDesc] != nil) {
                    CJMLogStaticDebug(@"%@", [vr errorDesc]);
                }
            }
            BOOL accepted = false;
            @try {
                vr = [CJMValidator cleanObjectValue:value context:CJMValidatorContextEvent];
                accepted = [vr object] != nil;
            } @catch (NSException *e) {
                accepted = false;
            }
            if (!accepted) {
                NSString *errStr = [NSString stringWithFormat:@"For event \"%@\": Property value for property %@ wasn't a primitive (%@)", eventName, key, value];
                CJMLogStaticDebug(@"%@", errStr);
                CJMValidationResult *error = [[CJMValidationResult alloc] init];
                [error setErrorCode:512];
                [error setErrorDesc:errStr];
                [errors addObject:error];
                // Skip this property
                continue;
            }
            value = [vr object];
            // Check for an error
            if ([vr errorCode] != 0) {
                event[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                if ([vr errorDesc] != nil) {
                    CJMLogStaticDebug(@"%@", [vr errorDesc]);
                }
            }
            actions[key] = value;
        }
        event[@"evtName"] = eventName;
        event[@"evtData"] = actions;
        completion(event, errors);
    } @catch (NSException *e) {
        completion(nil, errors);
    }
}

/**
 * Build an event which describes a purchase made.
 *
 */
+ (void)buildChargedEventWithDetails:(NSDictionary *)chargeDetails andItems:(NSArray *)items completionHandler:(void(^)(NSDictionary* event, NSArray<CJMValidationResult*> *errors))completion {
    NSMutableArray<CJMValidationResult*> *errors = [NSMutableArray new];
    
    if (chargeDetails == nil || items == nil) {
        completion(nil, errors);
        return;
    }
    
    if (((int) [items count]) > 50) {
        CJMValidationResult *error = [[CJMValidationResult alloc] init];
        [error setErrorCode:522];
        [error setErrorDesc:@"Charged event contained more than 50 items."];
        CJMLogStaticDebug(@"Charged event contained more than 50 items.");
        [errors addObject:error];
    }
    NSMutableDictionary *evtData = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *chargedEvent = [[NSMutableDictionary alloc] init];
    CJMValidationResult *vr;
    @try {
        NSMutableArray *chargeDetailsAllKeys = [NSMutableArray arrayWithArray:[chargeDetails allKeys]];
        for (int i = 0; i < [chargeDetailsAllKeys count]; i++) {
            NSString *key = chargeDetailsAllKeys[(NSUInteger) i];
            id value = chargeDetails[key];
            vr = [CJMValidator cleanObjectKey:key];
            if ([vr object] == nil || [((NSString *) [vr object]) isEqualToString:@""]) {
                // Skip
                continue;
            }
            key = (NSString *) [vr object];
            // Check for an error
            if ([vr errorCode] != 0) {
                chargedEvent[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                if ([vr errorDesc] != nil) {
                    CJMLogStaticDebug(@"%@", [vr errorDesc]);
                }
            }
            BOOL accepted = false;
            @try {
                vr = [CJMValidator cleanObjectValue:value context:CJMValidatorContextEvent];
                accepted = [vr object] != nil;
            } @catch (NSException *e) {
                accepted = false;
            }
            if (!accepted) {
                NSString *errStr = [NSString stringWithFormat:@"For event Charged: Property value for property %@ wasn't a primitive (%@)", key, value];
                CJMLogStaticDebug(@"%@", errStr);
                CJMValidationResult *error = [[CJMValidationResult alloc] init];
                [error setErrorCode:511];
                [error setErrorDesc:errStr];
                [errors addObject:error];
                // Skip
                continue;
            }
            value = [vr object];
            // Check for an error
            if ([vr errorCode] != 0) {
                chargedEvent[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                if ([vr errorDesc] != nil) {
                    CJMLogStaticDebug(@"%@", [vr errorDesc]);
                }
            }
            evtData[key] = value;
        }
        NSMutableArray *jsonItemsArray = [[NSMutableArray alloc] init];
        for (id map in items) {
            if ([map isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *itemDetails = [[NSMutableDictionary alloc] init];
                NSMutableArray *mapAllKeys = [NSMutableArray arrayWithArray:[map allKeys]];
                for (int i = 0; i < [mapAllKeys count]; i++) {
                    NSString *key = mapAllKeys[(NSUInteger) i];
                    id value = [map objectForKey:key];
                    vr = [CJMValidator cleanObjectKey:key];
                    if ([vr object] == nil || [((NSString *) [vr object]) isEqualToString:@""]) {
                        // Abort
                        completion(nil, errors);
                        return;
                    }
                    key = (NSString *) [vr object];
                    // Check for an error
                    if ([vr errorCode] != 0) {
                        chargedEvent[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                        if ([vr errorDesc] != nil) {
                            CJMLogStaticDebug(@"%@", [vr errorDesc]);
                        }
                    }
                    BOOL accepted = false;
                    @try {
                        vr = [CJMValidator cleanObjectValue:value context:CJMValidatorContextEvent];
                        accepted = [vr object] != nil;
                    } @catch (NSException *e) {
                        accepted = false;
                    }
                    if (!accepted) {
                        NSString *errStr = [NSString stringWithFormat:@"An item's object value for key %@ wasn't a primitive (%@)", key, value];
                        CJMLogStaticDebug(@"%@", errStr);
                        CJMValidationResult *error = [[CJMValidationResult alloc] init];
                        [error setErrorCode:511];
                        [error setErrorDesc:errStr];
                        [errors addObject:error];
                        // Skip
                        continue;
                    }
                    value = [vr object];
                    // Check for an error
                    if ([vr errorCode] != 0) {
                        chargedEvent[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
                        if ([vr errorDesc] != nil) {
                            CJMLogStaticDebug(@"%@", [vr errorDesc]);
                        }
                    }
                    itemDetails[key] = value;
                }
                [jsonItemsArray addObject:itemDetails];
            }
        }
        evtData[@"Items"] = jsonItemsArray;
        
        chargedEvent[@"evtName"] = kCHARGED_EVENT;
        chargedEvent[@"evtData"] = evtData;
        completion(chargedEvent, errors);
    } @catch (NSException *e) {
        completion(nil, errors);
    }
}

/**
 * Raises the Notification Clicked event for Push Notifications event, if clicked is true,
 * otherwise the Notification Viewed event for Push Notifications event, if clicked is false.
 *
 */
+ (void)buildPushNotificationEvent:(BOOL)clicked
                   forNotification:(NSDictionary *)notification
                 completionHandler:(void(^)(NSDictionary* event, NSArray<CJMValidationResult*> *errors))completion {
    if (!notification){
        completion(nil, nil);
        return;
    }
    @try {
        NSMutableDictionary *event = [NSMutableDictionary new];
        NSMutableDictionary *notif = [NSMutableDictionary new];
        // only send through our push data
        for (NSString *x in [notification allKeys]) {
            if (!([CJMUtils doesString:x startWith:CLTAP_NOTIFICATION_TAG] || [CJMUtils doesString:x startWith:CLTAP_NOTIFICATION_TAG_SECONDARY]))
                continue;
            NSString *key = [x stringByReplacingOccurrencesOfString:CLTAP_NOTIFICATION_TAG withString:CLTAP_WZRK_PREFIX];
            id value = notification[x];
            notif[key] = value;
        }
        notif[CLTAP_NOTIFICATION_CLICKED_TAG] = @((long) [[NSDate date] timeIntervalSince1970]);
        event[@"evtName"] = clicked ? CLTAP_NOTIFICATION_CLICKED_EVENT_NAME : CLTAP_NOTIFICATION_VIEWED_EVENT_NAME;
        event[@"evtData"] = notif;
        completion(event, nil);
    } @catch (NSException *e) {
        CJMLogStaticDebug(@"Unable to build push notification clicked event: %@", e.debugDescription);
        completion(nil, nil);
    }
}

/**
 * Raises the Notification Clicked event, if clicked is true,
 * otherwise the Notification Viewed event, if clicked is false.
 *
 */
+ (void)buildInAppNotificationStateEvent:(BOOL)clicked
                         forNotification:(CJMInAppNotification *)notification
                      andQueryParameters:(NSDictionary *)params
                       completionHandler:(void(^)(NSDictionary* event, NSArray<CJMValidationResult*> *errors))completion {
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *notif = [[NSMutableDictionary alloc] init];
    @try {
        NSDictionary *data = notification.jsonDescription;
        for (NSString *x in [data allKeys]) {
            if (![CJMUtils doesString:x startWith:@"wzrk_"])
                continue;
            id value = data[x];
            notif[x] = value;
        }
        if (params) {
            [notif addEntriesFromDictionary:params];
        }
        if ([notif count] == 0) {
            CJMLogStaticInternal(@"Notification does not have any wzrk_* field");
        }
        event[@"evtName"] = clicked ? CLTAP_NOTIFICATION_CLICKED_EVENT_NAME : CLTAP_NOTIFICATION_VIEWED_EVENT_NAME;
        event[@"evtData"] = notif;
        completion(event, nil);
    } @catch (NSException *e) {
        completion(nil, nil);
    }
}

/**
 * Raises the Inbox Message Clicked event, if clicked is true,
 * otherwise the Inbox Message Viewed event, if clicked is false.
 *
 */
+ (void)buildInboxMessageStateEvent:(BOOL)clicked
                         forMessage:(CJMInboxMessage *)message
                 andQueryParameters:(NSDictionary *)params
                  completionHandler:(void(^)(NSDictionary* event, NSArray<CJMValidationResult*> *errors))completion {
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *notif = [[NSMutableDictionary alloc] init];
    @try {
        NSDictionary *data = message.json;
        for (NSString *x in [data allKeys]) {
            if (![CJMUtils doesString:x startWith:@"wzrk_"])
                continue;
            id value = data[x];
            notif[x] = value;
        }
        if (params) {
            [notif addEntriesFromDictionary:params];
        }
        if ([notif count] == 0) {
            CJMLogStaticInternal(@"Inbox Message does not have any wzrk_* field");
        }
        event[@"evtName"] = clicked ? CLTAP_NOTIFICATION_CLICKED_EVENT_NAME : CLTAP_NOTIFICATION_VIEWED_EVENT_NAME;
        event[@"evtData"] = notif;
        completion(event, nil);
    } @catch (NSException *e) {
        completion(nil, nil);
    }
}

/**
 * Raises the Native Display Clicked event, if clicked is true,
 * otherwise the Native Display Viewed event, if clicked is false.
 *
 */
+ (void)buildDisplayViewStateEvent:(BOOL)clicked
                    forDisplayUnit:(CJMDisplayUnit *)displayUnit
                andQueryParameters:(NSDictionary *)params
                 completionHandler:(void(^)(NSDictionary* event, NSArray<CJMValidationResult*> *errors))completion {
    @try {
        NSMutableDictionary *event = [NSMutableDictionary new];
        NSMutableDictionary *notif = [NSMutableDictionary new];
        NSDictionary *data = displayUnit.json;
        for (NSString *x in [data allKeys]) {
            if (!([CJMUtils doesString:x startWith:CLTAP_NOTIFICATION_TAG] || [CJMUtils doesString:x startWith:CLTAP_NOTIFICATION_TAG_SECONDARY]))
                continue;
            NSString *key = [x stringByReplacingOccurrencesOfString:CLTAP_NOTIFICATION_TAG withString:CLTAP_WZRK_PREFIX];
            id value = data[x];
            notif[key] = value;
        }
        notif[CLTAP_NOTIFICATION_CLICKED_TAG] = @((long) [[NSDate date] timeIntervalSince1970]);
        event[@"evtName"] = clicked ? CLTAP_NOTIFICATION_CLICKED_EVENT_NAME : CLTAP_NOTIFICATION_VIEWED_EVENT_NAME;
        event[@"evtData"] = notif;
        completion(event, nil);
    } @catch (NSException *e) {
        completion(nil, nil);
    }
}

/**
 * Raises the Geofence Entered event, if entered is true,
 * otherwise the Geofence Exited event, if entered is false.
 *
 */
+ (void)buildGeofenceStateEvent:(BOOL)entered
             forGeofenceDetails:(NSDictionary * _Nonnull)geofenceDetails
              completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CJMValidationResult*> * _Nullable errors))completion {
    @try {
        NSMutableDictionary *event = [NSMutableDictionary new];
        NSMutableDictionary *notif = [NSMutableDictionary new];
        if (geofenceDetails) {
            [notif addEntriesFromDictionary:geofenceDetails];
        }
        if ([notif count] == 0) {
            CJMLogStaticInternal(@"Geofence does not have any field");
        }
        event[@"evtName"] = entered ? CLTAP_GEOFENCE_ENTERED_EVENT_NAME : CLTAP_GEOFENCE_EXITED_EVENT_NAME;
        event[@"evtData"] = notif;
        completion(event, nil);
    } @catch (NSException *e) {
        completion(nil, nil);
    }
}

@end
