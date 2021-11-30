#import "CJMCoverImageViewController.h"
#import "CJMImageInAppViewControllerPrivate.h"
#import "CJMInAppResources.h"
#import "CJMDismissButton.h"

@interface CJMCoverImageViewController ()

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet CJMDismissButton *closeButton;

@end

@implementation CJMCoverImageViewController

- (void)loadView {
    [super loadView];
    [[CJMInAppUtils bundle] loadNibNamed:[CJMInAppUtils XibNameForControllerName:NSStringFromClass([CJMCoverImageViewController class])]
                                  owner:self
                                options:nil];
}


#pragma mark - Setup Notification

- (void)layoutNotification {
    [super layoutNotification];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat topLength = self.topLayoutGuide.length;
    [[NSLayoutConstraint constraintWithItem: self.closeButton
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:self.containerView
                                  attribute:NSLayoutAttributeTop
                                 multiplier:1.0 constant:topLength] setActive:YES];
}


@end
