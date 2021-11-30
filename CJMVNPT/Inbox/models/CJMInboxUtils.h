#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CJMInboxMessageType){
    CJMInboxMessageTypeUnknown,
    CJMInboxMessageTypeSimple,
    CJMInboxMessageTypeMessageIcon,
    CJMInboxMessageTypeCarousel,
    CJMInboxMessageTypeCarouselImage,
};

@interface CJMInboxUtils : NSObject

+ (CJMInboxMessageType)inboxMessageTypeFromString:(NSString*_Nonnull)type;
+ (NSString *_Nullable)XibNameForControllerName:(NSString *_Nonnull)controllerName;

@end
