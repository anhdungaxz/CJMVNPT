#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>
#import <SDWebImage/SDAnimatedImageView+WebCache.h>
#import "CJM+Inbox.h"
#import "CJMInboxMessageActionView.h"
#import "CJMConstants.h"
#import "CJMInAppUtils.h"
#import "CJMInboxUtils.h"
#import "CJMInAppResources.h"
#import "CJMVideoThumbnailGenerator.h"

@class SDAnimatedImageView;

typedef NS_OPTIONS(NSUInteger , CJMMediaPlayerCellType) {
    CJMMediaPlayerCellTypeNone,
    CJMMediaPlayerCellTypeTopLandscape,
    CJMMediaPlayerCellTypeTopPortrait,
    CJMMediaPlayerCellTypeMiddleLandscape,
    CJMMediaPlayerCellTypeMiddlePortrait,
    CJMMediaPlayerCellTypeBottomLandscape,
    CJMMediaPlayerCellTypeBottomPortrait
};

@interface CJMInboxBaseMessageCell : UITableViewCell <CJMInboxActionViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet SDAnimatedImageView *cellImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UIView *readView;
@property (strong, nonatomic) IBOutlet CJMInboxMessageActionView *actionView;
@property (strong, nonatomic) IBOutlet UIView *avPlayerContainerView;
@property (strong, nonatomic) IBOutlet UIView *avPlayerControlsView;
@property (strong, nonatomic) IBOutlet UIView *mediaContainerView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewLRatioConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewPRatioConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *actionViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *readViewWidthConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *dividerCenterXConstraint;

// video controls
@property (nonatomic, strong) UIButton *volumeButton;
@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (nonatomic, strong, readwrite) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerLayer *avPlayerLayer;
@property (nonatomic, weak)   NSTimer *controllersTimer;
@property (nonatomic, assign) NSInteger controllersTimeoutPeriod;
@property (nonatomic, assign) BOOL isAVMuted;
@property (nonatomic, assign) BOOL isControlsHidden;
@property (atomic, assign) BOOL hasVideoPoster;
@property (nonatomic, strong) CJMVideoThumbnailGenerator *thumbnailGenerator;
@property (nonatomic, strong) CJMInboxMessage *message;
@property (atomic, assign) CJMMediaPlayerCellType mediaPlayerCellType;
@property (atomic, assign) CJMInboxMessageType messageType;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;


@property (nonatomic, assign) SDWebImageOptions sdWebImageOptions;
@property (nonatomic, strong) SDWebImageContext *sdWebImageContext;

- (void)volumeButtonTapped:(UIButton *)sender;

- (void)configureForMessage:(CJMInboxMessage *)message;
- (void)configureActionView:(BOOL)hide;
- (BOOL)mediaIsEmpty;
- (BOOL)orientationIsPortrait;
- (BOOL)deviceOrientationIsLandscape;
- (UIImage *)getPortraitPlaceHolderImage;
- (UIImage *)getLandscapePlaceHolderImage;

- (BOOL)hasAudio;
- (BOOL)hasVideo;
- (void)setupMediaPlayer;
- (void)pause;
- (void)play;
- (void)mute:(BOOL)mute;
- (CGRect)videoRect;

- (void)setupInboxMessageActions:(CJMInboxMessageContent *)content;
- (void)handleOnMessageTapGesture:(UITapGestureRecognizer *)sender;

@end
