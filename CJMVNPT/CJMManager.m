//
//  CJMManager.m
//  CleverTapSDK
//
//  Created by Phạm Tiến Dũng on 15/03/2021.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import "CJMManager.h"
#import "CJM.h"
#import "CJMInstanceConfig.h"
#import "CJMPreferences.h"
#import "CJMConstants.h"

static const void *const kQueueCJMKey = &kQueueCJMKey;

NSString *const CJM_Version = @"1.0.6_20211109";

NSString *const kCJM_AES_KEY = @"dqeqgig123ndb123dsfsdf23g4d56jfq";
NSString *const kQUEUE_NAME_CJM_EVENTS = @"cjm-events";

NSString *const kBaseCJMUrl = @"https://cjmgw.vnptmedia.vn";
//NSString *const kBaseCJMUrl = @"http://123.31.36.223";

//NSString *const kBaseCJMUrl = @"http://10.144.28.117:8888";

static const int kCJMMaxBatchSize = 49;

@interface CJMManager() {}
@property (nonatomic, strong) NSURLSessionDataTask *loginSession;
@property (nonatomic, strong) NSURLSessionDataTask *postEventTask;
@property (nonatomic, assign) int sendQueueFails;
@property (nonatomic, strong) NSMutableArray *eventsQueue;

@end

@implementation CJMManager



+ (nullable instancetype)sharedInstance
{
    static CJMManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CJMManager alloc] init];
        // Do any other initialisation stuff here
        sharedInstance.eventsQueue = [NSMutableArray array];
    });
    return sharedInstance;
}

# pragma mark - Login CJM

- (void)loginCJM {
    @try {
        if (self.loginSession != nil) {
            return;
        }
        self.token = nil;
        CJMInstanceConfig *config = [[CJM sharedInstance] config];
        NSString *targetUrl = [NSString stringWithFormat:@"%@/sdk/login", kBaseCJMUrl];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        
        //Make an NSDictionary that would be converted to an NSData object sent over as JSON with the request body
        NSDictionary *tmp = [[NSDictionary alloc] init];
        NSError *error;
        NSData *postData = [NSJSONSerialization dataWithJSONObject:tmp options:0 error:&error];
        
        [request setHTTPBody:postData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:config.accountId forHTTPHeaderField:@"partner_code"];
        [request setValue:config.accountPasscode forHTTPHeaderField:@"partner_secret"];
        [request setHTTPMethod:@"POST"];
        [request setURL:[NSURL URLWithString:targetUrl]];
        CJMLogStaticDebug(@"login CJM body: %@", request.allHTTPHeaderFields);
        //    NSLog(@"%@",request.allHTTPHeaderFields);
        //    NSLog(@"%@", request.HTTPMethod);
        //    NSLog(@"%@", request.HTTPBody);
        self.loginSession = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
                             ^(NSData * _Nullable data,
                               NSURLResponse * _Nullable response,
                               NSError * _Nullable error) {
            
            @try {
                self.loginSession = nil;
                if (error == nil && data != nil) {
                    NSError *jsonError;
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:NSJSONReadingMutableContainers
                                                                           error:&jsonError];
                    CJMLogStaticDebug(@"Data CJM received: %@", json);
                    //            NSLog(@"Data received: %@", json);
                    if (json != nil &&  [json objectForKey:@"error_code"] != nil) {
                        long code = [json[@"error_code"] longValue];
                        if (code == 600 && [json objectForKey:@"data"] != nil) {
                            self.token = json[@"data"];
                            [self flushQueue];
                        }
                    }
                    
                }
            } @catch (NSException *exception) {
                CJMLogStaticDebug(@"%@: An error occurred CJM: %@", self, exception.debugDescription);
            }
            
            
        }];
        [self.loginSession resume];
    } @catch (NSException *exception) {
        CJMLogStaticDebug( @"%@: An error occurred CJM: %@", self, exception.debugDescription);
    }
    
}

- (BOOL) needLogin {
    return (self.token == nil);
}

