#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#if defined(CJM_HOST_WATCHOS)
#import <WatchConnectivity/WatchConnectivity.h>
#endif

#if TARGET_OS_TV
#define CJM_TVOS 1
#endif

#if defined(CJM_TVOS)
#define CJM_NO_INAPP_SUPPORT 1
#define CJM_NO_REACHABILITY_SUPPORT 1
#define CJM_NO_INBOX_SUPPORT 1
#define CJM_NO_AB_SUPPORT 1
#define CJM_NO_DISPLAY_UNIT_SUPPORT 1
#define CJM_NO_GEOFENCE_SUPPORT 1
#endif

@protocol CJMSyncDelegate;
@protocol CJMPushNotificationDelegate;
#if !CJM_NO_INAPP_SUPPORT
@protocol CJMInAppNotificationDelegate;
#endif

@class CJMEventDetail;
@class CJMUTMDetail;
@class CJMInstanceConfig;
@class CJMFeatureFlags;
@class CJMProductConfig;
@class CJMManager;

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"

typedef NS_ENUM(int, CJMLogLevel) {
    CJMLogOff = -1,
    CJMLogInfo = 0,
    CJMLogDebug = 1
};

@interface CJM : NSObject

#pragma mark - Properties

/* -----------------------------------------------------------------------------
 * Instance Properties
 */

/**
 CJM Configuration (e.g. the CJM accountId, token, region, other configuration properties...) for this instance.
 */

@property (nonatomic, strong, readonly, nonnull) CJMInstanceConfig *config;

/* ------------------------------------------------------------------------------------------------------
 * Initialization
 */

/*!
 @method
 
 @abstract
 Initializes and returns a singleton instance of the API.
 
 @discussion
 This method will set up a singleton instance of the CJM class, when you want to make calls to CJM
 elsewhere in your code, you can use this singleton or call sharedInstance.
 
 Returns nil if the CJM Account ID and Token are not provided in apps info.plist
 
 */
+ (nullable instancetype)sharedInstance;

/*!
 @method
 
 @abstract
 Initializes and returns a singleton instance of the API.
 
 @discussion
 This method will set up a singleton instance of the CJM class, when you want to make calls to CJM
 elsewhere in your code, you can use this singleton or call sharedInstanceWithCJMId.
 
 Returns nil if the CJM Account ID and Token are not provided in apps info.plist
 
 CJMUseCustomId key should be set to YES in apps info.plist to enable support for setting custom CJMID.
 
 */
+ (nullable instancetype)sharedInstanceWithCJMID:(NSString * _Nonnull)CJMID;

/*!
 @method
 
 @abstract
 Auto integrates CJM and initializes and returns a singleton instance of the API.
 
 @discussion
 This method will auto integrate CJM to automatically handle device token registration and
 push notification/url referrer tracking, and set up a singleton instance of the CJM class,
 when you want to make calls to CJM elsewhere in your code, you can use this singleton or call sharedInstance.
 
 Returns nil if the CJM Account ID and Token are not provided in apps info.plist
 
 */
+ (nullable instancetype)autoIntegrate;

/*!
 @method
 
 @abstract
 Auto integrates with CJMID CJM and initializes and returns a singleton instance of the API.
 
 @discussion
 This method will auto integrate CJM to automatically handle device token registration and
 push notification/url referrer tracking, and set up a singleton instance of the CJM class,
 when you want to make calls to CJM elsewhere in your code, you can use this singleton or call sharedInstance.
 
 Returns nil if the CJM Account ID and Token are not provided in apps info.plist
 
 CJMUseCustomId key should be set to YES in apps info.plist to enable support for setting custom CJMID.
 
 */
+ (nullable instancetype)autoIntegrateWithCJMID:(NSString * _Nonnull)CJMID;

/*!
 @method
 
 @abstract
 Returns the CJM instance corresponding to the config.accountId param. Use this for multiple instances of the SDK.
 
 @discussion
 Create an instance of CJMInstanceConfig with your CJM Account Id, Token, Region(if any) and other optional config properties.
 Passing that into this method will create (if necessary, and on all subsequent calls return) a singleton instance mapped to the config.accountId property.
 
 */
+ (instancetype _Nonnull )instanceWithConfig:(CJMInstanceConfig * _Nonnull)config;

