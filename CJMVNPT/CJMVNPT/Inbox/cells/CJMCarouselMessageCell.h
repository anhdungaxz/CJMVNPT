#import "CJMInboxBaseMessageCell.h"
#import "CJMSwipeView.h"

@class CJMCarouselImageView;

@interface CJMCarouselMessageCell : CJMInboxBaseMessageCell<CJMSwipeViewDataSource, CJMSwipeViewDelegate>{
    CGFloat captionHeight;
}

@property (nonatomic, strong) NSMutableArray<CJMCarouselImageView*> *itemViews;
@property (nonatomic, assign) long currentItemIndex;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) CJMSwipeView *swipeView;
@property (nonatomic, strong) IBOutlet UIView *carouselView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *carouselViewHeight;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *carouselViewWidth;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *carouselLandRatioConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *carouselPortRatioConstraint;

- (CGFloat)heightForPageControl;
- (float)getLandscapeMultiplier;
- (void)configurePageControlWithRect:(CGRect)rect;
- (void)configureSwipeViewWithHeightAdjustment:(CGFloat)adjustment;
- (void)handleItemViewTapGesture:(UITapGestureRecognizer *)sender;

@end
