#import "CJMHeaderViewController.h"
#import "CJMBaseHeaderFooterViewControllerPrivate.h"
#import "CJMInAppResources.h"

@interface CJMHeaderViewController () {
}

@property (nonatomic, strong) IBOutlet UIView *containerView;

@end

@implementation CJMHeaderViewController

- (void)loadView {
    [super loadView];
    [[CJMInAppUtils bundle] loadNibNamed:[CJMInAppUtils XibNameForControllerName:NSStringFromClass([CJMHeaderViewController class])] owner:self options:nil];
}


#pragma mark - Setup Notification

- (void)layoutNotification {
    [super layoutNotification];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat topLength = self.topLayoutGuide.length;
    [[NSLayoutConstraint constraintWithItem: self.containerView
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:self.view attribute:NSLayoutAttributeTop
                                 multiplier:1.0 constant:topLength] setActive:YES];
}


@end
