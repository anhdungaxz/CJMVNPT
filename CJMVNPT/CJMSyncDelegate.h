#import <Foundation/Foundation.h>

@protocol CJMSyncDelegate <NSObject>

/*!
 
 @abstract
 The `CJMSyncDelegate` protocol provides additional/alternative methods for
 notifying your application (the adopting delegate) when the User Profile is initialized.
 
 @discussion
 This method will be called when the User Profile is initialized with the CJM ID of the User Profile.
 The CJM ID is the unique identifier assigned to the User Profile by CJM.
 */
@optional
- (void)profileDidInitialize:(NSString*)CJMID;

/*!
 
 @abstract
 The `CJMSyncDelegate` protocol provides additional/alternative methods for
 notifying your application (the adopting delegate) when the User Profile is initialized.
 
 @discussion
 This method will be called when the User Profile is initialized with the CJM ID of the User Profile.
 The CJM ID is the unique identifier assigned to the User Profile by CJM.
 */
@optional
- (void)profileDidInitialize:(NSString*)CJMID forAccountId:(NSString*)accountId;


/*!
 
 @abstract 
 The `CJMSyncDelegate` protocol provides additional/alternative methods for
 notifying your application (the adopting delegate) about synchronization-related changes to the User Profile/Event History.
 
 @discussion
 the updates argument represents the changed data and is of the form:
 {
 "profile":{"<property1>":{"oldValue":<value>, "newValue":<value>}, ...},
 "events:{"<eventName>":
 {"count":
 {"oldValue":(int)<old count>, "newValue":<new count>},
 "firstTime":
 {"oldValue":(double)<old first time event occurred>, "newValue":<new first time event occurred>},
 "lastTime":
 {"oldValue":(double)<old last time event occurred>, "newValue":<new last time event occurred>},
 }, ...
 }
 }
 
 */

@optional
- (void)profileDataUpdated:(NSDictionary*)updates;

@end
