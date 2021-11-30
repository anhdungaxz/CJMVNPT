
#import "CJM+Inbox.h"
#import "CJMInboxViewControllerPrivate.h"
#import "CJMCarouselImageMessageCell.h"
#import "CJMInboxSimpleMessageCell.h"
#import "CJMInboxIconMessageCell.h"
#import "CJMInboxBaseMessageCell.h"
#import "CJMCarouselMessageCell.h"

#import "CJMInAppResources.h"
#import "CJMConstants.h"
#import "CJMInAppUtils.h"
#import "CJMInboxUtils.h"
#import "UIView+CJMToast.h"

#import <SDWebImage/UIImage+GIF.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

NSString * const kCellSimpleMessageIdentifier = @"CJMInboxSimpleMessageCell";
NSString * const kCellCarouselMessageIdentifier = @"CJMCarouselMessageCell";
NSString * const kCellCarouselImgMessageIdentifier = @"CJMCarouselImageMessageCell";
NSString * const kCellIconMessageIdentifier = @"CJMInboxIconMessageCell";

NSString * const kDefaultTag = @"All";
static const float kCellSpacing = 6;
static const int kMaxTags = 3;

@interface CJMInboxViewController () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>

@property (nonatomic, copy) NSArray<CJMInboxMessage *> *messages;
@property (nonatomic, copy) NSArray<CJMInboxMessage *> *filterMessages;
@property (nonatomic, copy) NSArray *tags;

@property (nonatomic, assign) int selectedSegmentIndex;
@property (nonatomic, assign) NSIndexPath *currentVideoIndex;
@property (nonatomic, strong) UIView *segmentedControlContainer;
@property (nonatomic, strong) UILabel *listEmptyLabel;

@property (nonatomic, strong) CJMInboxStyleConfig *config;

@property (nonatomic, weak) id<CJMInboxViewControllerDelegate> delegate;
@property (nonatomic, weak) id<CJMInboxViewControllerAnalyticsDelegate> analyticsDelegate;

@property (nonatomic, weak) CJMInboxBaseMessageCell *playingCell;
@property (nonatomic, assign) CGRect tableViewVisibleFrame;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *unreachableCellDictionary;

@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) CGFloat topContentOffset;


@end

@implementation CJMInboxViewController

- (instancetype)initWithMessages:(NSArray *)messages
                          config:(CJMInboxStyleConfig *)config
                        delegate:(id<CJMInboxViewControllerDelegate>)delegate
               analyticsDelegate:(id<CJMInboxViewControllerAnalyticsDelegate>)analyticsDelegate {
    self = [self initWithNibName:NSStringFromClass([CJMInboxViewController class]) bundle:[NSBundle bundleForClass:CJMInboxViewController.class]];
    if (self) {
        _config = [config copy];
        _delegate = delegate;
        _analyticsDelegate = analyticsDelegate;
        _messages = messages;
        _filterMessages = _messages;
        
        NSMutableArray *tags = _config.messageTags.count > 0 ?  [NSMutableArray arrayWithArray:_config.messageTags] : [NSMutableArray new];
        if ([tags count] > 0) {
            [tags insertObject:kDefaultTag atIndex:0];
            _topContentOffset = 33.f;
        }
        if ([tags count] > kMaxTags) {
            _tags = [tags subarrayWithRange:NSMakeRange(0, kMaxTags)];
        } else {
            _tags = tags;
        }
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]
                                    initWithTitle:@"✕"
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(dismissTapped)];
    self.navigationItem.rightBarButtonItem = closeButton;
    self.navigationItem.title = [self getTitle];
    self.navigationController.navigationBar.translucent = false;
    
    self.muted = YES;
    [self addObservers];
    [self registerNibs];
    [self setUpInboxLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self playVideoInVisibleCells];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateInboxLayout];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    if (self.segmentedControlContainer) {
        [self.segmentedControlContainer removeFromSuperview];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self calculateTableViewVisibleFrame];
}

- (void)loadView {
    [super loadView];
}

- (void)traitCollectionDidChange: (UITraitCollection *) previousTraitCollection {
    [super traitCollectionDidChange: previousTraitCollection];
    [self updateInboxLayout];
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMessageTapped:)
                                                 name:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaPlayingNotification:)
                                                 name:CLTAP_INBOX_MESSAGE_MEDIA_PLAYING_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaMutedNotification:)
                                                 name:CLTAP_INBOX_MESSAGE_MEDIA_MUTED_NOTIFICATION object:nil];
    
}