# pragma mark - Queue


- (void)flushQueue {
    
    if ([self needLogin]) {
        [self loginCJM];
        return;
    }
    [self sendQueue:self.eventsQueue];
}

- (void)sendQueue:(NSMutableArray *)queue {
    @try {
        if (queue == nil || ((int) [queue count]) <= 0) {
            return;
        }
        
        //fail quá 5 lần thì dừng
        if (_sendQueueFails > 5) {
            return;
        }
        
        // nếu đang có task post event thì dừng
        if (self.postEventTask != nil) {
            return;
        }
        // cần login thì dừng
        if ([self needLogin]) {
            return;
        }
        
        NSString *endpoint = [NSString stringWithFormat:@"%@/events/custom_upload", kBaseCJMUrl];
        
        NSUInteger batchSize = ([queue count] > kCJMMaxBatchSize) ? kCJMMaxBatchSize : [queue count];
        NSArray * batch = [queue subarrayWithRange:NSMakeRange(0, batchSize)];
        
        
        NSDictionary * body = [[NSDictionary alloc] initWithObjectsAndKeys:batch, @"d", nil];
        
        
        NSMutableDictionary * data = [[NSMutableDictionary alloc] init];
        data[@"event_type"] = @"custom";
        data[@"versionCJM"] = CJM_Version;
        data[@"data"] = body;
        data[@"objectId"] = [[CJM sharedInstance] profileGetCJMID];
        NSString * identity = [self getIdentity];
        if (identity) {
            data[@"identity"] = identity;
        }
        NSString *jsonBody = [self jsonObjectToString:data];
        
        CJMLogStaticDebug(@"%@: Sending %@ to CJMGateway servers at %@", self, jsonBody, endpoint);
        //    NSLog(@"%@: Sending %@ to CleverTap servers at %@", self, jsonBody, endpoint);
        
        NSString * authen = [NSString stringWithFormat:@"Bearer %@", self.token];
        //    CleverTapInstanceConfig *config = [[CleverTap sharedInstance] config];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        
        [request setHTTPBody: [jsonBody dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:authen forHTTPHeaderField:@"Authorization"];
        //    [request setValue:config.accountId forHTTPHeaderField:@"partner_name"];
        [request setHTTPMethod:@"POST"];
        [request setURL:[NSURL URLWithString:endpoint]];
        
        
        
        self.postEventTask = [[NSURLSession sharedSession]
                              dataTaskWithRequest:request
                              completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @try {
                    BOOL success = NO;
                    self.postEventTask = nil;
                    if (data == nil) {
                        [self scheduleQueueFlush];
                        [self handleSendQueueFail];
                        return;
                    }
                    if (error) {
                        success = NO;
                        //                    CleverTapLogDebug(self.config.logLevel, @"%@: Network error while sending queue, will retry: %@", self, error.localizedDescription);
                    }
                    NSError *jsonError;
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:NSJSONReadingMutableContainers
                                                                           error:&jsonError];
                    CJMLogStaticDebug(@"Data CJM received: %@", json);
                    if (json != nil && [json objectForKey:@"error_code"] != nil) {
                        long code = [json[@"error_code"] longValue];
                        
                        if (code == 600) {
                            success = YES;
                            
                        } else {
                            success = NO;
                        }
                        
                        if (code == 602) {
                            [self loginCJM];
                            return;
                        }
                        
                        if (!success) {
                            [self scheduleQueueFlush];
                            [self handleSendQueueFail];
                            return;
                        }
                        
                        [self handleSendQueueSuccess];
                        if (batch.count > queue.count) {
                            [queue removeAllObjects];
                        } else {
                            [queue removeObjectsInRange:NSMakeRange(0, batch.count)];
                        }
                        
                        
                        //            if (queue.count > 0) {
                        [self scheduleQueueFlush];
                    }
                } @catch (NSException *exception) {
                    CJMLogStaticDebug( @"%@: An error occurred CJM: %@", self, exception.debugDescription);
                }
            });
            
            
            
        }];
        [self.postEventTask resume];
    } @catch (NSException *exception) {
        CJMLogStaticDebug(@"%@: An error occurred CJM: %@", self, exception.debugDescription);
    }
    
    
}

