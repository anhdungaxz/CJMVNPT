#import "CJMInboxUtils.h"
#if !CJM_NO_INBOX_SUPPORT
#import "CJMInAppResources.h"
#endif

static NSDictionary *_inboxMessageTypeMap;

@implementation CJMInboxUtils

+ (CJMInboxMessageType)inboxMessageTypeFromString:(NSString*)type {
    if (_inboxMessageTypeMap == nil) {
        _inboxMessageTypeMap = @{
            @"simple": @(CJMInboxMessageTypeSimple),
            @"message-icon": @(CJMInboxMessageTypeMessageIcon),
            @"carousel": @(CJMInboxMessageTypeCarousel),
            @"carousel-image": @(CJMInboxMessageTypeCarouselImage),
        };
    }
    
    NSNumber *_type = type != nil ? _inboxMessageTypeMap[type] : @(CJMInboxMessageTypeUnknown);
    if (_type == nil) {
        _type = @(CJMInboxMessageTypeUnknown);
    }
    return [_type integerValue];
}

+ (NSString *)XibNameForControllerName:(NSString *)controllerName {
#if CJM_NO_INBOX_SUPPORT
    return nil;
#else
    NSMutableString *xib = [NSMutableString stringWithString:controllerName];
    UIApplication *sharedApplication = [CJMInAppResources getSharedApplication];
    BOOL landscape = UIInterfaceOrientationIsLandscape(sharedApplication.statusBarOrientation);
    if (landscape) {
        [xib appendString:@"~land"];
    } else {
        [xib appendString:@"~port"];
    }
    return xib;
#endif
}

@end
