//
//  CJMManager.h
//  CleverTapSDK
//
//  Created by Phạm Tiến Dũng on 15/03/2021.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kCJM_AES_KEY;
#define kCJM_IDENTIFY @"cjm-identify"

@interface CJMManager : NSObject
+ (nullable instancetype)sharedInstance;

@property (nonatomic, strong, nullable) NSString *token;

//- (void)loginCJM;
////- (void)recordEvent:(NSDictionary *_Nonnull)event withProps:(NSDictionary *_Nonnull)properties;
//- (void)recordEvent:(NSString *_Nonnull)event withProps:(NSDictionary *_Nullable)properties;
//- (void)flushQueue;
//- (void)clearQueue;
//- (void)inflateEventsQueue;
//- (void)persistEventsQueue;

//- (void)sendSystemEvent:(NSArray *)body;

- (NSMutableURLRequest*) forwardRequestCJM:(NSMutableURLRequest *) ctRequest;

- (NSMutableURLRequest*) forwardHandShakeRequestCJM:(NSMutableURLRequest *) ctRequest;

- (NSDictionary*) addCJMBodyData:(NSArray*) data header: (NSDictionary*) header;

//- (void)sendSystemQueue:(NSMutableURLRequest *)systemRequest;
@end

NS_ASSUME_NONNULL_END