/*!
 @method
 
 @abstract
 Returns the CJM instance corresponding to the config.accountId param. Use this for multiple instances of the SDK.
 
 @discussion
 Create an instance of CJMInstanceConfig with your CJM Account Id, Token, Region(if any) and other optional config properties.
 Passing that into this method will create (if necessary, and on all subsequent calls return) a singleton instance mapped to the config.accountId property.
 
 */
+ (instancetype _Nonnull)instanceWithConfig:(CJMInstanceConfig * _Nonnull)config andCJMID:(NSString * _Nonnull)CJMID;

/*!
 @method
 
 @abstract
 Set the CJM AccountID and Token
 
 @discussion
 Sets the CJM account credentials.  Once thes default shared instance is intialized subsequent calls will be ignored.
 Only has effect on the default shared instance.
 
 @param accountID  the CJM account id
 @param token      the CJM account token
 
 */
+ (void)changeCredentialsWithAccountID:(NSString * _Nonnull)accountID passcode:(NSString * _Nonnull) passcode andToken:(NSString * _Nonnull)token __attribute__((deprecated("Deprecated as of version 3.1.7, use setCredentialsWithAccountID:andToken instead")));

/*!
 @method
 
 @abstract
 Set the CJM AccountID, Token and Region
 
 @discussion
 Sets the CJM account credentials.  Once the default shared instance is intialized subsequent calls will be ignored.
 Only has effect on the default shared instance.
 
 @param accountID  the CJM account id
 @param token      the CJM account token
 @param region     the dedicated CJM region
 
 */
+ (void)changeCredentialsWithAccountID:(NSString * _Nonnull)accountID token:(NSString * _Nonnull)token passcode:(NSString * _Nonnull) passcode region:(NSString * _Nonnull)region __attribute__((deprecated("Deprecated as of version 3.1.7, use setCredentialsWithAccountID:token:region instead")));

/*!
 @method
 
 @abstract
 Set the CJM AccountID and Token
 
 @discussion
 Sets the CJM account credentials.  Once the default shared instance is intialized subsequent calls will be ignored.
 Only has effect on the default shared instance.
 
 @param accountID  the CJM account id
 @param token      the CJM account token
 
 */
+ (void)setCredentialsWithAccountID:(NSString * _Nonnull)accountID passcode:(NSString * _Nonnull) passcode andToken:(NSString * _Nonnull)token;

/*!
 @method
 
 @abstract
 Set the CJM AccountID, Token and Region
 
 @discussion
 Sets the CJM account credentials.  Once the default shared instance is intialized subsequent calls will be ignored.
 Only has effect on the default shared instance.
 
 @param accountID  the CJM account id
 @param token      the CJM account token
 @param region     the dedicated CJM region
 
 */
+ (void)setCredentialsWithAccountID:(NSString * _Nonnull)accountID token:(NSString * _Nonnull)token passcode:(NSString * _Nonnull) passcode region:(NSString * _Nonnull)region;

/*!
 @method
 
 @abstract
 notify the SDK instance of application launch
 
 */
- (void)notifyApplicationLaunchedWithOptions:launchOptions;

/* ------------------------------------------------------------------------------------------------------
 * User Profile/Action Events/Session API
 */

/*!
 @method
 
 @abstract
 Enables the Profile/Events Read and Synchronization API
 
 @discussion
 Call this method (typically once at app launch) to enable the Profile/Events Read and Synchronization API.
 
 */
+ (void)enablePersonalization;

/*!
 @method
 
 @abstract
 Disables the Profile/Events Read and Synchronization API
 
 */
+ (void)disablePersonalization;

/*!
 @method
 
 @abstract
 Store the users location on the default shared CJM instance.
 
 @discussion
 Optional.  If you're application is collection the user location you can pass it to CJM
 for, among other things, more fine-grained geo-targeting and segmentation purposes.
 
 @param location       CLLocationCoordiate2D
 */
+ (void)setLocation:(CLLocationCoordinate2D)location;

/*!
 @method
 
 @abstract
 Store the users location on a particular CJM SDK instance.
 
 @discussion
 Optional.  If you're application is collection the user location you can pass it to CJM
 for, among other things, more fine-grained geo-targeting and segmentation purposes.
 
 @param location       CLLocationCoordiate2D
 */
- (void)setLocation:(CLLocationCoordinate2D)location;

/*!
 
 @abstract
 Posted when the CJM Geofences are updated.
 
 @discussion
 Useful for accessing the CJM geofences
 
 */
