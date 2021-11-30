#import <UIKit/UIKit.h>
#import "CJMInAppNotification.h"
#if !(TARGET_OS_TV)
#import "CJMJSInterface.h"
#endif

@class CJMInAppDisplayViewController;

@protocol CJMInAppNotificationDisplayDelegate <NSObject>
- (void)handleNotificationCTA:(NSURL*)ctaURL buttonCustomExtras:(NSDictionary *)buttonCustomExtras forNotification:(CJMInAppNotification*)notification fromViewController:(CJMInAppDisplayViewController*)controller withExtras:(NSDictionary*)extras;
- (void)notificationDidDismiss:(CJMInAppNotification*)notification fromViewController:(CJMInAppDisplayViewController*)controller;
@optional
- (void)notificationDidShow:(CJMInAppNotification*)notification fromViewController:(CJMInAppDisplayViewController*)controller;
@end

@interface CJMInAppDisplayViewController : UIViewController

@property (nonatomic, weak) id <CJMInAppNotificationDisplayDelegate> delegate;
@property (nonatomic, strong, readonly) CJMInAppNotification *notification;

- (instancetype)init __unavailable;
- (instancetype)initWithNotification:(CJMInAppNotification*)notification;
#if !(TARGET_OS_TV)
- (instancetype)initWithNotification:(CJMInAppNotification*)notification jsInterface:(CJMJSInterface *)jsInterface;
#endif

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;
- (BOOL)deviceOrientationIsLandscape;

@end
