
#import "CJMHalfInterstitialImageViewController.h"
#import "CJMImageInAppViewControllerPrivate.h"

@interface CJMHalfInterstitialImageViewController ()

@end

@implementation CJMHalfInterstitialImageViewController

- (void)loadView {
    [super loadView];
    [[CJMInAppUtils bundle] loadNibNamed:[CJMInAppUtils XibNameForControllerName:NSStringFromClass([CJMHalfInterstitialImageViewController class])]
                                  owner:self
                                options:nil];
}


@end