extern NSString * _Nonnull const CJMGeofencesDidUpdateNotification;


/*!
 @method
 
 @abstract
 Get the device location if available.  Calling this will prompt the user location permissions dialog.
 
 Please be sure to include the NSLocationWhenInUseUsageDescription key in your Info.plist.  See https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW26
 
 Uses desired accuracy of kCLLocationAccuracyHundredMeters.
 
 If you need background location updates or finer accuracy please implement your own location handling.  Please see https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/index.html for more info.
 
 @discussion
 Optional.  You can use location to pass it to CJM via the setLocation API
 for, among other things, more fine-grained geo-targeting and segmentation purposes.  To enable, build the SDK with the preprocessor macro CJM_LOCATION.
 */
+ (void)getLocationWithSuccess:(void (^ _Nonnull)(CLLocationCoordinate2D location))success andError:(void (^_Nullable)(NSString * _Nullable reason))error;

/*!
 @method
 
 @abstract
 Creates a separate and distinct user profile identified by one or more of Identity, Email, FBID or GPID values,
 and populated with the key-values included in the properties dictionary.
 
 @discussion
 If your app is used by multiple users, you can use this method to assign them each a unique profile to track them separately.
 
 If instead you wish to assign multiple Identity, Email, FBID and/or GPID values to the same user profile,
 use profilePush rather than this method.
 
 If none of Identity, Email, FBID or GPID is included in the properties dictionary,
 all properties values will be associated with the current user profile.
 
 When initially installed on this device, your app is assigned an "anonymous" profile.
 The first time you identify a user on this device (whether via onUserLogin or profilePush),
 the "anonymous" history on the device will be associated with the newly identified user.
 
 Then, use this method to switch between subsequent separate identified users.
 
 Please note that switching from one identified user to another is a costly operation
 in that the current session for the previous user is automatically closed
 and data relating to the old user removed, and a new session is started
 for the new user and data for that user refreshed via a network call to CJM.
 In addition, any global frequency caps are reset as part of the switch.
 
 @param identity       properties String
 
 */
- (void)setIdentity:(NSString * _Nonnull)identity;

/*!
 @method
 
 @abstract
 Creates a separate and distinct user profile identified by one or more of Identity, Email, FBID or GPID values,
 and populated with the key-values included in the properties dictionary.
 
 @discussion
 If your app is used by multiple users, you can use this method to assign them each a unique profile to track them separately.
 
 If instead you wish to assign multiple Identity, Email, FBID and/or GPID values to the same user profile,
 use profilePush rather than this method.
 
 If none of Identity, Email, FBID or GPID is included in the properties dictionary,
 all properties values will be associated with the current user profile.
 
 When initially installed on this device, your app is assigned an "anonymous" profile.
 The first time you identify a user on this device (whether via onUserLogin or profilePush),
 the "anonymous" history on the device will be associated with the newly identified user.
 
 Then, use this method to switch between subsequent separate identified users.
 
 Please note that switching from one identified user to another is a costly operation
 in that the current session for the previous user is automatically closed
 and data relating to the old user removed, and a new session is started
 for the new user and data for that user refreshed via a network call to CJM.
 In addition, any global frequency caps are reset as part of the switch.
 
 @param properties       properties dictionary
 
 */
- (void)onUserLogin:(NSDictionary *_Nonnull)properties;


/*!
 @method
 
 @abstract
 Creates a separate and distinct user profile identified by one or more of Identity, Email, FBID or GPID values,
 and populated with the key-values included in the properties dictionary.
 
 @discussion
 If your app is used by multiple users, you can use this method to assign them each a unique profile to track them separately.
 
 If instead you wish to assign multiple Identity, Email, FBID and/or GPID values to the same user profile,
 use profilePush rather than this method.
 
 If none of Identity, Email, FBID or GPID is included in the properties dictionary,
 all properties values will be associated with the current user profile.
 
 When initially installed on this device, your app is assigned an "anonymous" profile.
 The first time you identify a user on this device (whether via onUserLogin or profilePush),
 the "anonymous" history on the device will be associated with the newly identified user.
 
 Then, use this method to switch between subsequent separate identified users.
 
 Please note that switching from one identified user to another is a costly operation
 in that the current session for the previous user is automatically closed
 and data relating to the old user removed, and a new session is started
 for the new user and data for that user refreshed via a network call to CJM.
 In addition, any global frequency caps are reset as part of the switch.
 
 CJMUseCustomId key should be set to YES in apps info.plist to enable support for setting custom CJMID.
 
 @param properties       properties dictionary
 @param CJMID        the CJM id
 
 */