- (void)setUpInboxLayout {
    
    UIColor *color = [CJMInAppUtils CJM_colorWithHexString:@"#EAEAEA"];
    
    self.view.backgroundColor = (_config && _config.backgroundColor) ? _config.backgroundColor : color;
    self.tableView.backgroundColor = (_config && _config.backgroundColor) ? _config.backgroundColor : color;
    
    self.navigationController.view.backgroundColor = (_config && _config.backgroundColor) ? _config.backgroundColor : color;
    self.navigationController.navigationBar.barTintColor = (_config && _config.navigationBarTintColor) ? _config.navigationBarTintColor : [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = (_config && _config.navigationTintColor) ? _config.navigationTintColor : [UIColor blackColor];
    
    if (_config && _config.navigationTintColor) {
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : _config.navigationTintColor};
    }
    
    [self setUpTableViewLayout];
    [self calculateTableViewVisibleFrame];
}

- (void)setUpTableViewLayout {
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, kCellSpacing)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 1.0)];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
}

- (void)updateInboxLayout {
    if ([self.tags count] > 0) {
        [self setUpSegmentedContainer];
    }
    [self showListEmptyLabel];
    [self calculateTableViewVisibleFrame];
}

- (void)registerNibs {
    [self.tableView registerNib:[UINib nibWithNibName:[CJMInboxUtils XibNameForControllerName:NSStringFromClass([CJMInboxSimpleMessageCell class])] bundle:[NSBundle bundleForClass:CJMInboxSimpleMessageCell.class]] forCellReuseIdentifier:kCellSimpleMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:[CJMInboxUtils XibNameForControllerName:NSStringFromClass([CJMCarouselMessageCell class])] bundle:[NSBundle bundleForClass:CJMCarouselMessageCell.class]] forCellReuseIdentifier:kCellCarouselMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:[CJMInboxUtils XibNameForControllerName:NSStringFromClass([CJMCarouselImageMessageCell class])] bundle:[NSBundle bundleForClass:CJMCarouselImageMessageCell.class]] forCellReuseIdentifier:kCellCarouselImgMessageIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:[CJMInboxUtils XibNameForControllerName:NSStringFromClass([CJMInboxIconMessageCell class])] bundle:[NSBundle bundleForClass:CJMInboxIconMessageCell.class]] forCellReuseIdentifier:kCellIconMessageIdentifier];
}

- (NSString*)getTitle {
    return self.config.title ? self.config.title : @"Notifications";
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        [self loadView];
        [self registerNibs];
        [self setUpInboxLayout];
        if ([self.tags count] > 0) {
            [self setUpSegmentedContainer];
        }
        [self showListEmptyLabel];
        [self stopPlay];
        [self.tableView reloadData];
        [self playVideoInVisibleCells];
    } completion:nil];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)calculateTableViewVisibleFrame {
    CGRect frame = self.tableView.frame;
    UIInterfaceOrientation orientation = [[CJMInAppResources getSharedApplication] statusBarOrientation];
    BOOL landscape = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
    if (landscape) {
        frame.origin.y += self.topContentOffset;
        frame.size.height -= self.topContentOffset;
    }
    self.tableViewVisibleFrame = frame;
}

- (void)setUpSegmentedContainer {
    [self.navigationController.view layoutSubviews];
    [self.segmentedControlContainer removeFromSuperview];
    self.segmentedControlContainer = [[UIView alloc] init];
    self.segmentedControlContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.segmentedControlContainer.backgroundColor = (_config && _config.navigationBarTintColor) ? _config.navigationBarTintColor : [UIColor whiteColor];
    [self.navigationController.view addSubview:self.segmentedControlContainer];
    [self addSegmentedControl];
}

