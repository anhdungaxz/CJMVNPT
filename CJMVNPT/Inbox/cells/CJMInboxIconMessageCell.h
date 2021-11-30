#import "CJMInboxBaseMessageCell.h"

@interface CJMInboxIconMessageCell : CJMInboxBaseMessageCell

@property (strong, nonatomic) IBOutlet UIImageView *cellIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cellIconWidthContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cellIconRatioContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cellIconHeightContraint;

@end