- (void)onUserLogin:(NSDictionary *_Nonnull)properties withCJMID:(NSString * _Nonnull)CJMID;

/*!
 @method
 
 @abstract
 Enables tracking opt out for the currently active user.
 
 @discussion
 Use this method to opt the current user out of all event/profile tracking.
 You must call this method separately for each active user profile (e.g. when switching user profiles using onUserLogin).
 Once enabled, no events will be saved remotely or locally for the current user. To re-enable tracking call this method with enabled set to NO.
 
 @param enabled         BOOL Whether tracking opt out should be enabled/disabled.
 */
- (void)setOptOut:(BOOL)enabled;

/*!
 @method
 
 @abstract
 Disables/Enables sending events to the server.
 
 @discussion
 If you want to stop recorded events from being sent to the server, use this method to set the SDK instance to offline. Once offline, events will be recorded and queued locally but will not be sent to the server until offline is disabled. Calling this method again with offline set to NO will allow events to be sent to server and the SDK instance will immediately attempt to send events that have been queued while offline.
 
 @param offline         BOOL Whether sending events to servers should be disabled(TRUE)/enabled(FALSE).
 */
- (void)setOffline:(BOOL)offline;

/*!
 @method
 
 @abstract
 Enables the reporting of device network-related information, including IP address.  This reporting is disabled by default.
 
 @discussion
 Use this method to enable device network-related information tracking, including IP address.
 This reporting is disabled by default.  To re-disable tracking call this method with enabled set to NO.
 
 @param enabled         BOOL Whether device network info reporting should be enabled/disabled.
 */
- (void)enableDeviceNetworkInfoReporting:(BOOL)enabled;

#pragma mark Profile API

/*!
 @method
 
 @abstract
 Set properties on the current user profile.
 
 @discussion
 Property keys must be NSString and values must be one of NSString, NSNumber, BOOL, NSDate.
 
 To add a multi-value (array) property value type please use profileAddValueToSet: forKey:
 
 @param properties       properties dictionary
 */
- (void)profilePush:(NSDictionary *_Nonnull)properties;

/*!
 @method
 
 @abstract
 Remove the property specified by key from the user profile.
 
 @param key       key string
 
 */
- (void)profileRemoveValueForKey:(NSString *_Nonnull)key;

/*!
 @method
 
 @abstract
 Method for setting a multi-value user profile property.
 
 Any existing value(s) for the key will be overwritten.
 
 @discussion
 Key must be NSString.
 Values must be NSStrings.
 Max 100 values, on reaching 100 cap, oldest value(s) will be removed.
 
 
 @param key       key string
 @param values    values NSArray<NSString *>
 
 */
- (void)profileSetMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nonnull)key;

/*!
 @method
 
 @abstract
 Method for adding a unique value to a multi-value profile property (or creating if not already existing).
 
 If the key currently contains a scalar value, the key will be promoted to a multi-value property
 with the current value cast to a string and the new value(s) added
 
 @discussion
 Key must be NSString.
 Values must be NSStrings.
 Max 100 values, on reaching 100 cap, oldest value(s) will be removed.
 
 
 @param key       key string
 @param value     value string
 */
- (void)profileAddMultiValue:(NSString * _Nonnull)value forKey:(NSString *_Nonnull)key;

/*!
 @method
 
 @abstract
 Method for adding multiple unique values to a multi-value profile property (or creating if not already existing).
 
 If the key currently contains a scalar value, the key will be promoted to a multi-value property
 with the current value cast to a string and the new value(s) added.
 
 @discussion
 Key must be NSString.
 Values must be NSStrings.
 Max 100 values, on reaching 100 cap, oldest value(s) will be removed.
 
 
 @param key       key string
 @param values    values NSArray<NSString *>
 */
- (void)profileAddMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nonnull)key;

/*!
 @method
 
 @abstract
 Method for removing a unique value from a multi-value profile property.
 
 If the key currently contains a scalar value, prior to performing the remove operation the key will be promoted to a multi-value property with the current value cast to a string.
 
 If the multi-value property is empty after the remove operation, the key will be removed.
 
 @param key       key string
 @param value     value string
 */