- (void)addSegmentedControl {
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems: self.tags];
    segmentedControl.selectedSegmentIndex = _selectedSegmentIndex;
    segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    [segmentedControl addTarget:self
                         action:@selector(segmentSelected:)
               forControlEvents:UIControlEventValueChanged];
    
    if (_config) {
        if (_config.tabSelectedBgColor) {
            if (@available(iOS 13.0, *)) {
                segmentedControl.selectedSegmentTintColor = _config.tabSelectedBgColor;
            } else {
                segmentedControl.tintColor = _config.tabSelectedBgColor;
            }
        }
        if (_config.tabSelectedBgColor) {
            [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : _config.tabSelectedTextColor} forState:UIControlStateSelected];
        }
        if (_config.tabUnSelectedTextColor) {
            [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : _config.tabUnSelectedTextColor} forState:UIControlStateNormal];
        }
    }
    
    [self.segmentedControlContainer addSubview:segmentedControl];
    [self.tableView setContentInset:UIEdgeInsetsMake(_topContentOffset, 0, 0, 0)];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView setContentOffset:CGPointMake(0, -(self->_topContentOffset))
                                animated:NO];
    });
    [self updateSegmentedLayoutConstraint: segmentedControl];
}

- (void)updateSegmentedLayoutConstraint:(UISegmentedControl *)segmentedControl {
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat navBarY = self.navigationController.navigationBar.frame.origin.y;
    [[NSLayoutConstraint constraintWithItem:self.segmentedControlContainer
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:self.navigationController.view attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:(navigationBarHeight+navBarY)] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:self.segmentedControlContainer
                                  attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
                                     toItem:self.navigationController.view attribute:NSLayoutAttributeLeading
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:self.segmentedControlContainer
                                  attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                     toItem:self.navigationController.view attribute:NSLayoutAttributeTrailing
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:self.segmentedControlContainer
                                  attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1 constant:_topContentOffset] setActive:YES];
    
    [[NSLayoutConstraint constraintWithItem:segmentedControl
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:self.segmentedControlContainer attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:segmentedControl
                                  attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
                                     toItem:self.segmentedControlContainer attribute:NSLayoutAttributeLeading
                                 multiplier:1 constant:25] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:segmentedControl
                                  attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                     toItem:self.segmentedControlContainer attribute:NSLayoutAttributeTrailing
                                 multiplier:1 constant:-25] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:segmentedControl
                                  attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1 constant:30] setActive:YES];
}

- (void)segmentSelected:(UISegmentedControl *)sender {
    _selectedSegmentIndex = (int)sender.selectedSegmentIndex;
    if (sender.selectedSegmentIndex == 0) {
        self.filterMessages = self.messages;
    } else {
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"SELF.tagString CONTAINS[c] %@", self.tags[sender.selectedSegmentIndex]];
        self.filterMessages = [self.messages filteredArrayUsingPredicate:filterPredicate];
    }
    [self _reloadTableView];
}

- (void)_reloadTableView {
    [self showListEmptyLabel];
    [self stopPlay];
    [self.tableView setContentOffset:CGPointMake(0, -_topContentOffset) animated:NO];
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
    [self.tableView setContentOffset:CGPointMake(0, -_topContentOffset) animated:NO];
    [self playVideoInVisibleCells];
}

