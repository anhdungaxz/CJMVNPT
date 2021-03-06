#import "CJM+Inbox.h"

@implementation CJMInboxStyleConfig

- (instancetype)copyWithZone:(NSZone*)zone {
    CJMInboxStyleConfig *copy = [[[self class] allocWithZone:zone] init];
    copy.title = self.title;
    copy.backgroundColor = self.backgroundColor;
    copy.messageTags = self.messageTags;
    copy.navigationBarTintColor = self.navigationBarTintColor;
    copy.navigationTintColor = self.navigationTintColor;
    copy.tabUnSelectedTextColor = self.tabUnSelectedTextColor;
    copy.tabSelectedTextColor = self.tabSelectedTextColor;
    copy.tabSelectedBgColor = self.tabSelectedBgColor;
    copy.noMessageViewText = self.noMessageViewText;
    copy.noMessageViewTextColor = self.noMessageViewTextColor;
    return copy;
}

@end
