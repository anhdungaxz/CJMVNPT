#import <Foundation/Foundation.h>
#import "CJM.h"
@class CJMInboxMessageContent;

/*!
 
 @abstract
 The `CJMInboxMessage` represents the inbox message object.
 */

@interface CJMInboxMessage : NSObject

@property (nullable, nonatomic, copy, readonly) NSDictionary *json;
@property (nullable, nonatomic, copy, readonly) NSDictionary *customData;

@property (nonatomic, assign, readonly) BOOL isRead;
@property (nonatomic, assign, readonly) NSUInteger date;
@property (nonatomic, assign, readonly) NSUInteger expires;
@property (nullable, nonatomic, copy, readonly) NSString *relativeDate;
@property (nullable, nonatomic, copy, readonly) NSString *type;
@property (nullable, nonatomic, copy, readonly) NSString *messageId;
@property (nullable, nonatomic, copy, readonly) NSString *campaignId;
@property (nullable, nonatomic, copy, readonly) NSString *tagString;
@property (nullable, nonatomic, copy, readonly) NSArray *tags;
@property (nullable, nonatomic, copy, readonly) NSString *orientation;
@property (nullable, nonatomic, copy, readonly) NSString *backgroundColor;
@property (nullable, nonatomic, copy, readonly) NSArray<CJMInboxMessageContent *> *content;

- (void)setRead:(BOOL)read;

@end

/*!
 
 @abstract
 The `CJMInboxMessageContent` represents the inbox message content.
 */

@interface CJMInboxMessageContent : NSObject

@property (nullable, nonatomic, copy, readonly) NSString *title;
@property (nullable, nonatomic, copy, readonly) NSString *titleColor;
@property (nullable, nonatomic, copy, readonly) NSString *message;
@property (nullable, nonatomic, copy, readonly) NSString *messageColor;
@property (nullable, nonatomic, copy, readonly) NSString *backgroundColor;
@property (nullable, nonatomic, copy, readonly) NSString *mediaUrl;
@property (nullable, nonatomic, copy, readonly) NSString *videoPosterUrl;
@property (nullable, nonatomic, copy, readonly) NSString *iconUrl;
@property (nullable, nonatomic, copy, readonly) NSString *actionUrl;
@property (nullable, nonatomic, copy, readonly) NSArray *links;
@property (nonatomic, readonly, assign) BOOL mediaIsAudio;
@property (nonatomic, readonly, assign) BOOL mediaIsVideo;
@property (nonatomic, readonly, assign) BOOL mediaIsImage;
@property (nonatomic, readonly, assign) BOOL mediaIsGif;
@property (nonatomic, readonly, assign) BOOL actionHasUrl;
@property (nonatomic, readonly, assign) BOOL actionHasLinks;

- (NSString *_Nullable)urlForLinkAtIndex:(int)index;
- (NSDictionary *_Nullable)customDataForLinkAtIndex:(int)index;

@end

@protocol CJMInboxViewControllerDelegate <NSObject>
@optional
- (void)messageDidSelect:(CJMInboxMessage *_Nonnull)message atIndex:(int)index withButtonIndex:(int)buttonIndex;
- (void)messageButtonTappedWithCustomExtras:(NSDictionary *_Nullable)customExtras;

@end

/*!
 
 @abstract
 The `CJMInboxStyleConfig` has all the parameters required to configure the styling of your Inbox ViewController
 */

@interface CJMInboxStyleConfig : NSObject

@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) UIColor *backgroundColor;
@property (nonatomic, strong, nullable) NSArray *messageTags;
@property (nonatomic, strong, nullable) UIColor *navigationBarTintColor;
@property (nonatomic, strong, nullable) UIColor *navigationTintColor;
@property (nonatomic, strong, nullable) UIColor *tabSelectedBgColor;
@property (nonatomic, strong, nullable) UIColor *tabSelectedTextColor;
@property (nonatomic, strong, nullable) UIColor *tabUnSelectedTextColor;
@property (nonatomic, strong, nullable) NSString *noMessageViewText;
@property (nonatomic, strong, nullable) UIColor *noMessageViewTextColor;

@end

@interface CJMInboxViewController : UITableViewController

@end

typedef void (^CJMInboxSuccessBlock)(BOOL success);
typedef void (^CJMInboxUpdatedBlock)(void);

@interface CJM (Inbox)

/*!
 @method
 
 @abstract
 Initialized the inbox controller and sends a callback.
 
 @discussion
 Use this method to initialize the inbox controller.
 You must call this method separately for each instance of CJM.
 */

- (void)initializeInboxWithCallback:(CJMInboxSuccessBlock _Nonnull)callback;

/*!
 @method
 
 @abstract
 This method returns the total number of inbox messages for the user.
 */

- (NSUInteger)getInboxMessageCount;

/*!
 @method
 
 @abstract
 This method returns the total number of unread inbox messages for the user.
 */

- (NSUInteger)getInboxMessageUnreadCount;

/*!
 @method
 Get all the inbox messages.
 
 @abstract
 This method returns an array of `CJMInboxMessage` objects for the user.
 */

- (NSArray<CJMInboxMessage *> * _Nonnull)getAllInboxMessages;

/*!
 @method
 Get all the unread inbox messages.
 
 @abstract
 This method returns an array of unread `CJMInboxMessage` objects for the user.
 */

- (NSArray<CJMInboxMessage *> * _Nonnull)getUnreadInboxMessages;

/*!
 @method
 
 @abstract
 This method returns `CJMInboxMessage` object that belongs to the given messageId.
 */

- (CJMInboxMessage * _Nullable)getInboxMessageForId:(NSString * _Nonnull)messageId;

/*!
 @method
 
 @abstract
 This method deletes the given `CJMInboxMessage` object.
 */

- (void)deleteInboxMessage:(CJMInboxMessage * _Nonnull)message;

/*!
 @method
 
 @abstract
 This method marks the given `CJMInboxMessage` object as read.
 */

- (void)markReadInboxMessage:(CJMInboxMessage * _Nonnull) message;

/*!
 @method
 
 @abstract
 This method deletes `CJMInboxMessage` object for the given `Message Id` as String.
 */

- (void)deleteInboxMessageForID:(NSString * _Nonnull)messageId;

/*!
 @method
 
 @abstract
 This method marks the `CJMInboxMessage` object as read for given 'Message Id` as String.
 */

- (void)markReadInboxMessageForID:(NSString * _Nonnull)messageId;

/*!
 @method
 
 @abstract
 Register a callback block when inbox messages are updated.
 */

- (void)registerInboxUpdatedBlock:(CJMInboxUpdatedBlock _Nonnull)block;

/**
 
 @method
 This method opens the controller to display the inbox messages.
 
 @abstract
 The `CJMInboxViewControllerDelegate` protocol provides a method for notifying
 your application when a inbox message is clicked (or tapped).
 
 The `CJMInboxStyleConfig` has all the parameters required to configure the styling of your Inbox ViewController
 */

- (CJMInboxViewController * _Nullable)newInboxViewControllerWithConfig:(CJMInboxStyleConfig * _Nullable)config andDelegate:(id<CJMInboxViewControllerDelegate> _Nullable )delegate;

/*!
 @method
 
 @abstract
 Record Notification Viewed for App Inbox.
 */
- (void)recordInboxNotificationViewedEventForID:(NSString * _Nonnull)messageId;

/*!
 @method
 
 @abstract
 Record Notification Clicked for App Inbox.
 */
- (void)recordInboxNotificationClickedEventForID:(NSString * _Nonnull)messageId;


@end