- (void)showListEmptyLabel {
    if (self.filterMessages.count <= 0) {
        CGRect frame = self.view.frame;
        if (!self.listEmptyLabel) {
            self.listEmptyLabel = [[UILabel alloc] init];
            self.listEmptyLabel.text = self.config.noMessageViewText ? self.config.noMessageViewText : [NSString stringWithFormat:@"%@", @"No message(s) to show"];
            self.listEmptyLabel.textColor = self.config.noMessageViewTextColor ? self.config.noMessageViewTextColor : UIColor.blackColor;
            self.listEmptyLabel.textAlignment = NSTextAlignmentCenter;
        }
        if ([self.listEmptyLabel isDescendantOfView:self.view]) {
            [self.listEmptyLabel removeFromSuperview];
        }
        self.listEmptyLabel.frame = CGRectMake(0, 10, frame.size.width, 44);
        [self.view addSubview:self.listEmptyLabel];
    } else {
        if (self.listEmptyLabel) {
            [self.listEmptyLabel removeFromSuperview];
        }
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.filterMessages) {
        return 0;
    }
    return [self.filterMessages count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.filterMessages) {
        return 0;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJMInboxMessage *message = [self.filterMessages objectAtIndex:indexPath.section];
    CJMInboxMessageType messageType = [CJMInboxUtils inboxMessageTypeFromString:message.type];
    NSString *identifier = kCellSimpleMessageIdentifier;
    switch (messageType) {
        case CJMInboxMessageTypeSimple:
            identifier = kCellSimpleMessageIdentifier;
            break;
        case CJMInboxMessageTypeCarousel:
            identifier = kCellCarouselMessageIdentifier;
            break;
        case CJMInboxMessageTypeCarouselImage:
            identifier = kCellCarouselImgMessageIdentifier;
            break;
        case CJMInboxMessageTypeMessageIcon:
            identifier = kCellIconMessageIdentifier;
            break;
        default:
            CJMLogStaticDebug(@"unknown Inbox Message Type, defaulting to Simple message");
            identifier = kCellSimpleMessageIdentifier;
            break;
    }
    CJMInboxBaseMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [cell configureForMessage:message];
    if ([cell hasVideo]) {
        [cell mute:self.muted];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CJMInboxMessage *message = [self.filterMessages objectAtIndex:indexPath.section];
    if (!message.isRead){
        [self _notifyMessageViewed:message];
        [message setRead:YES];
    }
}


#pragma mark - Actions

- (void)dismissTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Inbox Message Handling

- (void)handleMessageTapped:(NSNotification *)notification {
    CJMInboxMessage *message = (CJMInboxMessage*)notification.object;
    NSDictionary *userInfo = (NSDictionary *)notification.userInfo;
    int index = [[userInfo objectForKey:@"index"] intValue];
    int buttonIndex = [[userInfo objectForKey:@"buttonIndex"] intValue];
    if  (buttonIndex >= 0) {
        // handle copy to clipboard
        CJMInboxMessageContent *content = message.content[index];
        NSDictionary *link = content.links[buttonIndex];
        NSString *actionType = link[@"type"];
        if ([actionType caseInsensitiveCompare:@"copy"] == NSOrderedSame) {
            NSString *copy = link[@"copyText"][@"text"];
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = copy;
            [self.parentViewController.view CJM_makeToast:@"Copied to clipboard" duration:2.0 position:CJMToastPositionBottom];
        }
    }
    [self _notifyMessageSelected:message atIndex:index withButtonIndex:buttonIndex];
}

- (void)_notifyMessageViewed:(CJMInboxMessage *)message {
    if (self.analyticsDelegate && [self.analyticsDelegate respondsToSelector:@selector(messageDidShow:)]) {
        [self.analyticsDelegate messageDidShow:message];
    }
}

- (void)_notifyMessageSelected:(CJMInboxMessage *)message atIndex:(int)index withButtonIndex:(int)buttonIndex {
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageDidSelect:atIndex:withButtonIndex:)]) {
        [self.delegate messageDidSelect:message atIndex:index withButtonIndex:buttonIndex];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageButtonTappedWithCustomExtras:)]) {
        if (!(buttonIndex < 0)) {
            CJMInboxMessageContent *content = (CJMInboxMessageContent*)message.content[index];
            NSDictionary *customExtras = [content customDataForLinkAtIndex:buttonIndex];
            if (customExtras && customExtras.count > 0) {
                [self.delegate messageButtonTappedWithCustomExtras:customExtras];
            }
        }
    }
    
    if (self.analyticsDelegate && [self.analyticsDelegate respondsToSelector:@selector(messageDidSelect:atIndex:withButtonIndex:)]) {
        [self.analyticsDelegate messageDidSelect:message atIndex:index withButtonIndex:buttonIndex];
    }
}


#pragma mark - Video Player Handling

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self handleScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate == NO) {
        [self handleScrollStop];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self handleScrollStop];
}

- (void)handleMediaPlayingNotification:(NSNotification*)notification {
    CJMInboxBaseMessageCell *cell = (CJMInboxBaseMessageCell*)notification.object;
    if (!self.playingCell) {
        self.playingCell = cell;
    } else if (self.playingCell != cell) {
        [self stopPlay];
        self.playingCell = cell;
    }
}

- (void)handleMediaMutedNotification:(NSNotification*)notification {
    self.muted = [notification.userInfo[@"muted"] boolValue];
    NSArray<CJMInboxBaseMessageCell *> *visibleCells = [self.tableView visibleCells];
    for (CJMInboxBaseMessageCell *cell in visibleCells) {
        if ([cell hasVideo]) {
            [cell mute:self.muted];
        }
    }
}

- (void)playVideoInVisibleCells {
    if (self.playingCell) {
        [self playWithCell:self.playingCell];
        return;
    }
    [self playWithCell:[self findTheBestPlayCell]];
}

- (void)stopPlay {
    [self.playingCell pause];
    self.playingCell = nil;
}

