#import <Foundation/Foundation.h>

@protocol CJMInboxViewControllerDelegate;
@class CJMInboxStyleConfig;

@protocol CJMInboxViewControllerAnalyticsDelegate <NSObject>
@required
- (void)messageDidShow:(CJMInboxMessage * _Nonnull)message;
- (void)messageDidSelect:(CJMInboxMessage * _Nonnull)message atIndex:(int)index withButtonIndex:(int)buttonIndex;
@end

@interface CJMInboxViewController ()

- (instancetype _Nonnull)init __unavailable;

- (instancetype _Nonnull)initWithMessages:(NSArray * _Nonnull)messages
                                   config:(CJMInboxStyleConfig * _Nonnull)config
                                 delegate:(id<CJMInboxViewControllerDelegate> _Nullable)delegate
                        analyticsDelegate:(id<CJMInboxViewControllerAnalyticsDelegate> _Nullable)analyticsDelegate;

@end