- (void)profileRemoveMultiValue:(NSString *_Nonnull)value forKey:(NSString *_Nonnull)key;

/*!
 @method
 
 @abstract
 Method for removing multiple unique values from a multi-value profile property.
 
 If the key currently contains a scalar value, prior to performing the remove operation the key will be promoted to a multi-value property with the current value cast to a string.
 
 If the multi-value property is empty after the remove operation, the key will be removed.
 
 @param key       key string
 @param values    values NSArray<NSString *>
 */
- (void)profileRemoveMultiValues:(NSArray<NSString *> * _Nonnull)values forKey:(NSString * _Nonnull)key;

/*!
 @method
 
 @abstract
 Convenience method to set the Facebook Graph User properties on the user profile.
 
 @discussion
 If you support social login via FB connect in your app and are using the Facebook library in your app,
 you can push a GraphUser object of the user.
 Be sure that you’re sending a GraphUser object of the currently logged in user.
 
 @param fbGraphUser       fbGraphUser Facebook Graph User object
 
 */
- (void)profilePushGraphUser:(id _Nonnull)fbGraphUser;

/*!
 @method
 
 @abstract
 Convenience method to set the Google Plus User properties on the user profile.
 
 @discussion
 If you support social login via Google Plus in your app and are using the Google Plus library in your app,
 you can set a GTLPlusPerson object on the user profile, after a successful login.
 
 @param googleUser       GTLPlusPerson object
 
 */
- (void)profilePushGooglePlusUser:(id _Nonnull )googleUser;

/*!
 @method
 
 @abstract
 Get a user profile property.
 
 @discussion
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 If the property is not available or enablePersonalization has not been called, this call will return nil.
 
 @param propertyName          property name
 
 @return
 returns NSArray in the case of a multi-value property
 
 */
- (id _Nullable )profileGet:(NSString *_Nonnull)propertyName;

/*!
 @method
 
 @abstract
 Get the CJM ID of the User Profile.
 
 @discussion
 The CJM ID is the unique identifier assigned to the User Profile by CJM.
 
 */
- (NSString *_Nullable)profileGetCJMID;

/*!
 @method
 
 @abstract
 Returns a unique CJM identifier suitable for use with install attribution providers.
 
 */
- (NSString *_Nullable)profileGetCJMAttributionIdentifier;

#pragma mark User Action Events API

/*!
 @method
 
 @abstract
 Record an event.
 
 Reserved event names: "Stayed", "Notification Clicked", "Notification Viewed", "UTM Visited", "Notification Sent", "App Launched", "wzrk_d", are prohibited.
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 @param event           event name
 */
- (void)recordEvent:(NSString *_Nonnull)event;

/*!
 @method
 
 @abstract
 Records an event with properties.
 
 @discussion
 Property keys must be NSString and values must be one of NSString, NSNumber, BOOL or NSDate.
 Reserved event names: "Stayed", "Notification Clicked", "Notification Viewed", "UTM Visited", "Notification Sent", "App Launched", "wzrk_d", are prohibited.
 Keys are limited to 32 characters.
 Values are limited to 40 bytes.
 Longer will be truncated.
 Maximum number of event properties is 16.
 
 @param event           event name
 @param properties      properties dictionary
 */
- (void)recordEvent:(NSString *_Nonnull)event withProps:(NSDictionary *_Nonnull)properties;

/*!
 @method
 
 @abstract
 Records the special Charged event with properties.
 
 @discussion
 Charged is a special event in CJM. It should be used to track transactions or purchases.
 Recording the Charged event can help you analyze how your customers are using your app, or even to reach out to loyal or lost customers.
 The transaction total or subscription charge should be recorded in an event property called “Amount” in the chargeDetails param.
 Set your transaction ID or the receipt ID as the value of the "Charged ID" property of the chargeDetails param.
 
 You can send an array of purchased item dictionaries via the items param.
 
 Property keys must be NSString and values must be one of NSString, NSNumber, BOOL or NSDATE.
 Keys are limited to 32 characters.
 Values are limited to 40 bytes.
 Longer will be truncated.
 
 @param chargeDetails   charge transaction details dictionary
 @param items           charged items array
 */
- (void)recordChargedEventWithDetails:(NSDictionary *_Nonnull)chargeDetails andItems:(NSArray *_Nonnull)items;