- (NSMutableURLRequest*) forwardRequestCJM:(NSMutableURLRequest *) ctRequest {
    
    NSString *endpoint = [NSString stringWithFormat:@"%@/events/upload", kBaseCJMUrl];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [[NSURL alloc] initWithString:endpoint]];
    request.allHTTPHeaderFields = ctRequest.allHTTPHeaderFields;
    [request setValue:ctRequest.URL.absoluteString forHTTPHeaderField:@"uri"];
    CJMInstanceConfig *config = [[CJM sharedInstance] config];
    [request setValue:config.accountPasscode forHTTPHeaderField:@"X-CleverTap-Passcode"];
    request.HTTPMethod = ctRequest.HTTPMethod;
    request.HTTPBody = ctRequest.HTTPBody;
    return  request;
}

- (NSMutableURLRequest*) forwardHandShakeRequestCJM:(NSMutableURLRequest *) ctRequest {
    
    NSString *endpoint = [NSString stringWithFormat:@"%@/events/handshake", kBaseCJMUrl];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [[NSURL alloc] initWithString:endpoint]];
    request.allHTTPHeaderFields = ctRequest.allHTTPHeaderFields;
    [request setValue:ctRequest.URL.absoluteString forHTTPHeaderField:@"uri"];
    request.HTTPMethod = ctRequest.HTTPMethod;
    request.HTTPBody = ctRequest.HTTPBody;
    return  request;
}

- (NSDictionary*) addCJMBodyData:(NSArray*) data header: (NSDictionary*) header {
    @try {
        NSMutableDictionary * result = [[NSMutableDictionary alloc] init];
        result[@"versionCJM"] = CJM_Version;
        result[@"data"] = data;
        result[@"objectId"] = header[@"g"];
        
        BOOL isAppLaunch = false;
        for (NSObject* obj in data) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                NSDictionary * dict = (NSDictionary*) obj;
                NSString * evtName = dict[@"evtName"];
                if (evtName && [evtName isEqualToString:CLTAP_APP_LAUNCHED_EVENT]) {
                    isAppLaunch = true;
                    break;
                }
            }
        }
        result[@"has_app_launched"] = [NSNumber numberWithBool:isAppLaunch];
        NSDictionary *arp = header[@"arp"];
        if (arp && [arp count] > 0) {
            NSString * identity = arp[@"k_n"];
            if (identity) {
                NSData *objectData = [identity dataUsingEncoding:NSUTF8StringEncoding];
                NSError *jsonError;
                NSArray *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&jsonError];
                if (json.lastObject) {
                    result[@"identity"] = json.firstObject;
                }
            }
            
        }
        
        return result;
    } @catch (NSException *exception) {
        return  [[NSDictionary alloc] init];
    }
}

- (NSString*) getIdentity {
    @try {
        NSDictionary *arp = [[CJM sharedInstance] getARP];
        if (arp && [arp count] > 0) {
            NSString * identity = arp[@"k_n"];
            if (identity) {
                NSData *objectData = [identity dataUsingEncoding:NSUTF8StringEncoding];
                NSError *jsonError;
                NSArray *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&jsonError];
                return json.lastObject;
            }
            
        }
        return nil;
    } @catch (NSException *exception) {
        return  nil;
    }
    
}

