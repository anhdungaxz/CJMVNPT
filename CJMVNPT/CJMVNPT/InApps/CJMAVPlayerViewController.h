#import <AVKit/AVKit.h>

@class CJMInAppNotification;

@interface CJMAVPlayerViewController : AVPlayerViewController

- (instancetype)initWithNotification:(CJMInAppNotification*)notification;

@end
