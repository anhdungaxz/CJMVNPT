
#import "CJMInterstitialImageViewController.h"
#import "CJMImageInAppViewControllerPrivate.h"

@interface CJMInterstitialImageViewController ()

@property (nonatomic, strong) IBOutlet UIView *containerView;

@end

@implementation CJMInterstitialImageViewController

- (void)loadView {
    [super loadView];
    [[CJMInAppUtils bundle] loadNibNamed:[CJMInAppUtils XibNameForControllerName:NSStringFromClass([CJMInterstitialImageViewController class])] owner:self options:nil];
}


#pragma mark - Setup Notification

- (void)layoutNotification {
    [super layoutNotification];
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        [self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[NSLayoutConstraint constraintWithItem:self.containerView
                                      attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.containerView
                                      attribute:NSLayoutAttributeHeight
                                     multiplier:0.6 constant:0] setActive:YES];
        
    }
}

@end