//
//- (void)sendSystemEvent:(NSArray *)body {
//    // cần login thì dừng
//    if ([self needLogin]) {
//        [self loginCJM];
//        return;
//    }
//
//    NSDictionary * bodyData = [[NSDictionary alloc] initWithObjectsAndKeys:body, @"d", nil];
//
//    NSMutableDictionary * data = [[NSMutableDictionary alloc] init];
//    data[@"event_type"] = @"system";
//    data[@"data"] = bodyData;
//    data[@"objectId"] = [[CleverTap sharedInstance] profileGetCleverTapID];
//    NSString * identity = [CJMPreferences getObjectForKey:kCJM_IDENTIFY];
//    if (identity) {
//        data[@"identity"] = identity;
//    }
//
//    NSString *jsonBody = [self jsonObjectToString:data];
//
//    NSString *endpoint = [NSString stringWithFormat:@"%@/events/upload", kBaseCJMUrl];
//
//    NSString * authen = [NSString stringWithFormat:@"Bearer %@", self.token];
//
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//
//    [request setHTTPBody: [jsonBody dataUsingEncoding:NSUTF8StringEncoding]];
//    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//    [request setValue:authen forHTTPHeaderField:@"Authorization"];
//    //    [request setValue:config.accountId forHTTPHeaderField:@"partner_name"];
//    [request setHTTPMethod:@"POST"];
//    [request setURL:[NSURL URLWithString:endpoint]];
////    CJMLogStaticDebug(@"%@: Sending systemEvent %@ to CJMGateway servers at %@", self, jsonBody, endpoint);
//
//
//    NSURLSessionDataTask *postDataTask = [[NSURLSession sharedSession]
//                          dataTaskWithRequest:request
//                          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        dispatch_async(dispatch_get_main_queue(), ^{
////            if (data == nil) {
////                return;
////            }
////            if (error) {
////                return;
////                //                    CleverTapLogDebug(self.config.logLevel, @"%@: Network error while sending queue, will retry: %@", self, error.localizedDescription);
////            }
////            NSError *jsonError;
////            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
////                                                                 options:NSJSONReadingMutableContainers
////                                                                   error:&jsonError];
////            CJMLogStaticDebug(@"Data CJM systemEvent received: %@", json);
//        });
//
//
//
//    }];
//    [postDataTask resume];
//
//}

//- (void)sendSystemQueue:(NSMutableURLRequest *)systemRequest {
//
//    NSString *endpoint = [NSString stringWithFormat:@"%@/events/system_upload", kBaseCJMUrlLocal];
//
//    NSString * authen = [NSString stringWithFormat:@"Bearer %@", self.token];
//
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//
//    [request setHTTPBody: systemRequest.HTTPBody];
//    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//    [request setValue:authen forHTTPHeaderField:@"Authorization"];
//    [request setValue:systemRequest.URL.absoluteString forHTTPHeaderField:@"uri"];
//    for (NSString * key in systemRequest.allHTTPHeaderFields) {
//        [request setValue:[systemRequest.allHTTPHeaderFields valueForKey:key] forHTTPHeaderField:key];
//    }
//    //    [request setValue:config.accountId forHTTPHeaderField:@"partner_name"];
//    [request setHTTPMethod:@"POST"];
//    [request setURL:[NSURL URLWithString:endpoint]];
////    CJMLogStaticDebug(@"%@: Sending systemEvent %@ to CJMGateway servers at %@", self, jsonBody, endpoint);
//
//
//    NSURLSessionDataTask *postDataTask = [[NSURLSession sharedSession]
//                          dataTaskWithRequest:request
//                          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (data == nil) {
//                return;
//            }
//            if (error) {
//                return;
//                //                    CleverTapLogDebug(self.config.logLevel, @"%@: Network error while sending queue, will retry: %@", self, error.localizedDescription);
//            }
//            NSError *jsonError;
//            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
//                                                                 options:NSJSONReadingMutableContainers
//                                                                   error:&jsonError];
//            CJMLogStaticDebug(@"Data CJM systemEvent received: %@", json);
//        });
//
//
//
//    }];
//    [postDataTask resume];
//
//}


- (void)scheduleQueueFlush {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(flushQueue) object:nil];
        [self performSelector:@selector(flushQueue) withObject:nil afterDelay:1];
    });
}


- (void)resetFailsCounter {
    self.sendQueueFails = 0;
}

- (void)handleSendQueueSuccess {
    [self resetFailsCounter];
}

- (void)handleSendQueueFail {
    self.sendQueueFails += 1;
    if (self.sendQueueFails > 5) {
    }
}

