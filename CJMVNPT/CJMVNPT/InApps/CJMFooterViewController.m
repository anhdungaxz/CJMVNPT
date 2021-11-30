
#import "CJMFooterViewController.h"
#import "CJMBaseHeaderFooterViewControllerPrivate.h"

@interface CJMFooterViewController () {
    
}

@property (nonatomic, strong) IBOutlet UIView *containerView;

@end

@implementation CJMFooterViewController

- (void)loadView {
    [super loadView];
    [[CJMInAppUtils bundle] loadNibNamed:[CJMInAppUtils XibNameForControllerName:NSStringFromClass([CJMFooterViewController class])] owner:self options:nil];
}

- (void)layoutNotification {
    [super layoutNotification];
    if (@available(iOS 11, *)) {
        UILayoutGuide *layoutGuide = self.view.safeAreaLayoutGuide;
        [self.containerView.bottomAnchor constraintEqualToAnchor:layoutGuide.bottomAnchor].active = YES;
    }
}


@end
