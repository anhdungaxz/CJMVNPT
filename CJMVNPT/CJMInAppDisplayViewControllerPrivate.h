#import <UIKit/UIKit.h>
#import "CJMConstants.h"

@interface CJMInAppPassThroughWindow : UIWindow
@end

@protocol CJMInAppPassThroughViewDelegate <NSObject>
@required
- (void)viewWillPassThroughTouch;
@end

@interface CJMInAppPassThroughView : UIView
@property (nonatomic, weak) id<CJMInAppPassThroughViewDelegate> delegate;
@end

@interface CJMInAppDisplayViewController () <CJMInAppPassThroughViewDelegate> {
}

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong, readwrite) CJMInAppNotification *notification;
@property (nonatomic, assign) BOOL shouldPassThroughTouches;

- (void)showFromWindow:(BOOL)animated;
- (void)hideFromWindow:(BOOL)animated;

- (void)tappedDismiss;
- (void)buttonTapped:(UIButton*)button;
- (void)handleButtonClickFromIndex:(int)index;
- (void)handleImageTapGesture;
- (UIButton*)setupViewForButton:(UIButton *)buttonView withData:(CJMNotificationButton *)button withIndex:(NSInteger)index;

@end
