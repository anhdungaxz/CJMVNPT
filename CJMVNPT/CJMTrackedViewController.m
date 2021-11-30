#import "CJMTrackedViewController.h"
#import "CJM.h"

@implementation CJMTrackedViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.screenName) {
        [[CJM sharedInstance] recordScreenView:self.screenName];
    }
}

@end