/*!
 @method
 
 @abstract
 Record an error event.
 
 @param message           error message
 @param code              int error code
 */

- (void)recordErrorWithMessage:(NSString *_Nonnull)message andErrorCode:(int)code;

/*!
 @method
 
 @abstract
 Record a screen view.
 
 @param screenName           the screen name
 */
- (void)recordScreenView:(NSString *_Nonnull)screenName;

/*!
 @method
 
 @abstract
 Record Notification Viewed for Push Notifications.
 
 @param notificationData       notificationData id
 */
- (void)recordNotificationViewedEventWithData:(id _Nonnull)notificationData;

/*!
 @method
 
 @abstract
 Record Notification Clicked for Push Notifications.
 
 @param notificationData       notificationData id
 */
- (void)recordNotificationClickedEventWithData:(id _Nonnull)notificationData;

/*!
 @method
 
 @abstract
 Get the time of the first recording of the event.
 
 Be sure to call enablePersonalization prior to invoking this method.
 
 @param event           event name
 */
- (NSTimeInterval)eventGetFirstTime:(NSString *_Nonnull)event;

/*!
 @method
 
 @abstract
 Get the time of the last recording of the event.
 Be sure to call enablePersonalization prior to invoking this method.
 
 @param event           event name
 */

- (NSTimeInterval)eventGetLastTime:(NSString *_Nonnull)event;

/*!
 @method
 
 @abstract
 Get the number of occurrences of the event.
 Be sure to call enablePersonalization prior to invoking this method.
 
 @param event           event name
 */
- (int)eventGetOccurrences:(NSString *_Nonnull)event;

/*!
 @method
 
 @abstract
 Get the user's event history.
 
 @discussion
 Returns a dictionary of CJMEventDetail objects (eventName, firstTime, lastTime, occurrences), keyed by eventName.
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 */
- (NSDictionary *_Nullable)userGetEventHistory;

/*!
 @method
 
 @abstract
 Get the details for the event.
 
 @discussion
 Returns a CJMEventDetail object (eventName, firstTime, lastTime, occurrences)
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 @param event           event name
 */
- (CJMEventDetail *_Nullable)eventGetDetail:(NSString *_Nullable)event;


#pragma mark Session API

- (NSDictionary *_Nullable)getARP;
/*!
 @method
 
 @abstract
 Get the elapsed time of the current user session.
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 */
- (NSTimeInterval)sessionGetTimeElapsed;

/*!
 @method
 
 @abstract
 Get the utm referrer details for this user session.
 
 @discussion
 Returns a CJMUTMDetail object (source, medium and campaign).
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 */
- (CJMUTMDetail *_Nullable)sessionGetUTMDetails;

/*!
 @method
 
 @abstract
 Get the total number of visits by this user.
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 */
- (int)userGetTotalVisits;

/*!
 @method
 
 @abstract
 Get the total screens viewed by this user.
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 */
- (int)userGetScreenCount;

/*!
 @method
 
 @abstract
 Get the last prior visit time for this user.
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 */
- (NSTimeInterval)userGetPreviousVisitTime;

/* ------------------------------------------------------------------------------------------------------
 * Synchronization
 */


/*!
 @abstract
 Posted when the CJM User Profile/Event History has changed in response to a synchronization call to the CJM servers.
 
 @discussion
 CJM provides a flexible notification system for informing applications when changes have occured
 to the CJM User Profile/Event History in response to synchronization activities.
 
 CJM leverages the NSNotification broadcast mechanism to notify your application when changes occur.
 Your application should observe CJMProfileDidChangeNotification in order to receive notifications.
 
 Be sure to call enablePersonalization (typically once at app launch) to enable synchronization.
 
 Change data will be returned in the userInfo property of the NSNotification, and is of the form:
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
extern NSString * _Nonnull const CJMProfileDidChangeNotification;

/*!
 
 @abstract
 Posted when the CJM User Profile is initialized.
 
 @discussion
 Useful for accessing the CJM ID of the User Profile.
 
 The CJM ID is the unique identifier assigned to the User Profile by CJM.
 
 The CJM ID and cooresponding CJMAccountID will be returned in the userInfo property of the NSNotifcation in the form: {@"CJMID":CJMID, @"CJMAccountID":CJMAccountID}.
 
 */
extern NSString * _Nonnull const CJMProfileDidInitializeNotification;