- (BOOL)cellMediaIsVisible:(CJMInboxBaseMessageCell *)cell {
    if (CGRectIsEmpty(self.tableViewVisibleFrame) || !cell) {
        return NO;
    }
    CGRect referenceRect = [self.tableView.superview convertRect:self.tableViewVisibleFrame toView:nil];
    // use fallback for MessageIcon
    CGRect localMediaRect = (cell.messageType == CJMInboxMessageTypeMessageIcon) ? CGRectZero : [cell videoRect];
    // video
    if (!CGRectIsEmpty(localMediaRect)) {
        CGRect referenceMediaRect = [cell convertRect:localMediaRect toView:nil];
        return CGRectContainsRect(referenceRect, referenceMediaRect);
    }
    // audio/fallback test
    CGPoint viewTopPoint = cell.frame.origin;
    CGFloat topOffset = 1;
    CGFloat bottomOffset = 2;
    CGFloat cellHeight =  cell.bounds.size.height;
    CGFloat multiplier = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 1.5 : 1;
    
    switch (cell.mediaPlayerCellType) {
        case CJMMediaPlayerCellTypeTopLandscape:
            topOffset = 30.0 * multiplier;
            bottomOffset = 100.0 * multiplier;
            break;
        case CJMMediaPlayerCellTypeTopPortrait:
            topOffset = 80.0 * multiplier;
            bottomOffset = 150.0 * multiplier;
            break;
        case CJMMediaPlayerCellTypeMiddleLandscape:
            topOffset = 75.0 * multiplier;
            bottomOffset = 100.0 * multiplier;
            break;
        case CJMMediaPlayerCellTypeMiddlePortrait:
            topOffset = 125.0 * multiplier;
            bottomOffset = 150.0 * multiplier;
            break;
        case CJMMediaPlayerCellTypeBottomLandscape:
            topOffset = 100.0 * multiplier;
            bottomOffset = 50.0 * multiplier;
            break;
        case CJMMediaPlayerCellTypeBottomPortrait:
            topOffset = 150.0 * multiplier;
            bottomOffset = 100.0 * multiplier;
            break;
        default:
            return NO;
            break;
    }
    CGPoint viewLeftTopPoint = viewTopPoint;
    viewLeftTopPoint.y += topOffset;
    CGPoint topCoordinatePoint = [cell.superview convertPoint:viewLeftTopPoint toView:nil];
    BOOL isTopContain = CGRectContainsPoint(referenceRect, topCoordinatePoint);
    
    CGFloat viewBottomY = viewTopPoint.y + cellHeight;
    viewBottomY -= bottomOffset;
    CGPoint viewLeftBottomPoint = CGPointMake(viewTopPoint.x, viewBottomY);
    CGPoint bottomCoordinatePoint = [cell.superview convertPoint:viewLeftBottomPoint toView:nil];
    BOOL isBottomContain = CGRectContainsPoint(referenceRect, bottomCoordinatePoint);
    if(!isTopContain || !isBottomContain){
        return NO;
    }
    return YES;
}

- (CJMInboxBaseMessageCell *)findTheBestPlayCell {
    if(CGRectIsEmpty(self.tableViewVisibleFrame)){
        return nil;
    }
    CJMInboxBaseMessageCell *targetCell = nil;
    UITableView *tableView = self.tableView;
    NSArray<CJMInboxBaseMessageCell *> *visibleCells = [tableView visibleCells];
    
    for (CJMInboxBaseMessageCell *cell in visibleCells) {
        if (![cell hasVideo]) {
            continue;
        }
        if ([self cellMediaIsVisible:cell]) {
            targetCell = cell;
            break;
        }
    }
    return targetCell;
}

- (void)playWithCell:(CJMInboxBaseMessageCell *)cell {
    if (!cell) {
        return;
    }
    self.playingCell = cell;
    [cell mute:self.muted];
    [cell play];
}

- (void)handleScroll {
    if (!self.playingCell) {
        return;
    }
    if (![self cellMediaIsVisible:self.playingCell]) {
        [self stopPlay];
    }
}

- (void)handleScrollStop {
    if (self.playingCell && [self cellMediaIsVisible:self.playingCell]) {
        return;
    }
    
    CJMInboxBaseMessageCell *bestCell = [self findTheBestPlayCell];
    if (!bestCell) {
        [self stopPlay];
        return;
    }
    [self stopPlay];
    [self playWithCell:bestCell];
}

@end
