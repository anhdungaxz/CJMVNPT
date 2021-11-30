#import "CJMJSInterface.h"
#import "CJM.h"
#import "CJMInstanceConfig.h"
#import "CJMInstanceConfigPrivate.h"

@interface CJMJSInterface (){}

@property (nonatomic, strong) CJMInstanceConfig *config;

@end

@implementation CJMJSInterface

- (instancetype)initWithConfig:(CJMInstanceConfig *)config {
    if (self = [super init]) {
        _config = config;
        [self initUserContentController];
    }
    return self;
}

- (void)initUserContentController {
    _userContentController = [[WKUserContentController alloc] init];
    [_userContentController addScriptMessageHandler:self name:@"clevertap"];
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    if ([message.body isKindOfClass:[NSDictionary class]]) {
        CJM *cjm;
        if (!self.config || self.config.isDefaultInstance){
            cjm = [CJM sharedInstance];
        } else {
            cjm = [CJM instanceWithConfig:self.config];
        }
        if (cjm) {
            [self handleMessageFromWebview:message.body forInstance:cjm];
        }
    }
}

- (void)handleMessageFromWebview:(NSDictionary<NSString *,id> *)message forInstance:(CJM *)CJM {
    NSString *action = [message objectForKey:@"action"];
    if ([action isEqual:@"recordEventWithProps"]) {
        [CJM recordEvent: message[@"event"] withProps: message[@"props"]];
    } else if ([action isEqual: @"profilePush"]) {
        [CJM profilePush: message[@"properties"]];
    } else if ([action isEqual: @"profileSetMultiValues"]) {
        [CJM profileSetMultiValues: message[@"values"] forKey: message[@"key"]];
    } else if ([action isEqual: @"profileAddMultiValue"]) {
        [CJM profileAddMultiValue: message[@"value"] forKey: message[@"key"]];
    } else if ([action isEqual: @"profileAddMultiValues"]) {
        [CJM profileAddMultiValues: message[@"values"] forKey: message[@"key"]];
    } else if ([action isEqual: @"profileRemoveValueForKey"]) {
        [CJM profileRemoveValueForKey: message[@"key"]];
    } else if ([action isEqual: @"profileRemoveMultiValue"]) {
        [CJM profileRemoveMultiValue: message[@"value"] forKey: message[@"key"]];
    } else if ([action isEqual: @"profileRemoveMultiValues"]) {
        [CJM profileRemoveMultiValues: message[@"values"] forKey: message[@"key"]];
    }
}

@end