/*!
 
 @method
 
 @abstract
 The `CJMSyncDelegate` protocol provides additional/alternative methods for notifying
 your application (the adopting delegate) about synchronization-related changes to the User Profile/Event History.
 
 @see CJMSyncDelegate.h
 
 @discussion
 This sets the CJMSyncDelegate.
 
 Be sure to call enablePersonalization (typically once at app launch) to enable synchronization.
 
 @param delegate     an object conforming to the CJMSyncDelegate Protocol
 */
- (void)setSyncDelegate:(id <CJMSyncDelegate> _Nullable)delegate;


/*!

@method

@abstract
The `CJMPushNotificationDelegate` protocol provides methods for notifying
your application (the adopting delegate) about push notifications.

@see CJMPushNotificationDelegate.h

@discussion
This sets the CJMPushNotificationDelegate.

@param delegate     an object conforming to the CJMPushNotificationDelegate Protocol
*/

- (void)setPushNotificationDelegate:(id <CJMPushNotificationDelegate> _Nullable)delegate;

#if !CJM_NO_INAPP_SUPPORT
/*!
 
 @method
 
 @abstract
 The `CJMInAppNotificationDelegate` protocol provides methods for notifying
 your application (the adopting delegate) about in-app notifications.
 
 @see CJMInAppNotificationDelegate.h
 
 @discussion
 This sets the CJMInAppNotificationDelegate.
 
 @param delegate     an object conforming to the CJMInAppNotificationDelegate Protocol
 */
- (void)setInAppNotificationDelegate:(id <CJMInAppNotificationDelegate> _Nullable)delegate;
#endif

/* ------------------------------------------------------------------------------------------------------
 * Notifications
 */

/*!
 @method
 
 @abstract
 Register the device to receive push notifications.
 
 @discussion
 This will associate the device token with the current user to allow push notifications to the user.
 
 @param pushToken     device token as returned from application:didRegisterForRemoteNotificationsWithDeviceToken:
 */
- (void)setPushToken:(NSData *_Nonnull)pushToken;

/*!
 @method
 
 @abstract
 Convenience method to register the device push token as as string.
 
 @discussion
 This will associate the device token with the current user to allow push notifications to the user.
 
 @param pushTokenString     device token as returned from application:didRegisterForRemoteNotificationsWithDeviceToken: converted to an NSString.
 */
- (void)setPushTokenAsString:(NSString *_Nonnull)pushTokenString;

/*!
 @method
 
 @abstract
 Track and process a push notification based on its payload.
 
 @discussion
 By calling this method, CJM will automatically track user notification interaction for you.
 If the push notification contains a deep link, CJM will handle the call to application:openUrl: with the deep link, as long as the application is not in the foreground.
 
 @param data         notification payload
 */
- (void)handleNotificationWithData:(id _Nonnull )data;

/*!
 @method
 
 @abstract
 Track and process a push notification based on its payload.
 
 @discussion
 By calling this method, CJM will automatically track user notification interaction for you.
 If the push notification contains a deep link, CJM will handle the call to application:openUrl: with the deep link, as long as the application is not in the foreground or you pass TRUE in the openInForeground param.
 
 @param data                     notification payload
 @param openInForeground         Boolean as to whether the SDK should open any deep link attached to the notification while the application is in the foreground.
 */
- (void)handleNotificationWithData:(id _Nonnull )data openDeepLinksInForeground:(BOOL)openInForeground;

/*!
 @method
 
 @abstract
 Convenience method when using multiple SDK instances to track and process a push notification based on its payload.
 
 @discussion
 By calling this method, CJM will automatically track user notification interaction for you; the specific instance of the CJM SDK to process the call is determined based on the CJM AccountID included in the notification payload and, if not present, will default to the shared instance.
 
 If the push notification contains a deep link, CJM will handle the call to application:openUrl: with the deep link, as long as the application is not in the foreground or you pass TRUE in the openInForeground param.
 
 @param notification             notification payload
 @param openInForeground         Boolean as to whether the SDK should open any deep link attached to the notification while the application is in the foreground.
 */
+ (void)handlePushNotification:(NSDictionary*_Nonnull)notification openDeepLinksInForeground:(BOOL)openInForeground;

/*!
 @method
 
 @abstract
 Determine whether a notification originated from CJM
 
 @param payload  notification payload
 */