# pragma mark - Record event

- (void)recordEvent:(NSString *)event withProps:(NSDictionary *)properties {
    @try {
        NSMutableDictionary *eventDict = [[NSMutableDictionary alloc] init];
        eventDict[@"type"] = @"event";
        eventDict[@"ts"] = @((int) [[NSDate date] timeIntervalSince1970]);
        eventDict[@"evtName"] = event;
        eventDict[@"versionCJM"] = CJM_Version;
        eventDict[@"objectId"] = [[CJM sharedInstance] profileGetCJMID];
        NSString * identity = [self getIdentity];
        if (identity) {
            eventDict[@"identity"] = identity;
        }
        if (properties) {
            eventDict[@"evtData"] = properties;
        } else {
            eventDict[@"evtData"] = [[NSDictionary alloc] init];
        }
        [self.eventsQueue addObject:eventDict];
        if ([self.eventsQueue count] > 500) {
            [self.eventsQueue removeObjectAtIndex:0];
        }
        [self resetFailsCounter];
        [self flushQueue];
    } @catch (NSException *exception) {
        CJMLogStaticDebug( @"%@: An error occurred CJM: %@", self, exception.debugDescription);
    }
    
    
}

//- (void)recordEvent:(NSDictionary *)event withProps:(NSDictionary *)properties {
//    NSMutableDictionary *mutableEvent = [NSMutableDictionary dictionaryWithDictionary:event];
//    CleverTapInstanceConfig *config = [[CleverTap sharedInstance] config];
//    if (!config.accountId || !config.accountToken) {
//        return;
//    }
//    
//    mutableEvent[@"type"] = @"event";
//    mutableEvent[@"ep"] = @((int) [[NSDate date] timeIntervalSince1970]);
//    if (properties != nil) {
//        mutableEvent[@"s"] = properties[@"s"];
//        mutableEvent[@"pg"] = properties[@"pg"];
//        mutableEvent[@"lsl"] = properties[@"lsl"];
//        mutableEvent[@"f"] = properties[@"f"];
//        mutableEvent[@"n"] = properties[@"n"];
//    }
//    
//    
//    NSLog(@"count: %d", self.eventsQueue.count);
//    [self.eventsQueue addObject:mutableEvent];
//    if ([self.eventsQueue count] > 500) {
//        [self.eventsQueue removeObjectAtIndex:0];
//    }
//    [self resetFailsCounter];
//    [self flushQueue];
//    
//}

# pragma mark - Archvive/ Unarchive event

- (void)inflateEventsQueue {
    NSMutableArray * inflate = (NSMutableArray *)[CJMPreferences unarchiveFromFile:[self eventsFileName] removeFile:YES];
    
    [self.eventsQueue addObjectsFromArray:inflate];
    
}

- (void)persistEventsQueue {
    NSString *fileName = [self eventsFileName];
    NSMutableArray *eventsCopy;
    @synchronized (self) {
        eventsCopy = [NSMutableArray arrayWithArray:[self.eventsQueue copy]];
    }
    [CJMPreferences archiveObject:eventsCopy forFileName:fileName];
    
}

- (void)clearQueue {
    self.eventsQueue = (NSMutableArray *)[CJMPreferences unarchiveFromFile:[self eventsFileName] removeFile:YES];
    self.eventsQueue = [NSMutableArray array];
}

- (NSString *)eventsFileName {
    return [self fileNameForQueue:kQUEUE_NAME_CJM_EVENTS];
}

- (NSString *)fileNameForQueue:(NSString *)queueName {
    CJMInstanceConfig *config = [[CJM sharedInstance] config];
    return [NSString stringWithFormat:@"clevertap-%@-%@.plist", config.accountId, queueName];
}


- (NSString *)jsonObjectToString:(id)object {
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    @try {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                           options:0
                                                             error:&error];
        if (error) {
            return @"";
        }
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
    @catch (NSException *exception) {
        return @"";
    }
}

@end