- (BOOL)isCJMNotification:(NSDictionary *_Nonnull)payload;

#if !CJM_NO_INAPP_SUPPORT
/*!
 @method
 
 @abstract
 Manually initiate the display of any pending in app notifications.
 
 */
- (void)showInAppNotificationIfAny;

#endif

/* ------------------------------------------------------------------------------------------------------
 * Referrer tracking
 */

/*!
 @method
 
 @abstract
 Track incoming referrers on a specific SDK instance.
 
 @discussion
 By calling this method, the specific CJM instance will automatically track incoming referrer utm details.
 When implementing multiple SDK instances, consider using +handleOpenURL: instead.
 
 
 @param url                     the incoming NSURL
 @param sourceApplication       the source application
 */
- (void)handleOpenURL:(NSURL *_Nonnull)url sourceApplication:(NSString *_Nullable)sourceApplication;

/*!
 @method
 
 @abstract
 Convenience method to track incoming referrers when using multile SDK instances.
 
 @discussion
 By calling this method, if the url contains a query parameter with a CJM AccountID, the SDK will pass the URL to that specific instance for processing.
 If no CJM AccountID param is present, the SDK will default to passing the URL to the shared instance.
 
 @param url                     the incoming NSURL
 */
+ (void)handleOpenURL:(NSURL*_Nonnull)url;


/*!
 @method
 
 @abstract
 Manually track incoming referrers.
 
 @discussion
 Call this to manually track the utm details for an incoming install referrer.
 
 
 @param source                   the utm source
 @param medium                   the utm medium
 @param campaign                 the utm campaign
 */
- (void)pushInstallReferrerSource:(NSString *_Nullable)source
                           medium:(NSString *_Nullable)medium
                         campaign:(NSString *_Nullable)campaign;

/* ------------------------------------------------------------------------------------------------------
 * Admin
 */

/*!
 @method
 
 @abstract
 Set the debug logging level
 
 @discussion
 Set using CJMLogLevel enum values (or the corresponding int values).
 SDK logging defaults to CJMLogInfo, which prints minimal SDK integration-related messages
 
 CJMLogOff - turns off all SDK logging.
 CJMLogInfo - default, prints minimal SDK integration related messages.
 CJMLogDebug - enables verbose debug logging.
 In Swift, use the respective rawValues:  CJMLogLevel.off.rawValue, CJMLogLevel.info.rawValue,
 CJMLogLevel.debug.rawValue.
 
 @param level  the level to set
 */
+ (void)setDebugLevel:(int)level;

/*!
 @method
 
 @abstract
 Get the debug logging level
 
 @discussion
 Returns the currently set debug logging level.
 */
+ (CJMLogLevel)getDebugLevel;

/*!
@method

@abstract
Set the Library name for Auxiliary SDKs

@discussion
Call this to method to set library name in the Auxiliary SDK
*/
- (void)setLibrary:(NSString * _Nonnull)name;

/*!
 @method
 
 @abstract
 Store the users location for geofences on the default shared CJM instance.
 
 @discussion
 Optional.  If you're application is collection the user location you can pass it to CJM
 for, among other things, more fine-grained geo-targeting and segmentation purposes.
 
 @param location       CLLocationCoordiate2D
 */
- (void)setLocationForGeofences:(CLLocationCoordinate2D)location withPluginVersion:(NSString *_Nullable)version;

/*!
 @method
 
 @abstract
 Record the error for geofences
 
 @param error       NSError
 */
- (void)didFailToRegisterForGeofencesWithError:(NSError *_Nullable)error;

/*!
 @method
 
 @abstract
 Record Geofence Entered Event.
 
 @param geofenceDetails      details of the Geofence
 */
- (void)recordGeofenceEnteredEvent:(NSDictionary *_Nonnull)geofenceDetails;

/*!
 @method
 
 @abstract
 Record Geofence Exited Event.
 
 @param geofenceDetails       details of the Geofence
 */
- (void)recordGeofenceExitedEvent:(NSDictionary *_Nonnull)geofenceDetails;

#if defined(CJM_HOST_WATCHOS)
/** HostWatchOS
 */
- (BOOL)handleMessage:(NSDictionary<NSString *, id> *)message forWatchSession:(WCSession *)session API_AVAILABLE(ios(9.0));
#endif

//- (void)login;

@end

#pragma clang diagnostic pop
