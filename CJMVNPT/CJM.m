
#import "CJM.h"
#import "CJMUtils.h"
#import "CJMLogger.h"
#import "CJMSwizzle.h"
#import "CJMConstants.h"
#import "CJMPlistInfo.h"
#import "CJMValidator.h"
#import "CJMUriHelper.h"
#import "CJMInAppUtils.h"
#import "CJMDeviceInfo.h"
#import "CJMPreferences.h"
#import "CJMEventBuilder.h"
#import "CJMProfileBuilder.h"
#import "CJMLocalDataStore.h"
#import "CJMUTMDetail.h"
#import "CJMEventDetail.h"
#import "CJMSyncDelegate.h"
#import "CJMInstanceConfig.h"
#import "CJMInstanceConfigPrivate.h"
#import "CJMPushNotificationDelegate.h"
#import "CJMInAppNotificationDelegate.h"
#import "CJMValidationResult.h"
#import "CJMInAppFCManager.h"
#import "CJMInAppNotification.h"
#import "CJMInAppDisplayViewController.h"

#if !CJM_NO_INAPP_SUPPORT
#import "CJMJSInterface.h"
#import "CJMInAppHTMLViewController.h"
#import "CJMInterstitialViewController.h"
#import "CJMHalfInterstitialViewController.h"
#import "CJMCoverViewController.h"
#import "CJMHeaderViewController.h"
#import "CJMFooterViewController.h"
#import "CJMAlertViewController.h"
#import "CJMCoverImageViewController.h"
#import "CJMInterstitialImageViewController.h"
#import "CJMHalfInterstitialImageViewController.h"
#endif

#import "CJMLocationManager.h"

#if !CJM_NO_INBOX_SUPPORT
#import "CJMInboxController.h"
#import "CJM+Inbox.h"
#import "CJMInboxViewControllerPrivate.h"
#endif

//#if CJM_SSL_PINNING
#import "CJMPinnedNSURLSessionDelegate.h"
static NSArray *sslCertNames;
//#endif

#if !CJM_NO_AB_SUPPORT
#import "CJMABTestController.h"
#import "CJM+ABTesting.h"
#import "CJMABVariant.h"
#endif

#if !CJM_NO_DISPLAY_UNIT_SUPPORT
#import "CJMDisplayUnitController.h"
#import "CJM+DisplayUnit.h"
#endif

#import "CJM+FeatureFlags.h"
#import "CJMFeatureFlagsPrivate.h"
#import "CJMFeatureFlagsController.h"

#import "CJM+ProductConfig.h"
#import "CJMProductConfigPrivate.h"
#import "CJMProductConfigController.h"

#import "CJMManager.h"
#import "CJMAESCrypt.h"

#import <objc/runtime.h>

static const void *const kQueueKey = &kQueueKey;
static const void *const kNotificationQueueKey = &kNotificationQueueKey;

static const int kMaxBatchSize = 49;
NSString *const kQUEUE_NAME_PROFILE = @"net_queue_profile";
NSString *const kQUEUE_NAME_EVENTS = @"events";
NSString *const kQUEUE_NAME_NOTIFICATIONS = @"notifications";

NSString *const kHANDSHAKE_URL = @"https://wzrkt.com/hello";

NSString *const kREDIRECT_DOMAIN_KEY = @"CLTAP_REDIRECT_DOMAIN_KEY";
NSString *const kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY = @"CLTAP_REDIRECT_NOTIF_VIEWED_DOMAIN_KEY";
NSString *const kMUTED_TS_KEY = @"CLTAP_MUTED_TS_KEY";

NSString *const kREDIRECT_HEADER = @"X-WZRK-RD";
NSString *const kREDIRECT_NOTIF_VIEWED_HEADER = @"X-WZRK-SPIKY-RD";
NSString *const kMUTE_HEADER = @"X-WZRK-MUTE";

NSString *const kACCOUNT_ID_HEADER = @"X-CleverTap-Account-Id";
NSString *const kACCOUNT_TOKEN_HEADER = @"X-CleverTap-Token";

NSString *const kI_KEY = @"CLTAP_I_KEY";
NSString *const kJ_KEY = @"CLTAP_J_KEY";

NSString *const kFIRST_TS_KEY = @"CLTAP_FIRST_TS_KEY";
NSString *const kLAST_TS_KEY = @"CLTAP_LAST_TS_KEY";

NSString *const kMultiUserPrefix = @"mt_";

NSString *const kNetworkInfoReportingKey = @"NetworkInfo";

NSString *const kLastSessionPing = @"last_session_ping";
NSString *const kLastSessionTime = @"lastSessionTime";
NSString *const kSessionId = @"sessionId";

NSString *const kWR_KEY_PERSONALISATION_ENABLED = @"boolPersonalisationEnabled";
NSString *const kWR_KEY_AB_TEST_EDITOR_ENABLED = @"boolABTestEditorEnabled";
NSString *const CJMProfileDidInitializeNotification = CLTAP_PROFILE_DID_INITIALIZE_NOTIFICATION;
NSString *const CJMProfileDidChangeNotification = CLTAP_PROFILE_DID_CHANGE_NOTIFICATION;
NSString *const CJMGeofencesDidUpdateNotification = CLTAP_GEOFENCES_DID_UPDATE_NOTIFICATION;

NSString *const kCachedGUIDS = @"CachedGUIDS";
NSString *const kOnUserLoginAction = @"onUserLogin";
NSString *const kInstanceWithCJMIDAction = @"instanceWithCleverTapID";

static int currentRequestTimestamp = 0;
static int initialAppEnteredForegroundTime = 0;
static BOOL isAutoIntegrated;

typedef NS_ENUM(NSInteger, CJMEventType) {
    CJMEventTypePage,
    CJMEventTypePing,
    CJMEventTypeProfile,
    CJMEventTypeRaised,
    CJMEventTypeData,
    CJMEventTypeNotificationViewed,
    CJMEventTypeFetch,
};

typedef NS_ENUM(NSInteger, CJMPushTokenRegistrationAction) {
    CJMPushTokenRegister,
    CJMPushTokenUnregister,
};

#if !CJM_NO_INBOX_SUPPORT
@interface CJMInboxMessage ()
- (instancetype) init __unavailable;
- (instancetype)initWithJSON:(NSDictionary *)json;
@end
#endif

#if !CJM_NO_INBOX_SUPPORT
@interface CJM () <CJMInboxDelegate, CJMInboxViewControllerAnalyticsDelegate> {}
@property(atomic, strong) CJMInboxController *inboxController;
@property(nonatomic, strong) NSMutableArray<CJMInboxUpdatedBlock> *inboxUpdateBlocks;
@end
#endif

#if !CJM_NO_AB_SUPPORT
@interface CJM () <CJMABTestingDelegate> {}
@property (nonatomic, strong) CJMABTestController *abTestController;
@property (nonatomic, strong) NSMutableArray<CJMExperimentsUpdatedBlock> *experimentsUpdateBlocks;

@end
#endif

@interface CJM () <CJMInAppNotificationDisplayDelegate> {}
//#if CJM_SSL_PINNING
@property(nonatomic, strong) CJMPinnedNSURLSessionDelegate *urlSessionDelegate;
//#endif
@end

#if !CJM_NO_DISPLAY_UNIT_SUPPORT
@interface CJM () <CJMDisplayUnitDelegate> {}
@property (nonatomic, strong) CJMDisplayUnitController *displayUnitController;
@property (atomic, weak) id <CleverTapDisplayUnitDelegate> displayUnitDelegate;
@end
#endif

@interface CJM () <CJMFeatureFlagsDelegate, CJMPrivateFeatureFlagsDelegate> {}
@property (atomic, strong) CJMFeatureFlagsController *featureFlagsController;
@property (atomic, strong, readwrite, nonnull) CJMFeatureFlags *featureFlags;

@end

@interface CJM () <CJMProductConfigDelegate, CJMPrivateProductConfigDelegate> {}
@property (atomic, strong) CJMProductConfigController *productConfigController;
@property (atomic, strong, readwrite, nonnull) CJMProductConfig *productConfig;

@end

#import <UserNotifications/UserNotifications.h>

@interface CJM () <UIApplicationDelegate> {
    dispatch_queue_t _serialQueue;
    dispatch_queue_t _notificationQueue;
}

@property (nonatomic, strong, readwrite) CJMInstanceConfig *config;
@property (nonatomic, assign) NSTimeInterval lastAppLaunchedTime;
@property (nonatomic, strong) CJMDeviceInfo *deviceInfo;
@property (nonatomic, strong) CJMLocalDataStore *localDataStore;
@property (nonatomic, strong) CJMInAppFCManager *inAppFCManager;
@property (nonatomic, assign) BOOL isAppForeground;

@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) NSMutableArray *profileQueue;
@property (nonatomic, strong) NSMutableArray *notificationsQueue;
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSString *redirectDomain;
@property (nonatomic, strong) NSString *explictEndpointDomain;
@property (nonatomic, strong) NSString *redirectNotifViewedDomain;
@property (nonatomic, strong) NSString *explictNotifViewedEndpointDomain;
@property (nonatomic, assign) NSTimeInterval lastMutedTs;
@property (nonatomic, assign) int sendQueueFails;

@property (nonatomic, assign) BOOL pushedAPNSId;
@property (atomic, assign) BOOL currentUserOptedOut;
@property (atomic, assign) BOOL offline;
@property (atomic, assign) BOOL enableNetworkInfoReporting;
@property (atomic, assign) BOOL appLaunchProcessed;
@property (atomic, assign) BOOL initialEventsPushed;
@property (atomic, assign) CLLocationCoordinate2D userSetLocation;
@property (nonatomic, assign) double lastLocationPingTime;

@property (nonatomic, assign) long minSessionSeconds;
@property (atomic, assign) long sessionId;
@property (atomic, assign) int screenCount;
@property (atomic, assign) BOOL firstSession;
@property (atomic, assign) BOOL firstRequestInSession;
@property (atomic, assign) int lastSessionLengthSeconds;

@property (atomic, retain) NSString *source;
@property (atomic, retain) NSString *medium;
@property (atomic, retain) NSString *campaign;
@property (atomic, retain) NSDictionary *wzrkParams;
@property (atomic, retain) NSDictionary *lastUTMFields;
@property (atomic, strong) NSString *currentViewControllerName;
@property (atomic, retain) FIRAnalytics *firAnalytics;

@property (atomic, strong) NSMutableArray<CJMValidationResult *> *pendingValidationResults;

@property (atomic, weak) id <CJMSyncDelegate> syncDelegate;
@property (atomic, weak) id <CJMPushNotificationDelegate> pushNotificationDelegate;
@property (atomic, weak) id <CJMInAppNotificationDelegate> inAppNotificationDelegate;

@property (atomic, strong) NSString *processingLoginUserIdentifier;

@property (nonatomic, assign, readonly) BOOL sslPinningEnabled;

@property (atomic, assign) BOOL geofenceLocation;
@property (nonatomic, strong) NSString *gfSDKVersion;

- (instancetype)init __unavailable;

@end

@implementation CJM

@synthesize sessionId=_sessionId;
@synthesize source=_source;
@synthesize medium=_medium;
@synthesize campaign=_campaign;
@synthesize wzrkParams=_wzrkParams;
@synthesize syncDelegate=_syncDelegate;
@synthesize pushNotificationDelegate=_pushNotificationDelegate;
@synthesize inAppNotificationDelegate=_inAppNotificationDelegate;
@synthesize userSetLocation=_userSetLocation;
@synthesize offline=_offline;
@synthesize firstRequestInSession=_firstRequestInSession;
@synthesize geofenceLocation=_geofenceLocation;

#if !CJM_NO_DISPLAY_UNIT_SUPPORT
@synthesize displayUnitDelegate=_displayUnitDelegate;
#endif

@synthesize featureFlagsDelegate=_featureFlagsDelegate;

@synthesize productConfigDelegate=_productConfigDelegate;

static CJMPlistInfo *_plistInfo;
static NSMutableDictionary<NSString*, CJM*> *_instances;
static CJMInstanceConfig *_defaultInstanceConfig;
static BOOL sharedInstanceErrorLogged;
static CLLocationCoordinate2D emptyLocation = {-1000.0, -1000.0}; // custom empty definition; will fail the CLLocationCoordinate2DIsValid test

// static here as we may have multiple instances handling inapps
static CJMInAppDisplayViewController *currentDisplayController;
static NSMutableArray<CJMInAppDisplayViewController*> *pendingNotificationControllers;


#pragma mark - Lifecycle

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidFinishLaunchingNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instances = [NSMutableDictionary new];
        _plistInfo = [CJMPlistInfo sharedInstance];
        pendingNotificationControllers = [NSMutableArray new];
//#if CJM_SSL_PINNING
        // Only pin anchor/CA certificates
        sslCertNames = @[@"DigiCertGlobalRootCA", @"DigiCertSHA2SecureServerCA"];
//#endif
    });
}

+ (void)onDidFinishLaunchingNotification:(NSNotification *)notification {
    if (initialAppEnteredForegroundTime <= 0) {
        initialAppEnteredForegroundTime = (int) [[[NSDate alloc] init] timeIntervalSince1970];
    }
    NSDictionary *launchOptions = notification.userInfo;
    if (!_instances || [_instances count] <= 0) {
        [[self sharedInstance] notifyApplicationLaunchedWithOptions:launchOptions];
        return;
    }
    for (CJM *instance in [_instances allValues]) {
        [instance notifyApplicationLaunchedWithOptions:launchOptions];
    }
}

+ (nullable instancetype)autoIntegrate {
    return [self _autoIntegrateWithCJMID:nil];
}

+ (nullable instancetype)autoIntegrateWithCJMID:(NSString *)CJMID {
    return [self _autoIntegrateWithCJMID:CJMID];
}

+ (nullable instancetype)_autoIntegrateWithCJMID:(NSString *)CJMID {
    CJMLogStaticInfo("%@: Auto Integration enabled", self);
    isAutoIntegrated = YES;
    [self swizzleAppDelegate];
    CJM *instance = CJMID ? [CJM sharedInstanceWithCJMID:CJMID] : [CJM sharedInstance];
    return instance;
}

+ (void)swizzleAppDelegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIApplication *sharedApplication = [self getSharedApplication];
        if (sharedApplication == nil) {
            return;
        }
        
        __strong id appDelegate = [sharedApplication delegate];
        Class cls = [sharedApplication.delegate class];
        SEL sel;
        
        // Token Handling
        sel = NSSelectorFromString(@"application:didFailToRegisterForRemoteNotificationsWithError:");
        if (!class_getInstanceMethod(cls, sel)) {
            SEL newSel = @selector(CJM_application:didFailToRegisterForRemoteNotificationsWithError:);
            Method newMeth = class_getClassMethod([self class], newSel);
            IMP imp = method_getImplementation(newMeth);
            const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
            class_addMethod(cls, sel, imp, methodTypeEncoding);
        } else {
            __block NSInvocation *invocation = nil;
            invocation = [cls CJM_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSError *error) {
                [self CJM_application:application didFailToRegisterForRemoteNotificationsWithError:error];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&error atIndex:3];
                [invocation invokeWithTarget:obj];
            } error:nil];
        }
        
        sel = NSSelectorFromString(@"application:didRegisterForRemoteNotificationsWithDeviceToken:");
        if (!class_getInstanceMethod(cls, sel)) {
            SEL newSel = @selector(CJM_application:didRegisterForRemoteNotificationsWithDeviceToken:);
            Method newMeth = class_getClassMethod([self class], newSel);
            IMP imp = method_getImplementation(newMeth);
            const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
            class_addMethod(cls, sel, imp, methodTypeEncoding);
        } else {
            __block NSInvocation *invocation = nil;
            invocation = [cls CJM_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSData *token) {
                [self CJM_application:application didRegisterForRemoteNotificationsWithDeviceToken:token];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&token atIndex:3];
                [invocation invokeWithTarget:obj];
            } error:nil];
        }
        
        // Notification Handling
#if !defined(CJM_TVOS)
        if (@available(iOS 10.0, *)) {
            Class ncdCls = [[UNUserNotificationCenter currentNotificationCenter].delegate class];
            if ([UNUserNotificationCenter class] && !ncdCls) {
                [[UNUserNotificationCenter currentNotificationCenter] addObserver:[self sharedInstance] forKeyPath:@"delegate" options:0 context:nil];
            } else if (class_getInstanceMethod(ncdCls, NSSelectorFromString(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"))) {
                sel = NSSelectorFromString(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:");
                __block NSInvocation *invocation = nil;
                invocation = [ncdCls CJM_swizzleMethod:sel withBlock:^(id obj, UNUserNotificationCenter *center, UNNotificationResponse *response, void (^completion)(void) ) {
                    [CJM handlePushNotification:response.notification.request.content.userInfo openDeepLinksInForeground:YES];
                    [invocation setArgument:&center atIndex:2];
                    [invocation setArgument:&response atIndex:3];
                    [invocation setArgument:&completion atIndex:4];
                    [invocation invokeWithTarget:obj];
                } error:nil];
            }
        }
        if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:didReceiveRemoteNotification:fetchCompletionHandler:"))) {
            sel = NSSelectorFromString(@"application:didReceiveRemoteNotification:fetchCompletionHandler:");
            __block NSInvocation *invocation = nil;
            invocation = [cls CJM_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSDictionary *userInfo, void (^completion)(UIBackgroundFetchResult result) ) {
                [CJM handlePushNotification:userInfo openDeepLinksInForeground:NO];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&userInfo atIndex:3];
                [invocation setArgument:&completion atIndex:4];
                [invocation invokeWithTarget:obj];
            } error:nil];
        } else if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:didReceiveRemoteNotification:"))) {
            sel = NSSelectorFromString(@"application:didReceiveRemoteNotification:");
            __block NSInvocation *invocation = nil;
            invocation = [cls CJM_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSDictionary *userInfo) {
                [CJM handlePushNotification:userInfo openDeepLinksInForeground:NO];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&userInfo atIndex:3];
                [invocation invokeWithTarget:obj];
            } error:nil];
        } else {
            sel = NSSelectorFromString(@"application:didReceiveRemoteNotification:");
            SEL newSel = @selector(CJM_application:didReceiveRemoteNotification:);
            Method newMeth = class_getClassMethod([self class], newSel);
            IMP imp = method_getImplementation(newMeth);
            const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
            class_addMethod(cls, sel, imp, methodTypeEncoding);
        }
#endif
        
        // URL handling
        if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:openURL:sourceApplication:annotation:"))) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
            sel = NSSelectorFromString(@"application:openURL:sourceApplication:annotation:");
            __block NSInvocation *invocation = nil;
            invocation = [cls CJM_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSURL *url, NSString *sourceApplication, id annotation ) {
                [[self class] CJM_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&url atIndex:3];
                [invocation setArgument:&sourceApplication atIndex:4];
                [invocation setArgument:&annotation atIndex:5];
                [invocation invokeWithTarget:obj];
            } error:nil];
#endif
        } else if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:openURL:options:"))) {
            sel = NSSelectorFromString(@"application:openURL:options:");
            __block NSInvocation *invocation = nil;
            invocation = [cls CJM_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSURL *url, NSDictionary<UIApplicationOpenURLOptionsKey, id> *options ) {
                [[self class] CJM_application:application openURL:url options:options];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&url atIndex:3];
                [invocation setArgument:&options atIndex:4];
                [invocation invokeWithTarget:obj];
            } error:nil];
        } else {
            if (@available(iOS 9.0, *)) {
                sel = NSSelectorFromString(@"application:openURL:options:");
                SEL newSel = @selector(CJM_application:openURL:options:);
                Method newMeth = class_getClassMethod([self class], newSel);
                IMP imp = method_getImplementation(newMeth);
                const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
                class_addMethod(cls, sel, imp, methodTypeEncoding);
            } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
                sel = NSSelectorFromString(@"application:openURL:sourceApplication:annotation:");
                SEL newSel = @selector(CJM_application:openURL:sourceApplication:annotation:);
                Method newMeth = class_getClassMethod([self class], newSel);
                IMP imp = method_getImplementation(newMeth);
                const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
                class_addMethod(cls, sel, imp, methodTypeEncoding);
#endif
            }
            // UIApplication caches whether or not the delegate responds to certain selectors. Clearing out the delegate and resetting it gaurantees that gets updated
            [sharedApplication setDelegate:nil];
            // UIApplication won't assume ownership of AppDelegate for setDelegate calls add a retain here
            [sharedApplication setDelegate:(__bridge id)CFRetain((__bridge CFTypeRef)appDelegate)];
        }
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
#if !defined(CJM_TVOS)
    if ([keyPath isEqualToString:@"delegate"]) {
        if (@available(iOS 10.0, *)) {
            Class cls = [[UNUserNotificationCenter currentNotificationCenter].delegate class];
            if (class_getInstanceMethod(cls, NSSelectorFromString(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"))) {
                SEL sel = NSSelectorFromString(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:");
                if (sel) {
                    __block NSInvocation *invocation = nil;
                    invocation = [cls CJM_swizzleMethod:sel withBlock:^(id obj, UNUserNotificationCenter *center, UNNotificationResponse *response, void (^completion)(void) ) {
                        [CJM handlePushNotification:response.notification.request.content.userInfo openDeepLinksInForeground:YES];
                        [invocation setArgument:&center atIndex:2];
                        [invocation setArgument:&response atIndex:3];
                        [invocation setArgument:&completion atIndex:4];
                        [invocation invokeWithTarget:obj];
                    } error:nil];
                }
            }
        }
    }
#endif
}


#pragma mark - AppDelegate Swizzles and Related

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
#if !defined(CJM_TVOS)
+ (BOOL)CJM_application:(UIApplication *)application
               openURL:(NSURL *)url
     sourceApplication:(NSString *)sourceApplication
            annotation:(id)annotation {
    CJMLogStaticDebug(@"Handling openURL:sourceApplication: %@", url);
    [CJM handleOpenURL:url];
    return NO;
}
#endif
#endif
+ (BOOL)CJM_application:(UIApplication *)application
               openURL:(NSURL *)url
               options:(NSDictionary<NSString*, id> *)options {
    CJMLogStaticDebug(@"Handling openURL:options: %@", url);
    [CJM handleOpenURL:url];
    return NO;
}

+ (void)CJM_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *deviceTokenString = [CJMUtils deviceTokenStringFromData:deviceToken];
    if (!_instances || [_instances count] <= 0) {
        [[CJM sharedInstance] setPushTokenAsString:deviceTokenString];
        return;
    }
    for (CJM *instance in [_instances allValues]) {
        [instance setPushTokenAsString:deviceTokenString];
    }
}
+ (void)CJM_application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    CJMLogStaticDebug(@"Application failed to register for remote notification: %@", error);
}
+ (void)CJM_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [CJM handlePushNotification:userInfo openDeepLinksInForeground:NO];
}

#pragma clang diagnostic pop


#pragma mark - Instance Lifecycle

+ (nullable instancetype)sharedInstance {
    return [self _sharedInstanceWithCJMID:nil];
}

+ (nullable instancetype)sharedInstanceWithCJMID:(NSString *)CJMID {
    return [self _sharedInstanceWithCJMID:CJMID];
}

+ (nullable instancetype)_sharedInstanceWithCJMID:(NSString *)CJMID {
    if (_defaultInstanceConfig == nil) {
        if (!_plistInfo.accountId || !_plistInfo.accountToken) {
            if (!sharedInstanceErrorLogged) {
                sharedInstanceErrorLogged = YES;
                CJMLogStaticInfo(@"Unable to initialize default CleverTap SDK instance. %@: %@ %@: %@", CLTAP_ACCOUNT_ID_LABEL, _plistInfo.accountId, CLTAP_TOKEN_LABEL, _plistInfo.accountToken);
            }
            return nil;
        }
        
        _defaultInstanceConfig = [[CJMInstanceConfig alloc] initWithAccountId:_plistInfo.accountId accountToken:_plistInfo.accountToken accountPasscode: _plistInfo.accountPasscode accountRegion:_plistInfo.accountRegion isDefaultInstance:YES];
        
        if (_defaultInstanceConfig == nil) {
            return nil;
        }
        _defaultInstanceConfig.enablePersonalization = [CJM isPersonalizationEnabled];
        _defaultInstanceConfig.logLevel = [self getDebugLevel];
        CJMLogStaticInfo(@"Initializing default CleverTap SDK instance. %@: %@ %@: %@ %@: %@", CLTAP_ACCOUNT_ID_LABEL, _plistInfo.accountId, CLTAP_TOKEN_LABEL, _plistInfo.accountToken, CLTAP_REGION_LABEL, (!_plistInfo.accountRegion || _plistInfo.accountRegion.length < 1) ? @"default" : _plistInfo.accountRegion);
    }
    return [self instanceWithConfig:_defaultInstanceConfig andCJMID:CJMID];
}

+ (instancetype)instanceWithConfig:(CJMInstanceConfig*)config {
    return [self _instanceWithConfig:config andCJMID:nil];
}

+ (instancetype)instanceWithConfig:(CJMInstanceConfig *)config andCJMID:(NSString *)CJMID {
    return [self _instanceWithConfig:config andCJMID:CJMID];
}

+ (instancetype)_instanceWithConfig:(CJMInstanceConfig *)config andCJMID:(NSString *)CJMID {
    if (!_instances) {
        _instances = [[NSMutableDictionary alloc] init];
    }
    __block CJM *instance = [_instances objectForKey:config.accountId];
    if (instance == nil) {
#if !CJM_NO_AB_SUPPORT
        // Default or first non-default instance gets the ABTestController
        config.enableABTesting =  (config.isDefaultInstance || [_instances count] <= 0);
#endif
        instance = [[self alloc] initWithConfig:config andCJMID:CJMID];
        _instances[config.accountId] = instance;
        [instance recordDeviceErrors];
    } else {
        if ([instance.deviceInfo isErrorDeviceID] && instance.config.useCustomCJMId && CJMID != nil && [CJMValidator isValidCJMId:CJMID]) {
            [instance _asyncSwitchUser:nil withCachedGuid:nil andCJMID:CJMID forAction:kInstanceWithCJMIDAction];
        }
    }
    return instance;
}

- (void)intergrateFirebaseAnalytics: (FIRAnalytics * _Nonnull) analytics {
    _firAnalytics = analytics;
}

- (instancetype)initWithConfig:(CJMInstanceConfig*)config andCJMID:(NSString *)CJMID {
    self = [super init];
    if (self) {
        _config = [config copy];
        if (_config.analyticsOnly) {
            CJMLogDebug(_config.logLevel, @"%@ is configured as analytics only!", self);
        }
        _deviceInfo = [[CJMDeviceInfo alloc] initWithConfig:_config andCJMID:CJMID];
        NSMutableDictionary *initialProfileValues = [NSMutableDictionary new];
        if (_deviceInfo.carrier && ![_deviceInfo.carrier isEqualToString:@""]) {
            initialProfileValues[CLTAP_SYS_CARRIER] = _deviceInfo.carrier;
        }
        if (_deviceInfo.countryCode && ![_deviceInfo.countryCode isEqualToString:@""]) {
            initialProfileValues[CLTAP_SYS_CC] = _deviceInfo.countryCode;
        }
        if (_deviceInfo.timeZone&& ![_deviceInfo.timeZone isEqualToString:@""]) {
            initialProfileValues[CLTAP_SYS_TZ] = _deviceInfo.timeZone;
        }
        _localDataStore = [[CJMLocalDataStore alloc] initWithConfig:_config andProfileValues:initialProfileValues];
        
        _serialQueue = dispatch_queue_create([_config.queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_serialQueue, kQueueKey, (__bridge void *)self, NULL);
        
        _lastAppLaunchedTime = [self eventGetLastTime:@"App Launched"];
        self.pendingValidationResults = [NSMutableArray array];
        self.userSetLocation = emptyLocation;
        self.minSessionSeconds =  CLTAP_SESSION_LENGTH_MINS * 60;
        [self _setDeviceNetworkInfoReportingFromStorage];
        [self _setCurrentUserOptOutStateFromStorage];
        [self initNetworking];
        [self inflateQueuesAsync];
        [self addObservers];
#if !CJM_NO_INAPP_SUPPORT
        if (!_config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
            _notificationQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.clevertap.notificationQueue:%@", _config.accountId] UTF8String], DISPATCH_QUEUE_SERIAL);
            dispatch_queue_set_specific(_notificationQueue, kNotificationQueueKey, (__bridge void *)self, NULL);
            _inAppFCManager = [[CJMInAppFCManager alloc] initWithConfig:_config guid: [self.deviceInfo.deviceId copy]];
        }
#endif
        int now = [[[NSDate alloc] init] timeIntervalSince1970];
        if (now - initialAppEnteredForegroundTime > 5) {
            _config.isCreatedPostAppLaunched = YES;
        }
        
#if !CJM_NO_AB_SUPPORT
        // Default (flag is set in the config init) or first non-default instance gets the ABTestController
        if (!_config.enableABTesting) {
            _config.enableABTesting = (!_instances || [_instances count] <= 0);
        }
        [self _initABTesting];
#endif
        [self _initFeatureFlags];
        
        [self _initProductConfig];
        
        [self notifyUserProfileInitialized];
    }
    
    return self;
}

// notify application code once we have a device GUID
- (void)notifyUserProfileInitialized {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *deviceID = self.deviceInfo.deviceId;
        if (!deviceID) return;
        CJMLogInternal(self.config.logLevel, @"%@: Notifying user profile initialized with ID %@", self, deviceID);
        
        id <CJMSyncDelegate> apiDelegate = [self syncDelegate];
        
        if (apiDelegate && [apiDelegate respondsToSelector:@selector(profileDidInitialize:)]) {
            [apiDelegate profileDidInitialize:deviceID];
        }
        if (apiDelegate && [apiDelegate respondsToSelector:@selector(profileDidInitialize:forAccountId:)]) {
            [apiDelegate profileDidInitialize:deviceID forAccountId:self.config.accountId];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CJMProfileDidInitializeNotification object:nil userInfo:@{@"CleverTapID" : deviceID, @"CleverTapAccountID":self.config.accountId}];
    });
}

- (void) dealloc {
    [self removeObservers];
}


#pragma mark - Private

+ (void)_changeCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token passcode:(NSString *)passcode region:(NSString *)region {
    if (_defaultInstanceConfig) {
        CJMLogStaticDebug(@"CleverTap SDK already initialized with accountID: %@ and token: %@. Cannot change credentials to %@ : %@", _defaultInstanceConfig.accountId, _defaultInstanceConfig.accountToken, accountID, token);
        return;
    }
    accountID = [accountID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    token = [token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    passcode = [passcode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (region != nil && ![region isEqualToString:@""]) {
        region = [region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (region.length <= 0) {
            region = nil;
        }
    }
    [_plistInfo changeCredentialsWithAccountID:accountID token:token passcode:passcode region:region];
}

+ (void)runSyncMainQueue:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (UIApplication *)getSharedApplication {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if (UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return [UIApplication performSelector:@selector(sharedApplication)];
    }
    return nil;
}

+ (BOOL)runningInsideAppExtension {
    return [self getSharedApplication] == nil;
}

- (void)addObservers {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"CleverTap.%@", self.config.accountId];
}

- (NSString *)storageKeyWithSuffix: (NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@", self.config.accountId, suffix];
}

- (void)initNetworking {
    if (self.config.isDefaultInstance) {
        self.lastMutedTs = [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kLAST_TS_KEY] withResetValue:[CJMPreferences getIntForKey:kMUTED_TS_KEY withResetValue:0]];
    } else {
        self.lastMutedTs = [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kLAST_TS_KEY] withResetValue:0];
    }
    self.redirectDomain = [self loadRedirectDomain];
    self.redirectNotifViewedDomain = [self loadRedirectNotifViewedDomain];
    [self setUpUrlSession];
    [self doHandshakeAsync];
}

- (void)setUpUrlSession {
    if (!self.urlSession) {
        NSURLSessionConfiguration *sc = [NSURLSessionConfiguration defaultSessionConfiguration];
        [sc setHTTPAdditionalHeaders:@{
            @"Content-Type" : @"application/json; charset=utf-8"
        }];
        
        sc.timeoutIntervalForRequest = CLTAP_REQUEST_TIME_OUT_INTERVAL;
        sc.timeoutIntervalForResource = CLTAP_REQUEST_TIME_OUT_INTERVAL;
        [sc setHTTPShouldSetCookies:NO];
        [sc setRequestCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        
//#if CJM_SSL_PINNING
        _sslPinningEnabled = YES;
        self.urlSessionDelegate = [[CJMPinnedNSURLSessionDelegate alloc] initWithConfig:self.config];
        NSMutableArray *domains = [NSMutableArray arrayWithObjects:kCJMApiDomain, nil];
        if (self.redirectDomain && ![self.redirectDomain isEqualToString:kCJMApiDomain]) {
            [domains addObject:self.redirectDomain];
        }
        [self.urlSessionDelegate pinSSLCerts:sslCertNames forDomains:domains];
        self.urlSession = [NSURLSession sessionWithConfiguration:sc delegate:self.urlSessionDelegate delegateQueue:nil];
//#else
//        _sslPinningEnabled = NO;
//        self.urlSession = [NSURLSession sessionWithConfiguration:sc];
//#endif
    }
}

- (void)setUserSetLocation:(CLLocationCoordinate2D)location {
    _userSetLocation = location;
    if (!self.isAppForeground) return;
    // if in foreground, queue the ping event to transmit location update to server
    // min 10 second interval between location pings
    double now = [[[NSDate alloc] init] timeIntervalSince1970];
    if (now > (self.lastLocationPingTime + CLTAP_LOCATION_PING_INTERVAL_SECONDS)) {
        [self queueEvent:@{} withType:CJMEventTypePing];
        self.lastLocationPingTime = now;
    }
}

- (CLLocationCoordinate2D)userSetLocation {
    return _userSetLocation;
}


# pragma mark - Handshake Handling

- (void)clearRedirectDomain {
    self.redirectDomain = nil;
    self.redirectNotifViewedDomain = nil;
    [self persistRedirectDomain]; // if nil persist will remove
    self.redirectDomain = [self loadRedirectDomain]; // reload explicit domain if we have one else will be nil
    self.redirectNotifViewedDomain = [self loadRedirectNotifViewedDomain]; // reload explicit notification viewe domain if we have one else will be nil
}

- (NSString *)loadRedirectDomain {
    NSString *region = self.config.accountRegion;
    if (region) {
        region = [region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
        if (region.length > 0) {
            self.explictEndpointDomain = [NSString stringWithFormat:@"%@.%@", region, kCJMApiDomain];
            return self.explictEndpointDomain;
        }
    }
    NSString *domain = nil;
    if (self.config.isDefaultInstance) {
        domain = [CJMPreferences getStringForKey:[self storageKeyWithSuffix:kREDIRECT_DOMAIN_KEY] withResetValue:[CJMPreferences getStringForKey:kREDIRECT_DOMAIN_KEY withResetValue:nil]];
    } else {
        domain = [CJMPreferences getStringForKey:[self storageKeyWithSuffix:kREDIRECT_DOMAIN_KEY] withResetValue:nil];
    }
    return domain;
}

- (NSString *)loadRedirectNotifViewedDomain {
    NSString *region = self.config.accountRegion;
    if (region) {
        region = [region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
        if (region.length > 0) {
            self.explictNotifViewedEndpointDomain = [NSString stringWithFormat:@"%@-%@", region, kCJMNotifViewedApiDomain];
            return self.explictNotifViewedEndpointDomain;
        }
    }
    NSString *domain = nil;
    if (self.config.isDefaultInstance) {
        domain = [CJMPreferences getStringForKey:[self storageKeyWithSuffix:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY] withResetValue:[CJMPreferences getStringForKey:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY withResetValue:nil]];
    } else {
        domain = [CJMPreferences getStringForKey:[self storageKeyWithSuffix:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY] withResetValue:nil];
    }
    return domain;
}

- (void)persistRedirectDomain {
    if (self.redirectDomain != nil) {
        [CJMPreferences putString:self.redirectDomain forKey:[self storageKeyWithSuffix:kREDIRECT_DOMAIN_KEY]];
//#if CJM_SSL_PINNING
        [self.urlSessionDelegate pinSSLCerts:sslCertNames forDomains:@[kCJMApiDomain, self.redirectDomain]];
//#endif
    } else {
        [CJMPreferences removeObjectForKey:kREDIRECT_DOMAIN_KEY];
        [CJMPreferences removeObjectForKey:[self storageKeyWithSuffix:kREDIRECT_DOMAIN_KEY]];
    }
}

- (void)persistRedirectNotifViewedDomain {
    if (self.redirectNotifViewedDomain != nil) {
        [CJMPreferences putString:self.redirectNotifViewedDomain forKey:[self storageKeyWithSuffix:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY]];
//#if CJM_SSL_PINNING
        [self.urlSessionDelegate pinSSLCerts:sslCertNames forDomains:@[kCJMNotifViewedApiDomain, self.redirectNotifViewedDomain]];
//#endif
    } else {
        [CJMPreferences removeObjectForKey:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY];
        [CJMPreferences removeObjectForKey:[self storageKeyWithSuffix:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY]];
    }
}
- (void)persistMutedTs {
    self.lastMutedTs = [NSDate new].timeIntervalSince1970;
    [CJMPreferences putInt:self.lastMutedTs forKey:[self storageKeyWithSuffix:kMUTED_TS_KEY]];
}

- (BOOL)needHandshake {
    if ([self isMuted] || self.explictEndpointDomain) return NO;
    return self.redirectDomain == nil;
}

- (void)doHandshakeAsync {
    [self runSerialAsync:^{
        if (![self needHandshake]) return;
        CJMLogInternal(self.config.logLevel, @"%@: starting handshake with %@", self, kHANDSHAKE_URL);
        NSMutableURLRequest *request = [self createURLRequestFromURL:[[NSURL alloc] initWithString:kHANDSHAKE_URL]];
        request.HTTPMethod = @"POST";
        
        //forward CJM
        NSMutableURLRequest *requestForward = [[CJMManager sharedInstance] forwardHandShakeRequestCJM:request];
        
        // Need to simulate a synchronous request
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSessionDataTask *task = [self.urlSession
                                      dataTaskWithRequest:requestForward
                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode == 200) {
                    [self updateStateFromResponseHeadersShouldRedirect:httpResponse.allHeaderFields];
                    [self updateStateFromResponseHeadersShouldRedirectForNotif:httpResponse.allHeaderFields];
                    [self handleHandshakeSuccess];
                }
            }
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }];
}

- (BOOL)updateStateFromResponseHeadersShouldRedirectForNotif:(NSDictionary *)headers {
    CJMLogInternal(self.config.logLevel, @"%@: processing response with headers:%@", self, headers);
    BOOL shouldRedirect = NO;
    @try {
        NSString *redirectNotifViewedDomain = headers[kREDIRECT_NOTIF_VIEWED_HEADER];
        if (redirectNotifViewedDomain != nil) {
            NSString *currentDomain = self.redirectNotifViewedDomain;
            self.redirectNotifViewedDomain = redirectNotifViewedDomain;
            if (![self.redirectNotifViewedDomain isEqualToString:currentDomain]) {
                shouldRedirect = YES;
                self.redirectNotifViewedDomain = redirectNotifViewedDomain;
                [self persistRedirectNotifViewedDomain];
            }
        }
        NSString *mutedString = headers[kMUTE_HEADER];
        BOOL muted = (mutedString == nil ? NO : [mutedString boolValue]);
        if (muted) {
            [self persistMutedTs];
            [self clearQueues];
        }
    } @catch(NSException *e) {
        CJMLogInternal(self.config.logLevel, @"%@: Error processing Notification Viewed response headers: %@", self, e.debugDescription);
    }
    return shouldRedirect;
}

- (BOOL)updateStateFromResponseHeadersShouldRedirect:(NSDictionary *)headers {
    CJMLogInternal(self.config.logLevel, @"%@: processing response with headers:%@", self, headers);
    BOOL shouldRedirect = NO;
    @try {
        NSString *redirectDomain = headers[kREDIRECT_HEADER];
        if (redirectDomain != nil) {
            NSString *currentDomain = self.redirectDomain;
            self.redirectDomain = redirectDomain;
            if (![self.redirectDomain isEqualToString:currentDomain]) {
                shouldRedirect = YES;
                self.redirectDomain = redirectDomain;
                [self persistRedirectDomain];
            }
        }
        NSString *mutedString = headers[kMUTE_HEADER];
        BOOL muted = (mutedString == nil ? NO : [mutedString boolValue]);
        if (muted) {
            [self persistMutedTs];
            [self clearQueues];
        }
    } @catch(NSException *e) {
        CJMLogInternal(self.config.logLevel, @"%@: Error processing response headers: %@", self, e.debugDescription);
    }
    return shouldRedirect;
}

- (void)handleHandshakeSuccess {
    CJMLogInternal(self.config.logLevel, @"%@: handshake success", self);
    [self resetFailsCounter];
}

- (void)resetFailsCounter {
    self.sendQueueFails = 0;
}

- (void)handleSendQueueSuccess {
    [self setLastRequestTimestamp:currentRequestTimestamp];
    [self setFirstRequestTimestampIfNeeded:currentRequestTimestamp];
    [self resetFailsCounter];
}

- (void)handleSendQueueFail {
    self.sendQueueFails += 1;
    if (self.sendQueueFails > 5) {
        [self clearRedirectDomain];
        self.sendQueueFails = 0;
    }
}


#pragma mark - Queue/Dispatch helpers

- (NSMutableURLRequest *)createURLRequestFromURL:(NSURL *)url {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSString *accountId = self.config.accountId;
    NSString *accountToken = self.config.accountToken;
    if (accountId) {
        [request setValue:accountId forHTTPHeaderField:kACCOUNT_ID_HEADER];
    }
    if (accountToken) {
        [request setValue:accountToken forHTTPHeaderField:kACCOUNT_TOKEN_HEADER];
    }
    return request;
}

- (NSString *)endpointForQueue: (NSMutableArray *)queue {
    if (!self.redirectDomain) return nil;
    NSString *accountId = self.config.accountId;
    NSString *sdkRevision = self.deviceInfo.sdkVersion;
    NSString *endpointDomain;
    if (queue == _notificationsQueue) {
        endpointDomain = self.redirectNotifViewedDomain;
    } else {
        endpointDomain = self.redirectDomain;
    }
    NSString *endpointUrl = [[NSString alloc] initWithFormat:@"https://%@/a1?os=iOS&t=%@&z=%@", endpointDomain, sdkRevision, accountId];
    currentRequestTimestamp = (int) [[[NSDate alloc] init] timeIntervalSince1970];
    endpointUrl = [endpointUrl stringByAppendingFormat:@"&ts=%d", currentRequestTimestamp];
    return endpointUrl;
}

- (NSDictionary *)batchHeader {
    NSDictionary *appFields = [self generateAppFields];
    NSMutableDictionary *header = [@{@"type" : @"meta", @"af" : appFields} mutableCopy];
    
    header[@"g"] = self.deviceInfo.deviceId;
    header[@"tk"] = self.config.accountToken;
    header[@"id"] = self.config.accountId;
    
    header[@"ddnd"] = @([self getStoredDeviceToken].length <= 0);
    
    header[@"frs"] = @(_firstRequestInSession);
    _firstRequestInSession = NO;
    
    int lastTS = [self getLastRequestTimeStamp];
    header[@"l_ts"] = @(lastTS);
    
    int firstTS = [self getFirstRequestTimestamp];
    header[@"f_ts"] = @(firstTS);
    
    NSArray *registeredURLSchemes = _plistInfo.registeredUrlSchemes;
    if (registeredURLSchemes && [registeredURLSchemes count] > 0) {
        header[@"regURLs"] = registeredURLSchemes;
    }
    
    @try {
        NSDictionary *arp = [self getARP];
        if (arp && [arp count] > 0) {
            header[@"arp"] = arp;
        }
    } @catch (NSException *ex) {
        CJMLogInternal(self.config.logLevel, @"%@: Failed to attach ARP to batch header", self);
    }
    
    @try {
        NSMutableDictionary *ref = [NSMutableDictionary new];
        if (self.source != nil) {
            ref[@"us"] = self.source;
        }
        if (self.medium != nil) {
            ref[@"um"] = self.medium;
        }
        if (self.campaign != nil) {
            ref[@"uc"] = self.campaign;
        }
        if ([ref count] > 0) {
            header[@"ref"] = ref;
        }
        
    } @catch (NSException *ex) {
        CJMLogInternal(self.config.logLevel, @"%@: Failed to attach ref to batch header", self);
    }
    
    @try {
        if (self.wzrkParams != nil && [self.wzrkParams count] > 0) {
            header[@"wzrk_ref"] = self.wzrkParams;
        }
        
    } @catch (NSException *ex) {
        CJMLogInternal(self.config.logLevel, @"%@: Failed to attach wzrk_ref to batch header", self);
    }
#if !CJM_NO_INAPP_SUPPORT
    if (!_config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
        [self.inAppFCManager attachToHeader:header];
    }
#endif
    return header;
}

- (NSArray *)insertHeader:(NSDictionary *)header inBatch:(NSArray *)batch {
    if (batch == nil || header == nil) {
        return batch;
    }
    NSMutableArray *newBatch = [NSMutableArray arrayWithArray:batch];
    [newBatch insertObject:header atIndex:0];
    return newBatch;
}

- (NSDictionary *)generateAppFields {
    NSMutableDictionary *evtData = [NSMutableDictionary new];
    
    evtData[@"Version"] = self.deviceInfo.appVersion;
    
    evtData[@"Build"] = self.deviceInfo.appBuild;
    
    evtData[@"SDK Version"] = self.deviceInfo.sdkVersion;
    
    if (self.deviceInfo.model) {
        evtData[@"Model"] = self.deviceInfo.model;
    }
    
    if (CLLocationCoordinate2DIsValid(self.userSetLocation)) {
        evtData[@"Latitude"] = @(self.userSetLocation.latitude);
        evtData[@"Longitude"] = @(self.userSetLocation.longitude);
    }
    
    evtData[@"Make"] = self.deviceInfo.manufacturer;
    evtData[@"OS Version"] = self.deviceInfo.osVersion;
    
    if (self.deviceInfo.carrier) {
        evtData[@"Carrier"] = self.deviceInfo.carrier;
    }
    
    evtData[@"useIP"] = @(self.enableNetworkInfoReporting);
    if (self.enableNetworkInfoReporting) {
        if (self.deviceInfo.radio != nil) {
            evtData[@"Radio"] = self.deviceInfo.radio;
        }
        evtData[@"wifi"] = @(self.deviceInfo.wifi);
    }
    
    evtData[@"ifaA"] = @NO;
    if (self.deviceInfo.vendorIdentifier) {
        NSString *ifvString = [self deviceIsMultiUser] ?  [NSString stringWithFormat:@"%@%@", kMultiUserPrefix, @"ifv"] : @"ifv";
        evtData[ifvString] = self.deviceInfo.vendorIdentifier;
    }
    
    if ([[self class] runningInsideAppExtension]) {
        evtData[@"appex"] = @1;
    }
    
    evtData[@"OS"] = self.deviceInfo.osName;
    evtData[@"wdt"] = self.deviceInfo.deviceWidth;
    evtData[@"hgt"] = self.deviceInfo.deviceHeight;
    NSString *cc = self.deviceInfo.countryCode;
    if (cc != nil && ![cc isEqualToString:@""]) {
        evtData[@"cc"] = cc;
    }
    
    if (self.deviceInfo.library) {
        evtData[@"lib"] = self.deviceInfo.library;
    }
    return evtData;
}

- (NSString *)jsonObjectToString:(id)object {
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    @try {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                           options:0
                                                             error:&error];
        if (error) {
            return @"";
        }
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
    @catch (NSException *exception) {
        return @"";
    }
}

- (id)convertDataToPrimitive:(id)event {
    @try {
        if ([event isKindOfClass:[NSArray class]]) {
            NSMutableArray *eventData = [[NSMutableArray alloc] init];
            for (id value in event) {
                id obj = value;
                obj = [self convertDataToPrimitive:obj];
                if (obj != nil) {
                    [eventData addObject:obj];
                }
            }
            return eventData;
        } else if ([event isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *eventData = [[NSMutableDictionary alloc] init];
            for (id key in [event allKeys]) {
                id obj = [event objectForKey:key];
                if ([key isKindOfClass:[NSString class]]
                    && ([(NSString *) key isEqualToString:@"FBID"] || [(NSString *) key isEqualToString:@"GPID"])) {
                    if (obj != nil) {
                        eventData[key] = obj;
                    }
                } else {
                    obj = [self convertDataToPrimitive:obj];
                    if (obj != nil) {
                        eventData[key] = obj;
                    }
                }
            }
            return eventData;
        } else if ([event isKindOfClass:[NSString class]]) {
            // Try to convert it to a double first
            double forcedDoubleValue = [(NSString *) event doubleValue];
            if ([[@(forcedDoubleValue) stringValue] isEqualToString:(NSString *) event]) {
                return @(forcedDoubleValue);
            } else {
                int forcedIntValue = [(NSString *) event intValue];
                if ([[@(forcedIntValue) stringValue] isEqualToString:(NSString *) event]) {
                    return @(forcedIntValue);
                }
            }
            return event;
        } else if ([event isKindOfClass:[NSNumber class]]) {
            return event;
        } else {
            // Couldn't understand what it was
            return nil;
        }
    } @catch (NSException *exception) {
        // Ignore
    }
    return nil;
}


#pragma mark - Timestamp bookkeeping helpers

- (void)setLastRequestTimestamp:(double)ts {
    [CJMPreferences putInt:ts forKey:kLAST_TS_KEY];
}

- (NSTimeInterval)getLastRequestTimeStamp {
    if (self.config.isDefaultInstance) {
        return [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kLAST_TS_KEY] withResetValue:[CJMPreferences getIntForKey:kLAST_TS_KEY withResetValue:0]];
    } else {
        return [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kLAST_TS_KEY] withResetValue:0];
    }
}

- (void)clearLastRequestTimestamp {
    [CJMPreferences putInt:0 forKey:[self storageKeyWithSuffix:kLAST_TS_KEY]];
}

- (void)setFirstRequestTimestampIfNeeded:(double)ts {
    NSTimeInterval firstRequestTS = [self getFirstRequestTimestamp];
    if (firstRequestTS > 0) return;
    [CJMPreferences putInt:ts forKey:[self storageKeyWithSuffix:kFIRST_TS_KEY]];
}

- (NSTimeInterval)getFirstRequestTimestamp {
    if (self.config.isDefaultInstance) {
        return [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kFIRST_TS_KEY] withResetValue:[CJMPreferences getIntForKey:kFIRST_TS_KEY withResetValue:0]];
    } else {
        return [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kFIRST_TS_KEY] withResetValue:0];
    }
}

- (void)clearFirstRequestTimestamp {
    [CJMPreferences putInt:0 forKey:[self storageKeyWithSuffix:kFIRST_TS_KEY]];
}

- (BOOL)isMuted {
    return [NSDate new].timeIntervalSince1970 - _lastMutedTs < 24 * 60 * 60;
}


#pragma mark - Lifecycle Handling

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self _appEnteredForeground];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    if ([self isMuted]) return;
    [self flushQueue];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    CJMLogInternal(self.config.logLevel, @"%@: applicationDidEnterBackground", self);
    [self _appEnteredBackground];
}

- (void)applicationWillEnterForeground:(NSNotificationCenter *)notification {
    if ([self needHandshake]) {
        [self doHandshakeAsync];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if ([self isMuted]) return;
    [self persistQueues];
}

- (void)_appEnteredForegroundWithLaunchingOptions:(NSDictionary *)launchOptions {
    CJMLogInternal(self.config.logLevel, @"%@: appEnteredForeground with options: %@", self, launchOptions);
    if ([[self class] runningInsideAppExtension]) return;
    [self _appEnteredForeground];
    
#if !defined(CJM_TVOS)
    // check for a launching push and handle
    if (isAutoIntegrated) {
        if (@available(iOS 10.0, *)) {
            Class ncdCls = [[UNUserNotificationCenter currentNotificationCenter].delegate class];
            if ([UNUserNotificationCenter class] && ncdCls) {
                CJMLogDebug(self.config.logLevel, @"%@: CleverTap autoIntegration enabled in iOS10+ with a UNUserNotificationCenterDelegate, not manually checking for push notification at launch", self);
                return;
            }
        }
    }
    if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        NSDictionary *notification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        CJMLogDebug(self.config.logLevel, @"%@: found push notification at launch: %@", self, notification);
        [self _handlePushNotification:notification];
    }
#endif
}

- (void)_appEnteredForeground {
    if ([[self class] runningInsideAppExtension]) return;
    [self updateSessionStateOnLaunch];
    if (!self.isAppForeground) {
        [self recordAppLaunched:@"appEnteredForeground"];
        [self scheduleQueueFlush];
        CJMLogInternal(self.config.logLevel, @"%@: app is in foreground", self);
    }
    self.isAppForeground = YES;
    
#if !CJM_NO_INAPP_SUPPORT
    if (!_config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
        [self.inAppFCManager checkUpdateDailyLimits];
    }
#endif
}

- (void)_appEnteredBackground {
    self.isAppForeground = NO;
    if (![self isMuted]) {
        [self persistQueues];
    }
    [self runSerialAsync:^{
        [self updateSessionTime:(long) [[NSDate date] timeIntervalSince1970]];
    }];
}

- (void)recordAppLaunched:(NSString *)caller {
    if ([[self class] runningInsideAppExtension]) return;
    
    if (self.appLaunchProcessed) {
        CJMLogInternal(self.config.logLevel, @"%@: App Launched already processed", self);
        return;
    }
    
    self.appLaunchProcessed = YES;
    
    if (self.config.disableAppLaunchedEvent) {
        CJMLogDebug(self.config.logLevel, @"%@: Dropping App Launched event - reporting disabled in instance configuration", self);
        return;
    }
    
    CJMLogInternal(self.config.logLevel, @"%@: recording App Launched event from: %@", self, caller);
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    event[@"evtName"] = CLTAP_APP_LAUNCHED_EVENT;
    event[@"evtData"] = [self generateAppFields];
    
    if (self.lastUTMFields) {
        [event addEntriesFromDictionary:self.lastUTMFields];
    }
    [self queueEvent:event withType:CJMEventTypeRaised];
}

- (void)recordPageEventWithExtras:(NSDictionary *)extras {
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    @try {
        // Add the extras
        if (extras != nil && ((int) [extras count]) > 0) {
            for (NSString *key in [extras allKeys]) {
                @try {
                    jsonObject[key] = extras[key];
                } @catch (NSException *ignore) {
                    // no-op
                }
            }
        }
        [self queueEvent:jsonObject withType:CJMEventTypePage];
    } @catch (NSException *e) {
        //no-op
        CJMLogInternal(self.config.logLevel, @"%@: error recording page event: %@", self, e.debugDescription);
    }
}

- (void)pushInitialEventsIfNeeded {
    if (!self.initialEventsPushed) {
        self.initialEventsPushed = YES;
        [self pushInitialEvents];
    }
}

- (void)pushInitialEvents {
    if ([[self class] runningInsideAppExtension]) return;
    NSDate *d = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"d"];
    
    if ([CJMPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_LAST_DAILY_PUSHED_EVENTS_DATE] withResetValue:0] != [[dateFormatter stringFromDate:d] intValue]) {
        CJMLogInternal(self.config.logLevel, @"%@: queuing daily events", self);
        [self _pushBaseProfile];
        if (!self.pushedAPNSId) {
            [self pushDeviceTokenWithAction:CJMPushTokenRegister];
        } else {
            CJMLogInternal(self.config.logLevel, @"%@: Skipped push of the APNS ID, already sent.", self);
        }
    }
    [CJMPreferences putInt:[[dateFormatter stringFromDate:d] intValue] forKey:[self storageKeyWithSuffix:CLTAP_PREFS_LAST_DAILY_PUSHED_EVENTS_DATE]];
}


#pragma mark - Notifications Private

- (void)pushDeviceTokenWithAction:(CJMPushTokenRegistrationAction)action {
    if ([[self class] runningInsideAppExtension]) return;
    NSString *token = [self getStoredDeviceToken];
    if (token != nil && ![token isEqualToString:@""])
        [self pushDeviceToken:token forRegisterAction:action];
}

- (void)pushDeviceToken:(NSString *)deviceToken forRegisterAction:(CJMPushTokenRegistrationAction)action {
    if ([[self class] runningInsideAppExtension]) return;
    if (deviceToken == nil) return;
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *pushDetails = [[NSMutableDictionary alloc] init];
    pushDetails[@"action"] = (action == CJMPushTokenRegister ? @"register" : @"unregister");
    pushDetails[@"id"] = deviceToken;
    pushDetails[@"type"] = @"apns";
    event[@"data"] = pushDetails;
    [self queueEvent:event withType:CJMEventTypeData];
    self.pushedAPNSId = (action == CJMPushTokenRegister);
}

- (void)storeDeviceToken:(NSString *)deviceToken {
    CJMLogInternal(self.config.logLevel, @"%@: Saving APNS token for app version %@", self, self.deviceInfo.appVersion);
    [CJMPreferences putString:deviceToken forKey:CLTAP_APNS_PROPERTY_DEVICE_TOKEN];
}

- (NSString *)getStoredDeviceToken {
    NSString *deviceToken = [CJMPreferences getStringForKey:CLTAP_APNS_PROPERTY_DEVICE_TOKEN withResetValue:@""];
    if (!deviceToken || [deviceToken isEqualToString:@""]) {
        CJMLogInternal(self.config.logLevel, @"%@: APNS Push Token not found", self);
        return @"";
    }
    return deviceToken;
}
- (void)_handlePushNotification:(id)object {
    [self _handlePushNotification:object openDeepLinksInForeground:NO];
}

- (void)_handlePushNotification:(id)object openDeepLinksInForeground:(BOOL)openInForeground {
    if ([[self class] runningInsideAppExtension]) return;
    
    if (!object) return;
    
#if !defined(CJM_TVOS)
    // normalize the notification data
    NSDictionary *notification;
    if ([object isKindOfClass:[UILocalNotification class]]) {
        notification = [((UILocalNotification *) object) userInfo];
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        notification = object;
    }
    
    if (!notification || [notification count] <= 0) return;
    
    // make sure its our notification before processing
    
    BOOL shouldHandlePush = [self _isCJMPushNotification:notification];
    if (!shouldHandlePush) {
        CJMLogDebug(self.config.logLevel, @"%@: push notification not from CleverTap, not processing: %@", self, notification);
        return;
    }
    shouldHandlePush = !self.config.analyticsOnly;
    if (!shouldHandlePush) {
        CJMLogInternal(self.config.logLevel, @"%@: instance is analyticsOnly, not processing push notification %@", self, notification);
        return;
    }
    
    // this is push generated for this instance of the SDK
    NSString *accountId = (NSString *) notification[@"wzrk_acct_id"];
    // if there is no accountId then only process if its the default instance
    shouldHandlePush = accountId ? [accountId isEqualToString:self.config.accountId]: self.config.isDefaultInstance;
    if (!shouldHandlePush) {
        CJMLogInternal(self.config.logLevel, @"%@: push notification not targeted as this instance, not processing %@", self, notification);
        return;
    }
    
    CJMLogDebug(self.config.logLevel, @"%@: handling push notification: %@", self, notification);
    
    // check to see whether the push includes a test in-app notification, if so don't process further
    if ([self didHandleInAppTestFromPushNotificaton:notification]) return;
    
    // check to see whether the push includes a test inbox message, if so don't process further
    if ([self didHandleInboxMessageTestFromPushNotificaton:notification]) return;
    
    // check to see whether the push includes a test display unit, if so don't process further
    if ([self didHandleDisplayUnitTestFromPushNotificaton:notification]) return;
    
    // notify application with push notification custom extras
    [self _notifyPushNotificationTapped:notification];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // determine application state
        UIApplication *application = [[self class] getSharedApplication];
        if (application != nil) {
            BOOL inForeground = !(application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground);
            
            // should we open a deep link ?
            // if the app is in foreground and force flag is off, then don't fire any deep link
            if (inForeground && !openInForeground) {
                CJMLogDebug(self.config.logLevel, @"%@: app in foreground and openInForeground flag is FALSE, will not process any deep link for notification: %@", self, notification);
            } else {
                [self _checkAndFireDeepLinkForNotification:notification];
            }
            
            [self runSerialAsync:^{
                [CJMEventBuilder buildPushNotificationEvent:YES forNotification:notification completionHandler:^(NSDictionary *event, NSArray<CJMValidationResult*>*errors) {
                    if (event) {
                        self.wzrkParams = [event[@"evtData"] copy];
                        [self queueEvent:event withType:CJMEventTypeRaised];
                    };
                    if (errors) {
                        [self pushValidationResults:errors];
                    }
                }];
            }];
        }
    });
#endif
}

- (void)_notifyPushNotificationTapped:(NSDictionary *)notification {
    if (self.pushNotificationDelegate && [self.pushNotificationDelegate respondsToSelector:@selector(pushNotificationTappedWithCustomExtras:)]) {
        NSMutableDictionary *mutableNotification = [NSMutableDictionary dictionaryWithDictionary:notification];
        [mutableNotification removeObjectForKey:@"aps"];
        [self.pushNotificationDelegate pushNotificationTappedWithCustomExtras:mutableNotification];
    }
}

- (void)_checkAndFireDeepLinkForNotification:(NSDictionary *)notification {
    UIApplication *application = [[self class] getSharedApplication];
    if (application != nil) {
        @try {
            NSString *dl = (NSString *) notification[@"wzrk_dl"];
            if (dl) {
                __block NSURL *dlURL = [NSURL URLWithString:dl];
                if (dlURL) {
                    [[self class] runSyncMainQueue:^{
                        CJMLogDebug(self.config.logLevel, @"%@: Firing deep link: %@", self, dl);
                        if (@available(iOS 10.0, *)) {
                            if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                                NSMethodSignature *signature = [UIApplication
                                                                instanceMethodSignatureForSelector:@selector(openURL:options:completionHandler:)];
                                NSInvocation *invocation = [NSInvocation
                                                            invocationWithMethodSignature:signature];
                                [invocation setTarget:application];
                                [invocation setSelector:@selector(openURL:options:completionHandler:)];
                                NSDictionary *options = @{};
                                id completionHandler = nil;
                                [invocation setArgument:&dlURL atIndex:2];
                                [invocation setArgument:&options atIndex:3];
                                [invocation setArgument:&completionHandler atIndex:4];
                                [invocation invoke];
                            } else {
                                if ([application respondsToSelector:@selector(openURL:)]) {
                                    [application performSelector:@selector(openURL:) withObject:dlURL];
                                }
                            }
                        } else {
                            if ([application respondsToSelector:@selector(openURL:)]) {
                                [application performSelector:@selector(openURL:) withObject:dlURL];
                            }
                        }
                    }];
                }
            }
        }
        @catch (NSException *exception) {
            CJMLogDebug(self.config.logLevel, @"%@: Unable to fire deep link: %@", self, [exception reason]);
        }
    }
}

- (void)_pushDeepLink:(NSString *)uri withSourceApp:(NSString *)sourceApp andInstall:(BOOL)install {
    if (uri == nil)
        return;
    if (!sourceApp) sourceApp = uri;
    NSDictionary *referrer = [CJMUriHelper getUrchinFromUri:uri withSourceApp:sourceApp];
    if ([referrer count] == 0) {
        return;
    }
    [self setSource:referrer[@"us"]];
    [self setMedium:referrer[@"um"]];
    [self setCampaign:referrer[@"uc"]];
    [referrer setValue:@(install) forKey:@"install"];
    self.lastUTMFields = [[NSMutableDictionary alloc] initWithDictionary:referrer];
    [self recordPageEventWithExtras:self.lastUTMFields];
}

- (void)_pushDeepLink:(NSString *)uri withSourceApp:(NSString *)sourceApp {
    [self _pushDeepLink:uri withSourceApp:sourceApp andInstall:false];
}

- (BOOL)_isCJMPushNotification:(NSDictionary *)notification {
    BOOL isOurs = NO;
    @try {
        for (NSString *key in [notification allKeys]) {
            if (([CJMUtils doesString:key startWith:CLTAP_NOTIFICATION_TAG] || [CJMUtils doesString:key startWith:CLTAP_NOTIFICATION_TAG_SECONDARY])) {
                isOurs = YES;
                break;
            }
        }
    } @catch (NSException *e) {
        // no-op
    }
    
    return isOurs;
}


#pragma mark - InApp Notifications Private

- (BOOL)didHandleInAppTestFromPushNotificaton:(NSDictionary*)notification {
#if !CJM_NO_INAPP_SUPPORT
    if ([[self class] runningInsideAppExtension]) {
        return NO;
    }
    
    if (!notification || [notification count] <= 0 || !notification[@"wzrk_inapp"]) return NO;
    
    @try {
        [self.inAppFCManager resetSession];
        CJMLogDebug(self.config.logLevel, @"%@: Received in-app notification from push payload: %@", self, notification);
        
        NSString *jsonString = notification[@"wzrk_inapp"];
        
        NSDictionary *inapp = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                              options:0
                                                                error:nil];
        
        if (inapp) {
            float delay = self.isAppForeground ? 0.5 : 2.0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @try {
                    [self prepareNotificationForDisplay:inapp];
                } @catch (NSException *e) {
                    CJMLogDebug(self.config.logLevel, @"%@: Failed to display the inapp notifcation from payload: %@", self, e.debugDescription);
                }
            });
        } else {
            CJMLogDebug(self.config.logLevel, @"%@: Failed to parse the inapp notification as JSON", self);
            return YES;
        }
        
    } @catch (NSException *e) {
        CJMLogDebug(self.config.logLevel, @"%@: Failed to display the inapp notifcation from payload: %@", self, e.debugDescription);
        return YES;
    }
    
#endif
    return YES;
}

// static display handling as we may have more than one instance competing to show an inapp
+ (void)checkPendingNotifications {
    if (pendingNotificationControllers && [pendingNotificationControllers count] > 0) {
        CJMInAppDisplayViewController *controller = [pendingNotificationControllers objectAtIndex:0];
        [pendingNotificationControllers removeObjectAtIndex:0];
        [self displayInAppDisplayController:controller];
    }
}

+ (void)displayInAppDisplayController:(CJMInAppDisplayViewController*)controller {
    // if we are currently displaying a notification, cache this notification for later display
    if (currentDisplayController) {
        [pendingNotificationControllers addObject:controller];
        return;
    }
    // no current notification so display
    currentDisplayController = controller;
    [controller show:YES];
}

+ (void)inAppDisplayControllerDidDismiss:(CJMInAppDisplayViewController*)controller {
    if (currentDisplayController && currentDisplayController == controller) {
        currentDisplayController = nil;
        [self checkPendingNotifications];
    }
}

- (void)runOnNotificationQueue:(void (^)(void))taskBlock {
    if ([self inNotificationQueue]) {
        taskBlock();
    } else {
        dispatch_async(_notificationQueue, taskBlock);
    }
}

- (BOOL)inNotificationQueue {
    CJM *currentQueue = (__bridge id) dispatch_get_specific(kNotificationQueueKey);
    return currentQueue == self;
}

- (void)_showNotificationIfAvailable {
    if ([[self class] runningInsideAppExtension]) return;
    
    @try {
        NSMutableArray *inapps = [[NSMutableArray alloc] initWithArray:[CJMPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY]]];
        if ([inapps count] < 1) {
            return;
        }
        [self prepareNotificationForDisplay:inapps[0]];
        [inapps removeObjectAtIndex:0];
        [CJMPreferences putObject:inapps forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY]];
    } @catch (NSException *e) {
        CJMLogDebug(self.config.logLevel, @"%@: Problem showing InApp: %@", self, e.debugDescription);
    }
}

- (void)prepareNotificationForDisplay:(NSDictionary*)jsonObj {
    if (!self.isAppForeground) {
        CJMLogInternal(self.config.logLevel, @"%@: Application is not in the foreground, won't prepare in-app: %@", self, jsonObj);
        return;
    }
    
    [self runOnNotificationQueue:^{
        CJMLogInternal(self.config.logLevel, @"%@: processing inapp notification: %@", self, jsonObj);
        __block CJMInAppNotification *notification = [[CJMInAppNotification alloc] initWithJSON:jsonObj];
        if (notification.error) {
            CJMLogInternal(self.config.logLevel, @"%@: unable to parse inapp notification: %@ error: %@", self, jsonObj, notification.error);
            return;
        }
        
        NSTimeInterval now = (int)[[NSDate date] timeIntervalSince1970];
        if (now > notification.timeToLive) {
            CJMLogInternal(self.config.logLevel, @"%@: InApp has elapsed its time to live, not showing the InApp: %@ wzrk_ttl: %lu", self, jsonObj, (unsigned long)notification.timeToLive);
            return;
        }
        
        [notification prepareWithCompletionHandler:^{
            [[self class] runSyncMainQueue:^{
                [self notificationReady:notification];
            }];
        }];
    }];
}

- (void)notificationReady:(CJMInAppNotification*)notification {
    if (![NSThread isMainThread]) {
        [[self class] runSyncMainQueue:^{
            [self notificationReady: notification];
        }];
        return;
    }
    if (notification.error) {
        CJMLogInternal(self.config.logLevel, @"%@: unable to process inapp notification: %@, error: %@ ", self, notification.jsonDescription, notification.error);
        return;
    }
    
    CJMLogInternal(self.config.logLevel, @"%@: InApp prepared for display: %@", self, notification.campaignId);
    [self displayNotification:notification];
}

- (void)displayNotification:(CJMInAppNotification*)notification {
#if !CJM_NO_INAPP_SUPPORT
    if (![NSThread isMainThread]) {
        [[self class] runSyncMainQueue:^{
            [self displayNotification:notification];
        }];
        return;
    }
    
    if (!self.isAppForeground) {
        CJMLogInternal(self.config.logLevel, @"%@: Application is not in the foreground, not displaying in-app: %@", self, notification.jsonDescription);
        return;
    }
    
    if (![self.inAppFCManager canShow:notification]) {
        CJMLogInternal(self.config.logLevel, @"%@: InApp %@ has been rejected by FC, not showing", self, notification.campaignId);
        [self showInAppNotificationIfAny];  // auto try the next one
        return;
    }
    
    BOOL goFromDelegate = YES;
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(shouldShowInAppNotificationWithExtras:)]) {
        goFromDelegate = [self.inAppNotificationDelegate shouldShowInAppNotificationWithExtras:notification.customExtras];
    }
    
    if (!goFromDelegate) {
        CJMLogDebug(self.config.logLevel, @"%@: Application has decided to not show this InApp: %@", self, notification.campaignId ? notification.campaignId : @"<unknown ID>");
        [self showInAppNotificationIfAny];  // auto try the next one
        return;
    }
    
    CJMInAppDisplayViewController *controller;
    NSString *errorString = nil;
    CJMJSInterface *jsInterface = nil;
    
    switch (notification.inAppType) {
        case CJMInAppTypeHTML:
            jsInterface = [[CJMJSInterface alloc] initWithConfig:self.config];
            controller = [[CJMInAppHTMLViewController alloc] initWithNotification:notification jsInterface:jsInterface];
            break;
        case CJMInAppTypeInterstitial:
            controller = [[CJMInterstitialViewController alloc] initWithNotification:notification];
            break;
        case CJMInAppTypeHalfInterstitial:
            controller = [[CJMHalfInterstitialViewController alloc] initWithNotification:notification];
            break;
        case CJMInAppTypeCover:
            controller = [[CJMCoverViewController alloc] initWithNotification:notification];
            break;
        case CJMInAppTypeHeader:
            controller = [[CJMHeaderViewController alloc] initWithNotification:notification];
            break;
        case CJMInAppTypeFooter:
            controller = [[CJMFooterViewController alloc] initWithNotification:notification];
            break;
        case CJMInAppTypeAlert:
            controller = [[CJMAlertViewController alloc] initWithNotification:notification];
            break;
        case CJMInAppTypeInterstitialImage:
            controller = [[CJMInterstitialImageViewController alloc] initWithNotification:notification];
            break;
        case CJMInAppTypeHalfInterstitialImage:
            controller = [[CJMHalfInterstitialImageViewController alloc] initWithNotification:notification];
            break;
        case CJMInAppTypeCoverImage:
            controller = [[CJMCoverImageViewController alloc] initWithNotification:notification];
            break;
        default:
            errorString = [NSString stringWithFormat:@"Unhandled notification type: %lu", (unsigned long)notification.inAppType];
            break;
    }
    if (controller) {
        CJMLogDebug(self.config.logLevel, @"%@: Will show new InApp: %@", self, notification.campaignId);
        controller.delegate = self;
        [[self class] displayInAppDisplayController:controller];
    }
    if (errorString) {
        CJMLogDebug(self.config.logLevel, @"%@: %@", self, errorString);
    }
#endif
}

- (void)clearInApps {
    CJMLogInternal(self.config.logLevel, @"%@: Clearing all pending InApp notifications", self);
    [CJMPreferences putObject:[[NSArray alloc] init] forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY]];
}

- (void)notifyNotificationDismissed:(CJMInAppNotification *)notification {
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDismissedWithExtras:andActionExtras:)]) {
        NSDictionary *extras;
        if (notification.actionExtras && [notification.actionExtras isKindOfClass:[NSDictionary class]]) {
            extras = [NSDictionary dictionaryWithDictionary:notification.actionExtras];
        } else {
            extras = [NSDictionary new];
        }
        [self.inAppNotificationDelegate inAppNotificationDismissedWithExtras:notification.customExtras andActionExtras:extras];
    }
}

- (void)recordInAppNotificationStateEvent:(BOOL)clicked
                          forNotification:(CJMInAppNotification *)notification andQueryParameters:(NSDictionary *)params {
    [self runSerialAsync:^{
        [CJMEventBuilder buildInAppNotificationStateEvent:clicked forNotification:notification andQueryParameters:params completionHandler:^(NSDictionary *event, NSArray<CJMValidationResult*>*errors) {
            if (event) {
                if (clicked) {
                    self.wzrkParams = [event[@"evtData"] copy];
                }
                [self queueEvent:event withType:CJMEventTypeRaised];
            };
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}


#pragma mark - CJMInAppNotificationDisplayDelegate

- (void)notificationDidDismiss:(CJMInAppNotification*)notification fromViewController:(CJMInAppDisplayViewController*)controller {
    CJMLogInternal(self.config.logLevel, @"%@: InApp did dismiss: %@", self, notification.campaignId);
    [self notifyNotificationDismissed:notification];
    [[self class] inAppDisplayControllerDidDismiss:controller];
    [self showInAppNotificationIfAny];
}

- (void)notificationDidShow:(CJMInAppNotification*)notification fromViewController:(CJMInAppDisplayViewController*)controller {
    CJMLogInternal(self.config.logLevel, @"%@: InApp did show: %@", self, notification.campaignId);
    [self recordInAppNotificationStateEvent:NO forNotification:notification andQueryParameters:nil];
    [self.inAppFCManager didShow:notification];
}

- (void)notifyNotificationButtonTappedWithCustomExtras:(NSDictionary *)customExtras {
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationButtonTappedWithCustomExtras:)]) {
        [self.inAppNotificationDelegate inAppNotificationButtonTappedWithCustomExtras:customExtras];
    }
}

- (void)handleNotificationCTA:(NSURL *)ctaURL buttonCustomExtras:(NSDictionary *)buttonCustomExtras forNotification:(CJMInAppNotification*)notification fromViewController:(CJMInAppDisplayViewController*)controller withExtras:(NSDictionary*)extras {
    CJMLogInternal(self.config.logLevel, @"%@: handle InApp cta: %@ button custom extras: %@ with options:%@", self, ctaURL.absoluteString, buttonCustomExtras, extras);
    [self recordInAppNotificationStateEvent:YES forNotification:notification andQueryParameters:extras];
    if (extras) {
        notification.actionExtras = extras;
    }
    if (buttonCustomExtras && buttonCustomExtras.count > 0) {
        CJMLogDebug(self.config.logLevel, @"%@: InApp: button tapped with custom extras: %@", self, buttonCustomExtras);
        [self notifyNotificationButtonTappedWithCustomExtras:buttonCustomExtras];
    } else if (ctaURL) {
        
#if !CJM_NO_INAPP_SUPPORT
        [[self class] runSyncMainQueue:^{
            [self openURL:ctaURL forModule:@"InApp"];
        }];
#endif
    }
    [controller hide:true];
}

- (void)openURL:(NSURL *)ctaURL forModule:(NSString *)module {
    UIApplication *sharedApplication = [[self class] getSharedApplication];
    if (sharedApplication == nil) {
        return;
    }
    CJMLogDebug(self.config.logLevel, @"%@: %@: firing deep link: %@", module, self, ctaURL);
    id dlURL;
    if (@available(iOS 10.0, *)) {
        if ([sharedApplication respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            NSMethodSignature *signature = [UIApplication
                                            instanceMethodSignatureForSelector:@selector(openURL:options:completionHandler:)];
            NSInvocation *invocation = [NSInvocation
                                        invocationWithMethodSignature:signature];
            [invocation setTarget:sharedApplication];
            [invocation setSelector:@selector(openURL:options:completionHandler:)];
            NSDictionary *options = @{};
            id completionHandler = nil;
            dlURL = ctaURL;
            [invocation setArgument:&dlURL atIndex:2];
            [invocation setArgument:&options atIndex:3];
            [invocation setArgument:&completionHandler atIndex:4];
            [invocation invoke];
        } else {
            if ([sharedApplication respondsToSelector:@selector(openURL:)]) {
                [sharedApplication performSelector:@selector(openURL:) withObject:ctaURL];
            }
        }
    } else {
        if ([sharedApplication respondsToSelector:@selector(openURL:)]) {
            [sharedApplication performSelector:@selector(openURL:) withObject:ctaURL];
        }
    }
}

#pragma mark - Serial Queue Operations

- (void)runSerialAsync:(void (^)(void))taskBlock {
    if ([self inSerialQueue]) {
        taskBlock();
    } else {
        dispatch_async(_serialQueue, taskBlock);
    }
}

- (BOOL)inSerialQueue {
    CJM *currentQueue = (__bridge id) dispatch_get_specific(kQueueKey);
    return currentQueue == self;
}


# pragma mark - Event Helpers

- (NSMutableDictionary *)getErrorObject:(CJMValidationResult *)vr {
    NSMutableDictionary *error = [[NSMutableDictionary alloc] init];
    @try {
        error[@"c"] = @([vr errorCode]);
        error[@"d"] = [vr errorDesc];
    } @catch (NSException *e) {
        // Won't reach here
    }
    return error;
}

- (void)recordDeviceErrors {
    for (CJMValidationResult *error in self.deviceInfo.validationErrors) {
        [self pushValidationResult:error];
    }
}


# pragma mark - Additional Request Parameters(ARP) and I/J handling

/**
 * Process additional request parameters (if available) in the response.
 * These parameters are then sent back with the next request as HTTP GET parameters.
 *
 * only used in [self endpoint]
 */

- (void)processAdditionalRequestParameters:(NSDictionary *)response {
    if (!response) return;
    
    NSNumber *i = response[@"_i"];
    if (i != nil) {
        [self saveI:i];
    }
    
    NSNumber *j = response[@"_j"];
    if (j != nil) {
        [self saveJ:j];
    }
    
    NSDictionary *arp = response[@"arp"];
    if (!arp || [arp count] < 1) return;
    
    [self updateARP:arp];
}

- (void)processDiscardedEventsRequest:(NSDictionary *)arp {
    if (!arp) return;
    
    if (!arp[CLTAP_DISCARDED_EVENT_JSON_KEY]) {
        CJMLogInternal(self.config.logLevel, @"%@: ARP doesn't contain the Discarded Events key.", self);
        return;
    }
    
    if (![arp[CLTAP_DISCARDED_EVENT_JSON_KEY] isKindOfClass:[NSArray class]]) {
        CJMLogInternal(self.config.logLevel, @"%@: Error parsing discarded events: %@", self, arp);
        return;
    }
    
    NSArray *discardedEvents = arp[CLTAP_DISCARDED_EVENT_JSON_KEY];
    if (discardedEvents && discardedEvents.count > 0) {
        @try {
            [CJMValidator setDiscardedEvents:discardedEvents];
        } @catch (NSException *e) {
            CJMLogInternal(self.config.logLevel, @"%@: Error parsing discarded events list: %@", self, e.debugDescription);
        }
    }
}

- (NSString *)arpKey {
    NSString *accountId = self.config.accountId;
    NSString *guid = self.deviceInfo.deviceId;
    if (accountId == nil || guid == nil) {
        return nil;
    }
    return [NSString stringWithFormat:@"arp:%@:%@", accountId, guid];
}

- (NSDictionary *)getARP {
    [self migrateARPKeysForLocalStorage];
    NSString *key = [self arpKey];
    if (!key) return nil;
    NSDictionary *arp = [CJMPreferences getObjectForKey:key];
    CJMLogInternal(self.config.logLevel, @"%@: Getting ARP: %@ for key: %@", self, arp, key);
    return arp;
}

- (void)saveARP:(NSDictionary *)arp {
    NSString *key = [self arpKey];
    if (!key) return;
    CJMLogInternal(self.config.logLevel, @"%@: Saving ARP: %@ for key: %@", self, arp, key);
    [CJMPreferences putObject:arp forKey:key];
}

- (void)updateARP:(NSDictionary *)arp {
    NSMutableDictionary *update;
    NSDictionary *staleARP = [self getARP];
    if (staleARP) {
        update = [staleARP mutableCopy];
    } else {
        update = [[NSMutableDictionary alloc] init];
    }
    [update addEntriesFromDictionary:arp];
    
    // Remove any keys that have the value -1
    NSArray *keys = [update allKeys];
    for (NSUInteger i = 0; i < [keys count]; i++) {
        id value = update[keys[i]];
        if ([value isKindOfClass:[NSNumber class]] && ((NSNumber *) value).intValue == -1) {
            [update removeObjectForKey:keys[i]];
            CJMLogInternal(self.config.logLevel, @"%@: Purged key %@ from future additional request parameters", self, keys[i]);
        }
    }
    [self saveARP:update];
    [self processDiscardedEventsRequest:arp];
    [self.productConfig updateProductConfigWithOptions:[self _setProductConfig:arp]];
}

- (void)migrateARPKeysForLocalStorage {
    //Fetch latest key which is updated in the new method we are using the old key structure below
    NSString *accountId = self.config.accountId;
    if (accountId == nil) {
        return;
    }
    NSString *key = [NSString stringWithFormat:@"arp:%@", accountId];
    NSDictionary *arp = [CJMPreferences getObjectForKey:key];
    
    //Set ARP value in new key and delete the value for old key
    if (arp != nil) {
        [self saveARP:arp];
        [CJMPreferences removeObjectForKey:key];
    }
}

- (long)getI {
    return [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kI_KEY] withResetValue:0];
}

- (void)saveI:(NSNumber *)i {
    [CJMPreferences putInt:[i longValue] forKey:[self storageKeyWithSuffix:kI_KEY]];
}

- (void)clearI {
    [CJMPreferences removeObjectForKey:[self storageKeyWithSuffix:kI_KEY]];
}

- (long)getJ {
    return [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kJ_KEY] withResetValue:0];
}

- (void)saveJ:(NSNumber *)j {
    [CJMPreferences putInt:[j longValue] forKey:[self storageKeyWithSuffix:kJ_KEY]];
}

- (void)clearJ {
    [CJMPreferences removeObjectForKey:[self storageKeyWithSuffix:kJ_KEY]];
}

- (void)clearUserContext {
    [self clearI];
    [self clearJ];
    [self clearLastRequestTimestamp];
    [self clearFirstRequestTimestamp];
}


#pragma mark - Session and Related Handling

- (void)createSessionIfNeeded {
    if ([[self class] runningInsideAppExtension] || [self inCurrentSession]) {
        return;
    }
    [self resetSession];
    [self createSession];
}

- (void)updateSessionStateOnLaunch {
    if (![self inCurrentSession]) {
        [self resetSession];
        [self createSession];
        return;
    }
    CJMLogInternal(self.config.logLevel, @"%@: have current session: %lu", self, self.sessionId);
    long now = (long) [[NSDate date] timeIntervalSince1970];
    if (![self isSessionTimedOut:now]) {
        [self updateSessionTime:now];
        return;
    }
    CJMLogInternal(self.config.logLevel, @"%@: Session timeout reached", self);
    [self resetSession];
    [self createSession];
}

- (BOOL)inCurrentSession {
    return self.sessionId > 0;
}

- (BOOL)isSessionTimedOut:(long)currentTS {
    long lastSessionTime = [self lastSessionTime];
    return (lastSessionTime > 0 && (currentTS - lastSessionTime > self.minSessionSeconds));
}

- (long)lastSessionTime {
    return (long)[CJMPreferences getIntForKey:[self storageKeyWithSuffix:kLastSessionTime] withResetValue:0];
}

- (void)updateSessionTime:(long)ts {
    if (![self inCurrentSession]) return;
    CJMLogInternal(self.config.logLevel, @"%@: updating session time: %lu", self, ts);
    [CJMPreferences putInt:ts forKey:[self storageKeyWithSuffix:kLastSessionTime]];
}

- (void)createFirstRequestInSession {
    self.firstRequestInSession = YES;
    [CJMValidator setDiscardedEvents:nil];
}

- (void)resetSession {
    if ([[self class] runningInsideAppExtension]) return;
    self.appLaunchProcessed = NO;
    long lastSessionID = 0;
    long lastSessionEnd = 0;
    if (self.config.isDefaultInstance) {
        lastSessionID = [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kSessionId] withResetValue:[CJMPreferences getIntForKey:kSessionId withResetValue:0]];
        lastSessionEnd = [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kLastSessionTime] withResetValue:[CJMPreferences getIntForKey:kLastSessionPing withResetValue:0]];
    } else {
        lastSessionID = [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kSessionId] withResetValue:0];
        lastSessionEnd = [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kLastSessionTime] withResetValue:0];
    }
    self.lastSessionLengthSeconds = (lastSessionID > 0 && lastSessionEnd > 0) ? (int)(lastSessionEnd - lastSessionID) : 0;
    self.sessionId = 0;
    [self updateSessionTime:0];
    [CJMPreferences removeObjectForKey:kSessionId];
    [CJMPreferences removeObjectForKey:[self storageKeyWithSuffix:kSessionId]];
    self.screenCount = 1;
    [self clearSource];
    [self clearMedium];
    [self clearCampaign];
    [self clearWzrkParams];
#if !CJM_NO_INAPP_SUPPORT
    if (![[self class] runningInsideAppExtension]) {
        [self.inAppFCManager resetSession];
    }
#endif
}

- (void)setSessionId:(long)sessionId {
    _sessionId = sessionId;
    [CJMPreferences putInt:self.sessionId forKey:[self storageKeyWithSuffix:kSessionId]];
}

- (long)sessionId {
    return _sessionId;
}

- (void)createSession {
    self.sessionId = (long) [[NSDate date] timeIntervalSince1970];
    [self updateSessionTime:self.sessionId];
    [self createFirstRequestInSession];
    if (self.config.isDefaultInstance) {
        self.firstSession = [CJMPreferences getIntForKey:[self storageKeyWithSuffix:@"firstTime"] withResetValue:[CJMPreferences getIntForKey:@"firstTime" withResetValue:0]] == 0;
    } else {
        self.firstSession = [CJMPreferences getIntForKey:[self storageKeyWithSuffix:@"firstTime"] withResetValue:0] == 0;
    }
    [CJMPreferences putInt:1 forKey:[self storageKeyWithSuffix:@"firstTime"]];
    CJMLogInternal(self.config.logLevel, @"%@: session created with ID: %lu", self, self.sessionId);
    CJMLogInternal(self.config.logLevel, @"%@: previous session length: %d seconds", self, self.lastSessionLengthSeconds);
#if !CJM_NO_INAPP_SUPPORT
    if (![[self class] runningInsideAppExtension]) {
        [self clearInApps];
    }
#endif
}

- (void)setFirstRequestInSession:(BOOL)firstRequestInSession {
    _firstRequestInSession = firstRequestInSession;
}

- (BOOL)firstRequestInSession {
    return _firstRequestInSession;
}

- (NSString*)source {
    return _source;
}
// only set if not already set for this session
- (void)setSource:(NSString *)source {
    if (_source == nil) {
        _source = source;
    }
}
- (void)clearSource {
    _source = nil;
}

- (NSString*)medium{
    return _medium;
}
// only set them if not already set during the session
- (void)setMedium:(NSString *)medium {
    if (_medium == nil) {
        _medium = medium;
    }
}
- (void)clearMedium {
    _medium = nil;
}

- (NSString*)campaign {
    return _campaign;
}
// only set them if not already set during the session
- (void)setCampaign:(NSString *)campaign {
    if (_campaign == nil) {
        _campaign = campaign;
    }
}
- (void)clearCampaign {
    _campaign = nil;
}

- (NSDictionary*)wzrkParams{
    return _wzrkParams;
}
// only set them if not already set during the session
- (void)setWzrkParams:(NSDictionary *)params {
    if (_wzrkParams == nil) {
        _wzrkParams = params;
    }
}
- (void)clearWzrkParams {
    _wzrkParams = nil;
}

#pragma mark - Queues/Persistence/Dispatch Handling

- (BOOL)shouldDeferProcessingEvent: (NSDictionary *)event withType:(CJMEventType)type {
    
    if (self.config.isCreatedPostAppLaunched){
        return NO;
    }
    
    return (type == CJMEventTypeRaised && !self.appLaunchProcessed);
}

- (BOOL)_shouldDropEvent:(NSDictionary *)event withType:(CJMEventType)type {
    
    if (type == CJMEventTypeFetch) {
        return NO;
    }
    
    if (self.currentUserOptedOut) {
        CJMLogDebug(self.config.logLevel, @"%@: User: %@ has opted out of sending events, dropping event: %@", self, self.deviceInfo.deviceId, event);
        return YES;
    }
    
    if ([self isMuted]) {
        CJMLogDebug(self.config.logLevel, @"%@: is muted, dropping event: %@", self, event);
        return YES;
    }
    
    return NO;
}

- (void)queueEvent:(NSDictionary *)event withType:(CJMEventType)type {
    if ([self _shouldDropEvent:event withType:type]) {
        return;
    }
    
    // make sure App Launched is processed first
    // if not defer this one; push back on the queue
    if ([self shouldDeferProcessingEvent:event withType:type]) {
        CJMLogDebug(self.config.logLevel, @"%@: App Launched not yet processed re-queueing: %@, %lu", self, event, (long)type);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self runSerialAsync:^{
                [self queueEvent:event withType:type];
            }];
        });
        return;
    }
    
    if (type == CJMEventTypeFetch) {
        [self runSerialAsync:^{
            [self processEvent:event withType:type];
        }];
    } else {
        [self createSessionIfNeeded];
        [self pushInitialEventsIfNeeded];
        [self runSerialAsync:^{
            [self updateSessionTime:(long) [[NSDate date] timeIntervalSince1970]];
            [self processEvent:event withType:type];
        }];
    }
}

- (void)processEvent:(NSDictionary *)event withType:(CJMEventType)eventType {
    @try {
        // just belt and suspenders
        if ([self isMuted]) {
            [self flushQueue];  //this will clear the queues when in a muted state
            return;
        }
        NSMutableDictionary *mutableEvent = [NSMutableDictionary dictionaryWithDictionary:event];
        
        if (!self.config.accountId || !self.config.accountToken) {
            CJMLogInternal(self.config.logLevel, @"%@: Account ID/token not found, will not add to queue", self);
            return;
        }
        
        // ignore pings if queue is not draining
        if ([self.eventsQueue count] >= 50 && (eventType == CJMEventTypePing || eventType == CJMEventTypeFetch)) {
            CJMLogInternal(self.config.logLevel, @"%@: Events queue not draining, ignoring ping and fetch events", self);
            return;
        }
        
        if (eventType != CJMEventTypeRaised || eventType != CJMEventTypeNotificationViewed) {
            event = [self convertDataToPrimitive:event];
        }
        
        NSString *type;
        if (eventType == CJMEventTypePage) {
            type = @"page";
        } else if (eventType == CJMEventTypePing) {
            type = @"ping";
        } else if (eventType == CJMEventTypeProfile) {
            type = @"profile";
        } else if (eventType == CJMEventTypeData) {
            type = @"data";
        } else if (eventType == CJMEventTypeNotificationViewed) {
            type = @"event";
            NSString *bundleIdentifier = _deviceInfo.bundleId;
            if (bundleIdentifier) {
                mutableEvent[@"pai"] = bundleIdentifier;
            }
        } else {
            type = @"event";
            NSString *bundleIdentifier = _deviceInfo.bundleId;
            if (bundleIdentifier) {
                mutableEvent[@"pai"] = bundleIdentifier;
            }
        }
        mutableEvent[@"type"] = type;
        mutableEvent[@"ep"] = @((int) [[NSDate date] timeIntervalSince1970]);
        mutableEvent[@"s"] = @(self.sessionId);
        int screenCount = self.screenCount == 0 ? 1 : self.screenCount;
        mutableEvent[@"pg"] = @(screenCount);
        mutableEvent[@"lsl"] = @(self.lastSessionLengthSeconds);
        mutableEvent[@"f"] = @(self.firstSession);
        mutableEvent[@"n"] = self.currentViewControllerName ? self.currentViewControllerName : @"_bg";
        
        if (eventType == CJMEventTypePing && _geofenceLocation) {
            mutableEvent[@"gf"] = @(_geofenceLocation);
            mutableEvent[@"gfSDKVersion"] = _gfSDKVersion;
            _geofenceLocation = NO;
        }
        
        // Report any pending validation error
        CJMValidationResult *vr = [self popValidationResult];
        if (vr != nil) {
            mutableEvent[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
        }
        
        if (self.config.enablePersonalization) {
            [self.localDataStore addDataSyncFlag:mutableEvent];
        }
        
        if (eventType == CJMEventTypeRaised || eventType == CJMEventTypeNotificationViewed) {
            [self.localDataStore persistEvent:mutableEvent];
        }
        
        if (eventType == CJMEventTypeProfile) {
            [self.profileQueue addObject:mutableEvent];
            if ([self.profileQueue count] > 500) {
                [self.profileQueue removeObjectAtIndex:0];
            }
        } else if (eventType == CJMEventTypeNotificationViewed) {
            [self.notificationsQueue addObject:mutableEvent];
            if ([self.notificationsQueue count] > 100) {
                [self.notificationsQueue removeObjectAtIndex:0];
            }
        } else {
            [self.eventsQueue addObject:mutableEvent];
            if ([self.eventsQueue count] > 500) {
                [self.eventsQueue removeObjectAtIndex:0];
            }
        }
        
        CJMLogDebug(self.config.logLevel, @"%@: New event processed: %@", self, [self jsonObjectToString:mutableEvent]);
        
        if (eventType == CJMEventTypeFetch) {
            [self flushQueue];
        } else {
            [self scheduleQueueFlush];
        }
        
    } @catch (NSException *e) {
        CJMLogDebug(self.config.logLevel, @"%@: Processing event failed with a exception: %@", self, e.debugDescription);
    }
}
- (void)scheduleQueueFlush {
    CJMLogInternal(self.config.logLevel, @"%@: scheduling delayed queue flush", self);
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(flushQueue) object:nil];
        [self performSelector:@selector(flushQueue) withObject:nil afterDelay:CLTAP_PUSH_DELAY_SECONDS];
    });
}

- (void)flushQueue {
    if ([self needHandshake]) {
        [self runSerialAsync:^{
            [self doHandshakeAsync];
        }];
    }
    [self runSerialAsync:^{
        if ([self isMuted]) {
            [self clearQueues];
        } else {
            [self sendQueues];
        }
    }];
}

- (void)clearQueue {
    [self runSerialAsync:^{
        [self sendQueues];
        [self clearQueues];
    }];
}

- (void)sendQueues {
    if ([self isMuted] || _offline) return;
    [self sendQueue:_profileQueue];
    [self sendQueue:_eventsQueue];
    [self sendQueue:_notificationsQueue];
//    [[CJMManager sharedInstance] flushQueue];
}

- (void)inflateQueuesAsync {
    [self runSerialAsync:^{
        [self inflateProfileQueue];
        [self inflateEventsQueue];
        [self inflateNotificationsQueue];
//        [[CJMManager sharedInstance] inflateEventsQueue];
    }];
}

- (void)inflateEventsQueue {
    self.eventsQueue = (NSMutableArray *)[CJMPreferences unarchiveFromFile:[self eventsFileName] removeFile:YES];
    if (!self.eventsQueue || [self isMuted]) {
        self.eventsQueue = [NSMutableArray array];
    }
}

- (void)inflateProfileQueue {
    self.profileQueue = (NSMutableArray *)[CJMPreferences unarchiveFromFile:[self profileEventsFileName] removeFile:YES];
    if (!self.profileQueue || [self isMuted]) {
        self.profileQueue = [NSMutableArray array];
    }
}

- (void)inflateNotificationsQueue {
    self.notificationsQueue = (NSMutableArray *)[CJMPreferences unarchiveFromFile:[self notificationsFileName] removeFile:YES];
    if (!self.notificationsQueue || [self isMuted]) {
        self.notificationsQueue = [NSMutableArray array];
    }
}

- (void)clearQueues {
    [self clearProfileQueue];
    [self clearEventsQueue];
    [self clearNotificationsQueue];
//    [[CJMManager sharedInstance] clearQueue];
}

- (void)clearEventsQueue {
    self.eventsQueue = (NSMutableArray *)[CJMPreferences unarchiveFromFile:[self eventsFileName] removeFile:YES];
    self.eventsQueue = [NSMutableArray array];
}

- (void)clearProfileQueue {
    self.profileQueue = (NSMutableArray *)[CJMPreferences unarchiveFromFile:[self profileEventsFileName] removeFile:YES];
    self.profileQueue = [NSMutableArray array];
}

- (void)clearNotificationsQueue {
    self.notificationsQueue = (NSMutableArray *)[CJMPreferences unarchiveFromFile:[self notificationsFileName] removeFile:YES];
    self.notificationsQueue = [NSMutableArray array];
}

- (void)persistQueues {
    [self runSerialAsync:^{
        if ([self isMuted]) {
            [self clearQueues];
        } else {
            [self persistProfileQueue];
            [self persistEventsQueue];
            [self persistNotificationsQueue];
//            [[CJMManager sharedInstance] persistEventsQueue];
        }
    }];
}

- (void)persistEventsQueue {
    NSString *fileName = [self eventsFileName];
    NSMutableArray *eventsCopy;
    @synchronized (self) {
        eventsCopy = [NSMutableArray arrayWithArray:[self.eventsQueue copy]];
    }
    [CJMPreferences archiveObject:eventsCopy forFileName:fileName];
}

- (void)persistProfileQueue {
    NSString *fileName = [self profileEventsFileName];
    NSMutableArray *profileEventsCopy;
    @synchronized (self) {
        profileEventsCopy = [NSMutableArray arrayWithArray:[self.profileQueue copy]];
    }
    [CJMPreferences archiveObject:profileEventsCopy forFileName:fileName];
}

- (void)persistNotificationsQueue {
    NSString *fileName = [self notificationsFileName];
    NSMutableArray *notificationsCopy;
    @synchronized (self) {
        notificationsCopy = [NSMutableArray arrayWithArray:[self.notificationsQueue copy]];
    }
    [CJMPreferences archiveObject:notificationsCopy forFileName:fileName];
}

- (NSString *)fileNameForQueue:(NSString *)queueName {
    return [NSString stringWithFormat:@"clevertap-%@-%@.plist", self.config.accountId, queueName];
}

- (NSString *)eventsFileName {
    return [self fileNameForQueue:kQUEUE_NAME_EVENTS];
}

- (NSString *)profileEventsFileName {
    return [self fileNameForQueue:kQUEUE_NAME_PROFILE];
}

- (NSString *)notificationsFileName {
    return [self fileNameForQueue:kQUEUE_NAME_NOTIFICATIONS];
}


#pragma mark - Validation Error Handling

- (void)pushValidationResults:(NSArray<CJMValidationResult *> * _Nonnull )results {
    for (CJMValidationResult *vr in results) {
        [self pushValidationResult:vr];
    }
}

- (void)pushValidationResult:(CJMValidationResult *)vr {
    [self.pendingValidationResults addObject:vr];
    if (self.pendingValidationResults && [self.pendingValidationResults count] > 50) {
        [self.pendingValidationResults removeObjectAtIndex:0];
    }
}

- (CJMValidationResult *)popValidationResult {
    CJMValidationResult *vr = nil;
    if (self.pendingValidationResults && [self.pendingValidationResults count] > 0) {
        vr = self.pendingValidationResults[0];
        [self.pendingValidationResults removeObjectAtIndex:0];
    }
    return vr;
}


# pragma mark - Request/Response handling

- (void)sendQueue:(NSMutableArray *)queue {
    if (queue == nil || ((int) [queue count]) <= 0) {
        CJMLogInternal(self.config.logLevel, @"%@: No events in the queue", self);
        return;
    }
    // just belt and suspenders here, should never get here in muted state
    if ([self isMuted]) {
        CJMLogInternal(self.config.logLevel, @"%@: is muted won't send queue", self);
        return;
    }
    
    NSString *endpoint = [self endpointForQueue:queue];
    
    if (endpoint == nil) {
        CJMLogDebug(self.config.logLevel, @"%@: Endpoint is not set, will not start sending queue", self);
        return;
    }
    
    NSDictionary *header = [self batchHeader];
    int originalCount = (int) [queue count];
    float numBatches = (float) ceil((float) originalCount / kMaxBatchSize);
    CJMLogDebug(self.config.logLevel, @"%@: Pending events to be sent: %d in %d batches", self, originalCount, (int) numBatches);
    
    while ([queue count] > 0) {
        NSUInteger batchSize = ([queue count] > kMaxBatchSize) ? kMaxBatchSize : [queue count];
        NSArray *batch = [queue subarrayWithRange:NSMakeRange(0, batchSize)];
        NSArray *batchWithHeader = [self insertHeader:header inBatch:batch];
        
        CJMLogInternal(self.config.logLevel, @"%@: Pending events batch contains: %d items", self, (int) [batch count]);
        
        @try {
            
            NSDictionary * body = [[CJMManager sharedInstance] addCJMBodyData:batchWithHeader header: header];
            
            NSString *jsonBody = [self jsonObjectToString:body];
            
            CJMLogDebug(self.config.logLevel, @"%@: Sending %@ to CleverTap servers at %@", self, jsonBody, endpoint);
            
            // update endpoint for current timestamp
            endpoint = [self endpointForQueue:queue];
            if (endpoint == nil) {
                CJMLogInternal(self.config.logLevel, @"%@: Endpoint is not set, won't send queue", self);
                return;
            }
            
            NSMutableURLRequest *request = [self createURLRequestFromURL:[[NSURL alloc] initWithString:endpoint]];
            request.HTTPBody = [jsonBody dataUsingEncoding:NSUTF8StringEncoding];
            request.HTTPMethod = @"POST";
            
            //forward CJM
            NSMutableURLRequest *requestForward = [[CJMManager sharedInstance] forwardRequestCJM:request];
            
            __block BOOL success = NO;
            __block NSData *responseData;
            
            __block BOOL redirect = NO;
            
            // Need to simulate a synchronous request
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            NSURLSessionDataTask *postDataTask = [self.urlSession
                                                  dataTaskWithRequest:requestForward
                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                responseData = data;
                
                if (error) {
                    CJMLogDebug(self.config.logLevel, @"%@: Network error while sending queue, will retry: %@", self, error.localizedDescription);
                }
                
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    
                    success = (httpResponse.statusCode == 200);
                    
                    if (success) {
                        if (queue == self->_notificationsQueue) {
                            redirect = [self updateStateFromResponseHeadersShouldRedirectForNotif: httpResponse.allHeaderFields];
                        } else {
                            redirect = [self updateStateFromResponseHeadersShouldRedirect: httpResponse.allHeaderFields];
                        }
                        
                    } else {
                        CJMLogDebug(self.config.logLevel, @"%@: Got %lu response when sending queue, will retry", self, (long)httpResponse.statusCode);
                    }
                }
                
                dispatch_semaphore_signal(semaphore);
            }];
            [postDataTask resume];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            if (!success) {
                [self scheduleQueueFlush];
                [self handleSendQueueFail];
            }
            
            if (!success || redirect) {
                // error so return without removing events from the queue or parsing the response
                // Note: in an APP Extension we don't persist any unsent queues
                return;
            }
            
            [queue removeObjectsInArray:batch];
            
            [self parseResponse:responseData];
            
            CJMLogDebug(self.config.logLevel,@"%@: Successfully sent %lu events", self, (unsigned long)[batch count]);
            
        } @catch (NSException *e) {
            CJMLogDebug(self.config.logLevel, @"%@: An error occurred while sending the queue: %@", self, e.debugDescription);
            break;
        }
    }
}


#pragma mark Response Handling

- (void)parseResponse:(NSData *)responseData {
    if (responseData) {
        @try {
            id jsonResp = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
            CJMLogInternal(self.config.logLevel, @"%@: Response: %@", self, jsonResp);
            
            if (jsonResp && [jsonResp isKindOfClass:[NSDictionary class]]) {
                NSString *upstreamGUID = [jsonResp objectForKey:@"g"];
                
                if (upstreamGUID && ![upstreamGUID isEqualToString:@""]) {
                    [self.deviceInfo forceUpdateDeviceID:upstreamGUID];
                    CJMLogInternal(self.config.logLevel, @"%@: Upstream updated the GUID to %@", self, upstreamGUID);
                }
                
#if !CJM_NO_INAPP_SUPPORT
                if (!self.config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
                    NSNumber *perSession = jsonResp[@"imc"];
                    if (perSession == nil) {
                        perSession = @10;
                    }
                    NSNumber *perDay = jsonResp[@"imp"];
                    if (perDay == nil) {
                        perDay = @10;
                    }
                    [self.inAppFCManager updateLimitsPerDay:perDay.intValue andPerSession:perSession.intValue];
                    
                    NSArray *inappsJSON = jsonResp[CLTAP_INAPP_JSON_RESPONSE_KEY];
                    if (inappsJSON) {
                        NSMutableArray *inappNotifs;
                        @try {
                            inappNotifs = [[NSMutableArray alloc] initWithArray:inappsJSON];
                        } @catch (NSException *e) {
                            CJMLogInternal(self.config.logLevel, @"%@: Error parsing InApps JSON: %@", self, e.debugDescription);
                        }
                        
                        // Add all the new notifications to the queue
                        if (inappNotifs && [inappNotifs count] > 0) {
                            CJMLogInternal(self.config.logLevel, @"%@: Processing new InApps: %@", self, inappNotifs);
                            @try {
                                NSMutableArray *inapps = [[NSMutableArray alloc] initWithArray:[CJMPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY]]];
                                for (int i = 0; i < [inappNotifs count]; i++) {
                                    @try {
                                        NSMutableDictionary *inappNotif = [[NSMutableDictionary alloc] initWithDictionary:inappNotifs[(NSUInteger) i]];
                                        [inapps addObject:inappNotif];
                                    } @catch (NSException *e) {
                                        CJMLogInternal(self.config.logLevel, @"%@: Malformed InApp notification", self);
                                    }
                                }
                                // Commit all the changes
                                [CJMPreferences putObject:inapps forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY]];
                                
                                // Fire the first notification, if any
                                [self runOnNotificationQueue:^{
                                    [self _showNotificationIfAvailable];
                                }];
                            } @catch (NSException *e) {
                                CJMLogInternal(self.config.logLevel, @"%@: InApp notification handling error: %@", self, e.debugDescription);
                            }
                            // Handle inapp_stale
                            @try {
                                [self.inAppFCManager processResponse:jsonResp];
                            } @catch (NSException *ex) {
                                CJMLogInternal(self.config.logLevel, @"%@: Failed to handle inapp_stale update: %@", self, ex.debugDescription)
                            }
                        }
                    }
                }
#endif
                
#if !CJM_NO_INBOX_SUPPORT
                NSArray *inboxJSON = jsonResp[CLTAP_INBOX_MSG_JSON_RESPONSE_KEY];
                if (inboxJSON) {
                    NSMutableArray *inboxNotifs;
                    @try {
                        inboxNotifs = [[NSMutableArray alloc] initWithArray:inboxJSON];
                    } @catch (NSException *e) {
                        CJMLogInternal(self.config.logLevel, @"%@: Error parsing Inbox Message JSON: %@", self, e.debugDescription);
                    }
                    if (inboxNotifs && [inboxNotifs count] > 0) {
                        [self initializeInboxWithCallback:^(BOOL success) {
                            if (success) {
                                [self runSerialAsync:^{
                                    NSArray <NSDictionary*> *messages =  [inboxNotifs mutableCopy];;
                                    [self.inboxController updateMessages:messages];
                                }];
                            }
                        }];
                    }
                }
#endif
                
#if !CJM_NO_AB_SUPPORT
                if (!self.config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
                    NSArray *experimentsJSON = jsonResp[CLTAP_AB_EXP_JSON_RESPONSE_KEY];
                    if (experimentsJSON) {
                        NSMutableArray *experiments;
                        @try {
                            experiments = [[NSMutableArray alloc] initWithArray:experimentsJSON];
                        } @catch (NSException *e) {
                            CJMLogInternal(self.config.logLevel, @"%@: Error parsing AB Experiments JSON: %@", self, e.debugDescription);
                        }
                        if (experiments && self.abTestController) {
                            [self.abTestController updateExperiments:experiments];
                        }
                    }
                }
#endif
                
#if !CJM_NO_DISPLAY_UNIT_SUPPORT
                NSArray *displayUnitJSON = jsonResp[CLTAP_DISPLAY_UNIT_JSON_RESPONSE_KEY];
                if (displayUnitJSON) {
                    NSMutableArray *displayUnitNotifs;
                    @try {
                        displayUnitNotifs = [[NSMutableArray alloc] initWithArray:displayUnitJSON];
                    } @catch (NSException *e) {
                        CJMLogInternal(self.config.logLevel, @"%@: Error parsing Display Unit JSON: %@", self, e.debugDescription);
                    }
                    if (displayUnitNotifs && [displayUnitNotifs count] > 0) {
                        [self initializeDisplayUnitWithCallback:^(BOOL success) {
                            if (success) {
                                NSArray <NSDictionary*> *displayUnits = [displayUnitNotifs mutableCopy];
                                [self.displayUnitController updateDisplayUnits:displayUnits];
                            }
                        }];
                    }
                }
#endif
                NSDictionary *featureFlagsJSON = jsonResp[CLTAP_FEATURE_FLAGS_JSON_RESPONSE_KEY];
                if (featureFlagsJSON) {
                    NSMutableArray *featureFlagsNotifs;
                    @try {
                        featureFlagsNotifs = [[NSMutableArray alloc] initWithArray:featureFlagsJSON[@"kv"]];
                    } @catch (NSException *e) {
                        CJMLogInternal(self.config.logLevel, @"%@: Error parsing Feature Flags JSON: %@", self, e.debugDescription);
                    }
                    if (featureFlagsNotifs && self.featureFlagsController) {
                        NSArray <NSDictionary*> *featureFlags =  [featureFlagsNotifs mutableCopy];
                        [self.featureFlagsController updateFeatureFlags:featureFlags];
                    }
                }
                
                NSDictionary *productConfigJSON = jsonResp[CLTAP_PRODUCT_CONFIG_JSON_RESPONSE_KEY];
                if (productConfigJSON) {
                    NSMutableArray *productConfigNotifs;
                    @try {
                        productConfigNotifs = [[NSMutableArray alloc] initWithArray:productConfigJSON[@"kv"]];
                    } @catch (NSException *e) {
                        CJMLogInternal(self.config.logLevel, @"%@: Error parsing Product Config JSON: %@", self, e.debugDescription);
                    }
                    if (productConfigNotifs && self.productConfigController) {
                        NSArray <NSDictionary*> *productConfig =  [productConfigNotifs mutableCopy];
                        [self.productConfigController updateProductConfig:productConfig];
                        NSString *lastFetchTs = productConfigJSON[@"ts"];
                        [self.productConfig updateProductConfigWithLastFetchTs:(long) [lastFetchTs longLongValue]];
                    }
                }
                
#if !CJM_NO_GEOFENCE_SUPPORT
                NSArray *geofencesJSON = jsonResp[CLTAP_GEOFENCES_JSON_RESPONSE_KEY];
                if (geofencesJSON) {
                    NSMutableArray *geofencesList;
                    @try {
                        geofencesList = [[NSMutableArray alloc] initWithArray:geofencesJSON];
                    } @catch (NSException *e) {
                        CJMLogInternal(self.config.logLevel, @"%@: Error parsing Geofences JSON: %@", self, e.debugDescription);
                    }
                    if (geofencesList) {
                        NSMutableDictionary *geofencesDict = [NSMutableDictionary new];
                        geofencesDict[@"geofences"] = geofencesList;
                        [[self class] runSyncMainQueue: ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:CJMGeofencesDidUpdateNotification object:nil userInfo:geofencesDict];
                        }];
                    }
                }
#endif
                
                // Handle events/profiles sync data
                @try {
                    NSDictionary *evpr = jsonResp[@"evpr"];
                    if (evpr) {
                        NSDictionary *updates = [self.localDataStore syncWithRemoteData:evpr];
                        if (updates) {
                            if (self.syncDelegate && [self.syncDelegate respondsToSelector:@selector(profileDataUpdated:)]) {
                                [self.syncDelegate profileDataUpdated:updates];
                            }
                            [[NSNotificationCenter defaultCenter] postNotificationName:CJMProfileDidChangeNotification object:nil userInfo:updates];
                        }
                    }
                } @catch (NSException *e) {
                    CJMLogInternal(self.config.logLevel, @"%@: Failed to process profile data updates: %@", self, e.debugDescription);
                }
                
                // Handle console
                @try {
                    NSArray *consoleMessages = jsonResp[@"console"];
                    if (consoleMessages && [consoleMessages count] > 0) {
                        for (NSUInteger i = 0; i < [consoleMessages count]; ++i) {
                            CJMLogDebug(self.config.logLevel, @"%@", consoleMessages[i]);
                        }
                    }
                } @catch (NSException *ex) {
                    // no-op
                }
                
                // Handle arp
                @try {
                    [self processAdditionalRequestParameters:jsonResp];
                } @catch (NSException *ex) {
                    CJMLogInternal(self.config.logLevel, @"%@: Failed to handle ARP update: %@", self, ex.debugDescription)
                }
                
                // Handle dbg_lvl
                @try {
                    if (jsonResp[@"dbg_lvl"] && [jsonResp[@"dbg_lvl"] isKindOfClass:[NSNumber class]]) {
                        [[self class] setDebugLevel:((NSNumber *) jsonResp[@"dbg_lvl"]).intValue];
                        CJMLogDebug(self.config.logLevel, @"%@: Debug level set to %@ (set by upstream)", self, jsonResp[@"dbg_lvl"]);
                    }
                } @catch (NSException *ex) {
                    CJMLogInternal(self.config.logLevel, @"%@: Failed to set debug level: %@", self, ex.debugDescription);
                }
                
                // good time to make sure we have persisted the local profile if needed
                [self.localDataStore persistLocalProfileIfRequired];
                
                CJMLogInternal(self.config.logLevel, @"%@: parseResponse completed successfully", self);
                
                [self handleSendQueueSuccess];
                
            } else {
                CJMLogInternal(self.config.logLevel, @"%@: either the JSON response was nil or it wasn't of type NSDictionary", self);
                [self handleSendQueueFail];
            }
        }
        @catch (NSException *e) {
            CJMLogInternal(self.config.logLevel, @"%@: Failed to parse the response as a JSON object. Reason: %@", self, e.debugDescription);
            [self handleSendQueueFail];
        }
    } else {
        CJMLogInternal(self.config.logLevel, @"%@: Expected a JSON object as the response, but received none", self);
        [self handleSendQueueFail];
    }
}


#pragma mark Profile Handling Private

- (NSString*)_optOutKey {
    NSString *currentGUID = self.deviceInfo.deviceId;
    return  currentGUID ? [NSString stringWithFormat:@"%@:OptOut:%@", self.config.accountId, currentGUID] : nil;
}

- (NSString*)_legacyOptOutKey {
    NSString *currentGUID = self.deviceInfo.deviceId;
    return  currentGUID ? [NSString stringWithFormat:@"OptOut:%@", currentGUID] : nil;
}

- (void)_setCurrentUserOptOutStateFromStorage {
    NSString *legacyKey = [self _legacyOptOutKey];
    NSString *key = [self _optOutKey];
    if (!key) {
        CJMLogInternal(self.config.logLevel, @"Unable to set user optOut state from storage: storage key is nil");
        return;
    }
    BOOL optedOut = NO;
    if (self.config.isDefaultInstance) {
        optedOut = (BOOL) [CJMPreferences getIntForKey:key withResetValue:[CJMPreferences getIntForKey:legacyKey withResetValue:NO]];
    } else {
        optedOut = (BOOL) [CJMPreferences getIntForKey:key withResetValue:NO];
    }
    CJMLogInternal(self.config.logLevel, @"Setting user optOut state from storage to: %@ for storageKey: %@", optedOut ? @"YES" : @"NO", key);
    self.currentUserOptedOut = optedOut;
}

- (void)cacheGUIDSforProfile:(NSDictionary*)profileEvent {
    // cache identifier:guid pairs
    for (NSString *key in profileEvent) {
        @try {
            if ([CLTAP_PROFILE_IDENTIFIER_KEYS containsObject:key]) {
                NSString *identifier = [NSString stringWithFormat:@"%@", profileEvent[key]];
                [self cacheGUID:nil forKey:key andIdentifier:identifier];
            }
        } @catch (NSException *e) {
            // no-op
        }
    }
}

- (BOOL)isAnonymousDevice {
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    return [cache count] <= 0;
}

- (NSDictionary *)getCachedGUIDs {
    NSDictionary *cachedGUIDS = [CJMPreferences getObjectForKey:[self storageKeyWithSuffix:kCachedGUIDS]];
    if (!cachedGUIDS && self.config.isDefaultInstance) {
        cachedGUIDS = [CJMPreferences getObjectForKey:kCachedGUIDS];
    }
    return cachedGUIDS;
}

- (void)setCachedGUIDs:(NSDictionary *)cache {
    [CJMPreferences putObject:cache forKey:[self storageKeyWithSuffix:kCachedGUIDS]];
}

- (NSString *)getGUIDforKey:(NSString *)key andIdentifier:(NSString *)identifier {
    if (!key || !identifier) return nil;
    
    NSDictionary *cache = [self getCachedGUIDs];
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", key, identifier];
    if (!cache) return nil;
    else return cache[cacheKey];
}

- (void)cacheGUID:(NSString *)guid forKey:(NSString *)key andIdentifier:(NSString *)identifier {
    if (!guid) guid = [self profileGetCJMID];
    if (!guid || [self.deviceInfo isErrorDeviceID] || !key || !identifier) return;
    
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    NSMutableDictionary *newCache = [NSMutableDictionary dictionaryWithDictionary:cache];
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", key, identifier];
    newCache[cacheKey] = guid;
    [self setCachedGUIDs:newCache];
}

- (BOOL)deviceIsMultiUser {
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    return [cache count] > 1;
}

- (BOOL)isProcessingLoginUserWithIdentifier:(NSString *)identifier {
    return identifier == nil ? NO : [self.processingLoginUserIdentifier isEqualToString:identifier];
}

- (void)_onUserLogin:(NSDictionary *)properties withCJMID:(NSString *)CJMID {
    if (!properties) return;
    
    NSString *currentGUID = [self profileGetCJMID];
    
    if (!currentGUID) return;
    
    NSString *cachedGUID;
    BOOL haveIdentifier = NO;
    
    // check for valid identifier keys
    // use the first one we find
    for (NSString *key in properties) {
        @try {
            if ([CLTAP_PROFILE_IDENTIFIER_KEYS containsObject:key]) {
                NSString *identifier = [NSString stringWithFormat:@"%@", properties[key]];
                
                if (identifier && [identifier length] > 0) {
                    haveIdentifier = YES;
                    cachedGUID = [self getGUIDforKey:key andIdentifier:identifier];
                    if (cachedGUID) break;
                }
            }
        } @catch (NSException *e) {
            // no-op
        }
    }
    
    // if no identifier provided or there are no identified users on the device; just push on the current profile
    if (![self.deviceInfo isErrorDeviceID]) {
        if (!haveIdentifier || [self isAnonymousDevice]) {
            CJMLogDebug(self.config.logLevel, @"%@: onUserLogin: either don't have identifier or device is anonymous, associating profile %@ with current user profile", self, properties);
            [self profilePush:properties];
            return;
        }
    }
    // if profile maps to current guid, push on current profile
    if (cachedGUID && [cachedGUID isEqualToString:currentGUID]) {
        CJMLogDebug(self.config.logLevel, @"%@: onUserLogin: profile %@ maps to current device id %@, using current user profile", self, properties, currentGUID);
        [self profilePush:properties];
        return;
    }
    // stringify the profile dict to use as a concurrent dupe key
    NSString *profileToString = [CJMUtils dictionaryToJsonString:properties];
    
    // as processing happens async block concurrent onUserLogin requests with the same profile, as our cache is set async
    if ([self isProcessingLoginUserWithIdentifier:profileToString]) {
        CJMLogInternal(self.config.logLevel, @"Already processing onUserLogin, will not process for profile: %@", properties);
        return;
    }
    
    // prevent dupes
    self.processingLoginUserIdentifier = profileToString;
    
    [self _asyncSwitchUser:properties withCachedGuid:cachedGUID andCJMID:CJMID forAction:kOnUserLoginAction];
}

- (void) _asyncSwitchUser:(NSDictionary *)properties withCachedGuid:(NSString *)cachedGUID andCJMID:(NSString *)CJMID forAction:(NSString*)action  {
    
    [self runSerialAsync:^{
        CJMLogDebug(self.config.logLevel, @"%@: async switching user with properties:  %@", action, properties);
        
        // set OptOut to false for the old user
        self.currentUserOptedOut = NO;
        
        // unregister the push token on the current user
        [self pushDeviceTokenWithAction:CJMPushTokenUnregister];
        
        // clear any events in the queue
        [self clearQueue];
        
        // clear ARP and other context for the old user
        [self clearUserContext];
        
        // clear old profile data
        [self.localDataStore changeUser];
        
        [self resetSession];
        
        if (cachedGUID) {
            [self.deviceInfo forceUpdateDeviceID:cachedGUID];
        } else if (self.config.useCustomCJMId){
            [self.deviceInfo forceUpdateCustomDeviceID:CJMID];
        } else {
            [self.deviceInfo forceNewDeviceID];
        }
        
        [self recordDeviceErrors];
        
#if !CJM_NO_INAPP_SUPPORT
        if (![[self class] runningInsideAppExtension]) {
            [self.inAppFCManager changeUserWithGuid: self.deviceInfo.deviceId];
        }
#endif
        
        [self _setCurrentUserOptOutStateFromStorage];  // be sure to do this AFTER updating the GUID
        
#if !CJM_NO_INBOX_SUPPORT
        [self _resetInbox];
#endif
        
#if !CJM_NO_AB_SUPPORT
        [self _resetABTesting];
#endif
        
#if !CJM_NO_DISPLAY_UNIT_SUPPORT
        [self _resetDisplayUnit];
#endif
        
        [self _resetFeatureFlags];
        
        [self _resetProductConfig];
        
        // push data on reset profile
        [self recordAppLaunched:action];
        if (properties) {
            [self profilePush:properties];
        }
        [self pushDeviceTokenWithAction:CJMPushTokenRegister];
        [self notifyUserProfileInitialized];
    }];
}

- (void)_pushBaseProfile {
    [self runSerialAsync:^{
        NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
        NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
        event[@"profile"] = profile;
        [self queueEvent:event withType:CJMEventTypeProfile];
    }];
}


#pragma mark - Public

#pragma mark Public API's For Multi Instance Implementations

+ (void)handlePushNotification:(NSDictionary*)notification openDeepLinksInForeground:(BOOL)openInForeground {
    CJMLogStaticDebug(@"Handling notification: %@", notification);
    NSString *accountId = (NSString *) notification[@"wzrk_acct_id"];
    // route to the right instance
    if (!_instances || [_instances count] <= 0 || !accountId) {
        [[self sharedInstance] _handlePushNotification:notification openDeepLinksInForeground:openInForeground];
        return;
    }
    for (CJM *instance in [_instances allValues]) {
        if ([accountId isEqualToString:instance.config.accountId]) {
            [instance _handlePushNotification:notification openDeepLinksInForeground:openInForeground];
            break;
        }
    }
}

+ (void)handleOpenURL:(NSURL*)url {
    if ([[self class] runningInsideAppExtension]){
        CJMLogStaticDebug(@"handleOpenUrl is a no-op in an app extension.");
        return;
    }
    CJMLogStaticDebug(@"Handling open url: %@", url.absoluteString);
    NSDictionary *args = [CJMUriHelper getQueryParameters:url andDecode:YES];
    NSString *accountId = args[@"wzrk_acct_id"];
    // if no accountId, default to the sharedInstance
    if (!accountId) {
        [[self sharedInstance] handleOpenURL:url sourceApplication:nil];
        return;
    }
    for (CJM *instance in [_instances allValues]) {
        if ([accountId isEqualToString:instance.config.accountId]) {
            [instance handleOpenURL:url sourceApplication:nil];
            break;
        }
    }
}


#pragma mark - Profile/Event/Session APIs

- (void)notifyApplicationLaunchedWithOptions:launchOptions {
    if ([[self class] runningInsideAppExtension]) {
        CJMLogDebug(self.config.logLevel, @"%@: notifyApplicationLaunchedWithOptions is a no-op in an app extension.", self);
        return;
    }
    CJMLogInternal(self.config.logLevel, @"%@: Application launched with options: %@", self, launchOptions);
    [self _appEnteredForegroundWithLaunchingOptions:launchOptions];
}


#pragma mark - Device Network Info Reporting Handling
// public
- (void)enableDeviceNetworkInfoReporting:(BOOL)enabled {
    self.enableNetworkInfoReporting = enabled;
    [CJMPreferences putInt:enabled forKey:[self storageKeyWithSuffix:kNetworkInfoReportingKey]];
}

// private
- (void)_setDeviceNetworkInfoReportingFromStorage {
    BOOL enabled = NO;
    if (self.config.isDefaultInstance) {
        enabled = (BOOL) [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kNetworkInfoReportingKey] withResetValue:[CJMPreferences getIntForKey:kNetworkInfoReportingKey withResetValue:NO]];
    } else {
        enabled = (BOOL) [CJMPreferences getIntForKey:[self storageKeyWithSuffix:kNetworkInfoReportingKey] withResetValue:NO];
    }
    CJMLogInternal(self.config.logLevel, @"%@: Setting device network info reporting state from storage to: %@", self, enabled ? @"YES" : @"NO");
    [self enableDeviceNetworkInfoReporting:enabled];
}


#pragma mark - Profile API

- (void)setOptOut:(BOOL)enabled {
    [self runSerialAsync:^ {
        CJMLogDebug(self.config.logLevel, @"%@: User: %@ OptOut set to: %@", self, self.deviceInfo.deviceId, enabled ? @"YES" : @"NO");
        NSDictionary *profile = @{CLTAP_OPTOUT: @(enabled)};
        if (enabled) {
            [self profilePush:profile];
            self.currentUserOptedOut = enabled;  // if opting out set this after processing the profile event that updates the server optOut state
        } else {
            self.currentUserOptedOut = enabled;  // if opting back in set this before processing the profile event that updates the server optOut state
            [self profilePush:profile];
        }
        NSString *key = [self _optOutKey];
        if (!key) {
            CJMLogInternal(self.config.logLevel, @"unable to store user optOut, optOutKey is nil");
            return;
        }
        [CJMPreferences putInt:enabled forKey:key];
    }];
}
- (void)setOffline:(BOOL)offline {
    _offline = offline;
    if (_offline) {
        CJMLogDebug(self.config.logLevel, @"%@: offline is enabled, won't send queue", self);
    } else {
        CJMLogDebug(self.config.logLevel, @"%@: offline is disabled, send queue", self);
        [self flushQueue];
    }
}
- (BOOL)offline {
    return _offline;
}

- (void)setIdentity:(NSString * _Nonnull)identity {
    if ([identity length] == 0) {
        return;
    }
    
    NSString * idProfile = [CJMAESCrypt cjm_encrypt:identity password:kCJM_AES_KEY];
    [CJMPreferences putObject:idProfile forKey:kCJM_IDENTIFY];

    NSDictionary *profile = @{@"Identity": idProfile};
        
    [self onUserLogin:profile];
}
- (void)onUserLogin:(NSDictionary *_Nonnull)properties {
    [self _onUserLogin:properties withCJMID:nil];
}

- (void)onUserLogin:(NSDictionary *_Nonnull)properties withCJMID:(NSString *_Nonnull)CJMID {
    [self _onUserLogin:properties withCJMID:CJMID];
}

- (void)profilePush:(NSDictionary *)properties {
    [self runSerialAsync:^{
        [CJMProfileBuilder build:properties completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CJMValidationResult*>*errors) {
            if (systemFields) {
                [self.localDataStore setProfileFields:systemFields];
            }
            NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
            if (customFields) {
                CJMLogInternal(self.config.logLevel, @"%@: Constructed custom profile: %@", self, customFields);
                [self.localDataStore setProfileFields:customFields];
                [profile addEntriesFromDictionary:customFields];
            }
            [self cacheGUIDSforProfile:profile];
            
#if !defined(CJM_TVOS)
            // make sure Phone is a string and debug check for country code and phone format, but always send
            NSArray *profileAllKeys = [profile allKeys];
            for (int i = 0; i < [profileAllKeys count]; i++) {
                NSString *key = profileAllKeys[(NSUInteger) i];
                id value = profile[key];
                if ([key isEqualToString:@"Phone"]) {
                    value = [NSString stringWithFormat:@"%@", value];
                    if (!self.deviceInfo.countryCode || [self.deviceInfo.countryCode isEqualToString:@""]) {
                        NSString *_value = (NSString *)value;
                        if (![_value hasPrefix:@"+"]) {
                            // if no country code and phone doesn't start with + log error but still send
                            NSString *errString = [NSString stringWithFormat:@"Device country code not available and profile phone: %@ does not appear to start with country code", _value];
                            CJMValidationResult *error = [[CJMValidationResult alloc] init];
                            [error setErrorCode:512];
                            [error setErrorDesc:errString];
                            [self pushValidationResult:error];
                            CJMLogDebug(self.config.logLevel, @"%@: %@", self, errString);
                        }
                    }
                    CJMLogInternal(self.config.logLevel, @"Profile phone number is: %@, device country code is: %@", value, self.deviceInfo.countryCode);
                }
            }
#endif
            NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
            event[@"profile"] = profile;
            [self queueEvent:event withType:CJMEventTypeProfile];
            
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)profilePushGraphUser:(id)fbGraphUser {
    [self runSerialAsync:^{
        [CJMProfileBuilder buildGraphUser:fbGraphUser completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CJMValidationResult*>*errors) {
            if (systemFields) {
                [self.localDataStore setProfileFields:systemFields];
            }
            NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
            if (customFields) {
                CJMLogInternal(self.config.logLevel, @"%@: Constructed custom profile: %@", self, customFields);
                [self.localDataStore setProfileFields:customFields];
                [profile addEntriesFromDictionary:customFields];
            }
            [self cacheGUIDSforProfile:profile];
            
            NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
            event[@"profile"] = profile;
            [self queueEvent:event withType:CJMEventTypeProfile];
            
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)profilePushGooglePlusUser:(id)googleUser {
    [self runSerialAsync:^{
        [CJMProfileBuilder buildGooglePlusUser:googleUser completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CJMValidationResult*>*errors) {
            if (systemFields) {
                [self.localDataStore setProfileFields:systemFields];
            }
            NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
            if (customFields) {
                CJMLogInternal(self.config.logLevel, @"%@: Constructed custom profile: %@", self, customFields);
                [self.localDataStore setProfileFields:customFields];
                [profile addEntriesFromDictionary:customFields];
            }
            [self cacheGUIDSforProfile:profile];
            
            NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
            event[@"profile"] = profile;
            [self queueEvent:event withType:CJMEventTypeProfile];
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (id)profileGet:(NSString *)propertyName {
    if (!self.config.enablePersonalization) {
        return nil;
    }
    return [self.localDataStore getProfileFieldForKey:propertyName];
}

- (void)profileRemoveValueForKey:(NSString *)key {
    [self runSerialAsync:^{
        [CJMProfileBuilder buildRemoveValueForKey:key completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CJMValidationResult*>*errors) {
            if (customFields && [[customFields allKeys] count] > 0) {
                NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
                NSString* _key = [customFields allKeys][0];
                CJMLogInternal(self.config.logLevel, @"%@: removing key %@ from profile", self, _key);
                [self.localDataStore removeProfileFieldForKey:_key];
                [profile addEntriesFromDictionary:customFields];
                
                NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
                event[@"profile"] = profile;
                [self queueEvent:event withType:CJMEventTypeProfile];
            }
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)profileSetMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key {
    [CJMProfileBuilder buildSetMultiValues:values forKey:key localDataStore:self.localDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CJMValidationResult*>*errors) {
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileAddMultiValue:(NSString *)value forKey:(NSString *)key {
    [CJMProfileBuilder buildAddMultiValue:value forKey:key localDataStore:self.localDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CJMValidationResult*>*errors) {
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileAddMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key {
    [CJMProfileBuilder buildAddMultiValues:values forKey:key localDataStore:self.localDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CJMValidationResult*>*errors) {
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileRemoveMultiValue:(NSString *)value forKey:(NSString *)key {
    [CJMProfileBuilder buildRemoveMultiValue:value forKey:key localDataStore:self.localDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CJMValidationResult*>*errors) {
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileRemoveMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key {
    [CJMProfileBuilder buildRemoveMultiValues:values forKey:key localDataStore:self.localDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CJMValidationResult*>*errors) {
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

// private
- (void)_handleMultiValueProfilePush:(NSDictionary*)customFields updatedMultiValue:(NSArray*)updatedMultiValue errors:(NSArray<CJMValidationResult*>*)errors {
    if (customFields && [[customFields allKeys] count] > 0) {
        NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
        NSString* _key = [customFields allKeys][0];
        CJMLogInternal(self.config.logLevel, @"Created multi-value profile push: %@", customFields);
        [profile addEntriesFromDictionary:customFields];
        
        if (updatedMultiValue && [updatedMultiValue count] > 0) {
            [self.localDataStore setProfileFieldWithKey:_key andValue:updatedMultiValue];
        } else {
            [self.localDataStore removeProfileFieldForKey:_key];
        }
        NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
        event[@"profile"] = profile;
        [self queueEvent:event withType:CJMEventTypeProfile];
    }
    if (errors) {
        [self pushValidationResults:errors];
    }
}

- (NSString *)profileGetCJMID {
    return self.deviceInfo.deviceId;
}

- (NSString *)profileGetCJMAttributionIdentifier {
    return self.deviceInfo.deviceId;
}


#pragma mark - User Action Events API

- (NSDictionary*) buildAddingPropertyCustomEvent {
    NSMutableDictionary * props = [[NSMutableDictionary alloc] init];
    props[@"ep"] = @((int) [[NSDate date] timeIntervalSince1970]);
    props[@"s"] = @(self.sessionId);
    int screenCount = self.screenCount == 0 ? 1 : self.screenCount;
    props[@"pg"] = @(screenCount);
    props[@"lsl"] = @(self.lastSessionLengthSeconds);
    props[@"f"] = @(self.firstSession);
    props[@"n"] = self.currentViewControllerName ? self.currentViewControllerName : @"_bg";
    return props;
}

- (void)recordEvent:(NSString *)event {
//    !self.appLaunchProcessed
//    [CJMManager.sharedInstance recordEvent:event withProps:nil];
//    [CJMEventBuilder build:event completionHandler:^(NSDictionary *eventDict, NSArray<CJMValidationResult*>*errors) {
//        if (event) {
//            [[CJMManager sharedInstance] recordEvent:eventDict withProps: [self buildAddingPropertyCustomEvent]];
//        }
//        if (errors) {
//            [self pushValidationResults:errors];
//        }
//    }];
    
    [FIRAnalytics logEventWithName:event
                        parameters: nil];
    
    [self runSerialAsync:^{
        [CJMEventBuilder build:event completionHandler:^(NSDictionary *event, NSArray<CJMValidationResult*>*errors) {
            if (event) {
                [self queueEvent:event withType:CJMEventTypeRaised];
            }
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)recordEvent:(NSString *)event withProps:(NSDictionary *)properties {
//    [CJMManager.sharedInstance recordEvent:event withProps:properties];
//    [CJMEventBuilder build:event withEventActions:properties completionHandler:^(NSDictionary *eventDict, NSArray<CJMValidationResult*>*errors) {
//        if (event) {
//            [[CJMManager sharedInstance] recordEvent:eventDict withProps:[self buildAddingPropertyCustomEvent]];
//        }
//        if (errors) {
//            [self pushValidationResults:errors];
//        }
//    }];
    
    [FIRAnalytics logEventWithName:event
                        parameters: properties];
    [self runSerialAsync:^{
        [CJMEventBuilder build:event withEventActions:properties completionHandler:^(NSDictionary *event, NSArray<CJMValidationResult*>*errors) {
            if (event) {
                [self queueEvent:event withType:CJMEventTypeRaised];
            }
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)recordChargedEventWithDetails:(NSDictionary *)chargeDetails andItems:(NSArray *)items {
    [self runSerialAsync:^{
        [CJMEventBuilder buildChargedEventWithDetails:chargeDetails andItems:items completionHandler:^(NSDictionary *event, NSArray<CJMValidationResult*>*errors) {
            if (event) {
                [self queueEvent:event withType:CJMEventTypeRaised];
            }
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)recordErrorWithMessage:(NSString *)message andErrorCode:(int)code {
    [self runSerialAsync:^{
        NSString *currentVCName = self.currentViewControllerName ? self.currentViewControllerName : @"Unknown";
        
        [self recordEvent:@"Error Occurred" withProps:@{
            @"Error Message" : message,
            @"Error Code" : @(code),
            @"Location" : currentVCName
        }];
    }];
}

- (void)recordScreenView:(NSString *)screenName {
    if ([[self class] runningInsideAppExtension]) {
        CJMLogDebug(self.config.logLevel, @"%@: recordScreenView is a no-op in an app extension.", self);
        return;
    }
    self.isAppForeground = YES;
    if (!screenName) {
        self.currentViewControllerName = nil;
        return;
    }
    // skip dupes
    if (self.currentViewControllerName && [self.currentViewControllerName isEqualToString:screenName]) {
        return;
    }
    CJMLogInternal(self.config.logLevel, @"%@: screen changed: %@", self, screenName);
    if (self.currentViewControllerName == nil && self.screenCount == 1) {
        self.screenCount--;
    }
    self.currentViewControllerName = screenName;
    self.screenCount++;
    
    [self recordPageEventWithExtras:nil];
}

- (void)recordNotificationViewedEventWithData:(id _Nonnull)notificationData {
    [self _recordPushNotificationEvent:NO forNotification:notificationData];
}

- (void)recordNotificationClickedEventWithData:(id)notificationData {
    [self _recordPushNotificationEvent:YES forNotification:notificationData];
}

- (void)_recordPushNotificationEvent:(BOOL)clicked forNotification:(id)notificationData {
#if !defined(CJM_TVOS)
    NSDictionary *notification;
    if ([notificationData isKindOfClass:[UILocalNotification class]]) {
        notification = [((UILocalNotification *) notificationData) userInfo];
    } else if ([notificationData isKindOfClass:[NSDictionary class]]) {
        notification = notificationData;
    }
    [self runSerialAsync:^{
        [CJMEventBuilder buildPushNotificationEvent:clicked forNotification:notification completionHandler:^(NSDictionary *event, NSArray<CJMValidationResult*>*errors) {
            if (event) {
                self.wzrkParams = [event[@"evtData"] copy];
                [self queueEvent:event withType: clicked ? CJMEventTypeRaised : CJMEventTypeNotificationViewed];
            };
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
#endif
}

- (NSTimeInterval)eventGetFirstTime:(NSString *)event {
    
    if (!self.config.enablePersonalization) {
        return -1;
    }
    return [self.localDataStore getFirstTimeForEvent:event];
}

- (NSTimeInterval)eventGetLastTime:(NSString *)event {
    
    if (!self.config.enablePersonalization) {
        return -1;
    }
    return [self.localDataStore getLastTimeForEvent:event];
}

- (int)eventGetOccurrences:(NSString *)event {
    
    if (!self.config.enablePersonalization) {
        return -1;
    }
    return [self.localDataStore getOccurrencesForEvent:event];
}

- (NSDictionary *)userGetEventHistory {
    
    if (!self.config.enablePersonalization) {
        return nil;
    }
    return [self.localDataStore getEventHistory];
}

- (CJMEventDetail *)eventGetDetail:(NSString *)event {
    
    if (!self.config.enablePersonalization) {
        return nil;
    }
    return [self.localDataStore getEventDetail:event];
}


#pragma mark - Session API

- (NSTimeInterval)sessionGetTimeElapsed {
    long current = self.sessionId;
    return (int) [[[NSDate alloc] init] timeIntervalSince1970] - current;
}

- (CJMUTMDetail *)sessionGetUTMDetails {
    CJMUTMDetail *d = [[CJMUTMDetail alloc] init];
    d.source = self.source;
    d.medium = self.medium;
    d.campaign = self.campaign;
    return d;
}

- (int)userGetTotalVisits {
    return [self eventGetOccurrences:@"App Launched"];
}

- (int)userGetScreenCount {
    return self.screenCount;
}

- (NSTimeInterval)userGetPreviousVisitTime {
    return self.lastAppLaunchedTime;
}


# pragma mark - Notifications

- (void)setPushToken:(NSData *)pushToken {
    if ([[self class] runningInsideAppExtension]){
        CJMLogDebug(self.config.logLevel, @"%@: setPushToken is a no-op in an app extension.", self);
        return;
    }
    NSString *deviceTokenString = [CJMUtils deviceTokenStringFromData:pushToken];
    [self setPushTokenAsString:deviceTokenString];
}

- (void)setPushTokenAsString:(NSString *)pushTokenString {
    if ([[self class] runningInsideAppExtension]){
        CJMLogDebug(self.config.logLevel, @"%@: setPushTokenAsString is a no-op in an app extension.", self);
        return;
    }
    if (self.config.analyticsOnly) {
        CJMLogDebug(self.config.logLevel,@"%@ is analyticsOnly, not registering APNs device token %@", self, pushTokenString);
        return;
    }
    CJMLogDebug(self.config.logLevel, @"%@: registering APNs device token %@", self, pushTokenString);
    [self storeDeviceToken:pushTokenString];
    [self pushDeviceToken:pushTokenString forRegisterAction:CJMPushTokenRegister];
}

- (void)handleNotificationWithData:(id)data {
    if ([[self class] runningInsideAppExtension]){
        CJMLogDebug(self.config.logLevel, @"%@: handleNotificationWithData is a no-op in an app extension.", self);
        return;
    }
    [self handleNotificationWithData:data openDeepLinksInForeground:NO];
}

- (void)handleNotificationWithData:(id)data openDeepLinksInForeground:(BOOL)openInForeground {
    if ([[self class] runningInsideAppExtension]){
        CJMLogDebug(self.config.logLevel, @"%@: handleNotificationWithData is a no-op in an app extension.", self);
        return;
    }
    [self _handlePushNotification:data openDeepLinksInForeground:openInForeground];
}

- (BOOL)isCJMNotification:(NSDictionary *)payload {
    return [self _isCJMPushNotification:payload];
}

- (void)showInAppNotificationIfAny {
    if ([[self class] runningInsideAppExtension]){
        CJMLogDebug(self.config.logLevel, @"%@: showInappNotificationIfAny is a no-op in an app extension.", self);
        return;
    }
    if (!self.config.analyticsOnly) {
        [self runOnNotificationQueue:^{
            [self _showNotificationIfAvailable];
        }];
    }
}


# pragma mark - Referrer Tracking

- (void)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    if ([[self class] runningInsideAppExtension]){
        CJMLogDebug(self.config.logLevel, @"%@: handleOpenUrl is a no-op in an app extension.", self);
        return;
    }
    CJMLogDebug(self.config.logLevel, @"%@: handling open URL %@", self, url.absoluteString);
    NSString *URLString = [url absoluteString];
    if (URLString != nil) {
        [self _pushDeepLink:URLString withSourceApp:sourceApplication];
    }
}

- (void)pushInstallReferrerSource:(NSString *)source
                           medium:(NSString *)medium
                         campaign:(NSString *)campaign {
    if ([[self class] runningInsideAppExtension]){
        CJMLogDebug(self.config.logLevel, @"%@: pushInstallReferrerSource:medium:campaign is a no-op in an app extension.", self);
        return;
    }
    if (!source && !medium && !campaign) return;
    
    @synchronized (self) {
        long installStatus = 0;
        if (self.config.isDefaultInstance) {
            installStatus = [CJMPreferences getIntForKey:[self storageKeyWithSuffix:@"install_referrer_status"] withResetValue:[CJMPreferences getIntForKey:@"install_referrer_status" withResetValue:0]];
        } else {
            installStatus = [CJMPreferences getIntForKey:[self storageKeyWithSuffix:@"install_referrer_status"] withResetValue:0];
        }
        if (installStatus == 1) {
            CJMLogInternal(self.config.logLevel, @"%@: Install referrer has already been set. Will not overwrite", self);
            return;
        }
        [CJMPreferences putInt:1 forKey:[self storageKeyWithSuffix:@"install_referrer_status"]];
    }
    @try {
        if (source) source = [CJMUtils urlEncodeString:source];
        if (medium) medium = [CJMUtils urlEncodeString:medium];
        if (campaign) campaign = [CJMUtils urlEncodeString:campaign];
        
        NSString *uriStr = @"wzrk://track?install=true";
        
        if (source) uriStr = [uriStr stringByAppendingFormat:@"&utm_source=%@", source];
        if (medium) uriStr = [uriStr stringByAppendingFormat:@"&utm_medium=%@", medium];
        if (campaign) uriStr = [uriStr stringByAppendingFormat:@"&utm_campaign=%@", campaign];
        
        [self _pushDeepLink:uriStr withSourceApp:nil andInstall:true];
    } @catch (NSException *e) {
        // no-op
    }
}


#pragma mark - Admin

- (void)setLibrary:(NSString *)name {
    self.deviceInfo.library = name;
}

+ (void)setDebugLevel:(int)level {
    [CJMLogger setDebugLevel:level];
    if (_defaultInstanceConfig) {
        CJM *sharedInstance = [CJM sharedInstance];
        if (sharedInstance) {
            sharedInstance.config.logLevel = level;
        }
    }
}

+ (CJMLogLevel)getDebugLevel {
    return (CJMLogLevel)[CJMLogger getDebugLevel];
}

+ (void)changeCredentialsWithAccountID:(NSString *)accountID passcode:(NSString *) passcode andToken:(NSString *)token {
    [self _changeCredentialsWithAccountID:accountID token:token passcode:passcode region:nil];
}

+ (void)changeCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token passcode:(NSString *) passcode region:(NSString *)region {
    [self _changeCredentialsWithAccountID:accountID token:token passcode:passcode region:region];
}

+ (void)setCredentialsWithAccountID:(NSString *)accountID passcode:(NSString *) passcode andToken:(NSString *)token {
    [self _changeCredentialsWithAccountID:accountID token:token passcode:passcode region:nil];
}

+ (void)setCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token passcode:(NSString *) passcode region:(NSString *)region {
    [self _changeCredentialsWithAccountID:accountID token:token passcode:passcode region:region];
}

- (void)setSyncDelegate:(id <CJMSyncDelegate>)delegate {
    if (delegate && [delegate conformsToProtocol:@protocol(CJMSyncDelegate)]) {
        _syncDelegate = delegate;
    } else {
        CJMLogDebug(self.config.logLevel, @"%@: CleverTap Sync Delegate does not conform to the CleverTapSyncDelegate protocol", self);
    }
}

- (id<CJMSyncDelegate>)syncDelegate {
    return _syncDelegate;
}

- (void)setPushNotificationDelegate:(id<CJMPushNotificationDelegate>)delegate {
    if ([[self class] runningInsideAppExtension]){
        CJMLogDebug(self.config.logLevel, @"%@: setPushNotificationDelegate is a no-op in an app extension.", self);
        return;
    }
    if (delegate && [delegate conformsToProtocol:@protocol(CJMPushNotificationDelegate)]) {
        _pushNotificationDelegate = delegate;
    } else {
        CJMLogDebug(self.config.logLevel, @"%@: CleverTap PushNotification Delegate does not conform to the CleverTapPushNotificationDelegate protocol", self);
    }
}

- (id<CJMPushNotificationDelegate>)pushNotificationDelegate {
    return _pushNotificationDelegate;
}

- (void)setInAppNotificationDelegate:(id <CJMInAppNotificationDelegate>)delegate {
    if ([[self class] runningInsideAppExtension]){
        CJMLogDebug(self.config.logLevel, @"%@: setInAppNotificationDelegate is a no-op in an app extension.", self);
        return;
    }
    if (delegate && [delegate conformsToProtocol:@protocol(CJMInAppNotificationDelegate)]) {
        _inAppNotificationDelegate = delegate;
    } else {
        CJMLogDebug(self.config.logLevel, @"%@: CleverTap InAppNotification Delegate does not conform to the CleverTapInAppNotificationDelegate protocol", self);
    }
}

- (id<CJMInAppNotificationDelegate>)inAppNotificationDelegate {
    return _inAppNotificationDelegate;
}

+ (void)enablePersonalization {
    [self setPersonalizationEnabled:true];
}

+ (void)disablePersonalization {
    [self setPersonalizationEnabled:false];
}

+ (void)setPersonalizationEnabled:(BOOL)enabled {
    [CJMPreferences putInt:enabled forKey:kWR_KEY_PERSONALISATION_ENABLED];
}

+ (BOOL)isPersonalizationEnabled {
    return (BOOL) [CJMPreferences getIntForKey:kWR_KEY_PERSONALISATION_ENABLED withResetValue:YES];
}

- (void)setLocationForGeofences:(CLLocationCoordinate2D)location withPluginVersion:(NSString *)version {
    if (version) {
        _gfSDKVersion = version;
    }
    _geofenceLocation = YES;
    [self setLocation:location];
}

+ (void)setLocation:(CLLocationCoordinate2D)location {
    [[self sharedInstance] setLocation:location];
}

- (void)setLocation:(CLLocationCoordinate2D)location {
    self.userSetLocation = location;
}

- (void)setGeofenceLocation:(BOOL)geofenceLocation {
    _geofenceLocation = geofenceLocation;
}

- (BOOL)geofenceLocation {
    return _geofenceLocation;
}

+ (void)getLocationWithSuccess:(void (^)(CLLocationCoordinate2D location))success andError:(void (^)(NSString *reason))error; {
#if defined(CJM_LOCATION)
    [CTLocationManager getLocationWithSuccess:success andError:error];
#else
    CJMLogStaticInfo(@"To Enable CleverTap Location services/apis please build the SDK with the CLEVERTAP_LOCATION macro");
#endif
}

#pragma clang diagnostic pop


#pragma mark - Event API

- (NSTimeInterval)getFirstTime:(NSString *)event {
    return [self eventGetFirstTime:event];
}

- (NSTimeInterval)getLastTime:(NSString *)event {
    return [self eventGetLastTime:event];
}

- (int)getOccurrences:(NSString *)event {
    return [self eventGetOccurrences:event];
}

- (NSDictionary *)getHistory {
    return [self userGetEventHistory];
}

- (CJMEventDetail *)getEventDetail:(NSString *)event {
    return [self eventGetDetail:event];
}


#pragma mark - Profile API

- (id)getProperty:(NSString *)propertyName {
    return [self profileGet:propertyName];
}


#pragma mark - Session API

- (NSTimeInterval)getTimeElapsed {
    return [self sessionGetTimeElapsed];
}

- (int)getTotalVisits {
    return [self userGetTotalVisits];
}

- (int)getScreenCount {
    return [self userGetScreenCount];
}

- (NSTimeInterval)getPreviousVisitTime {
    return [self userGetPreviousVisitTime];
}

- (CJMUTMDetail *)getUTMDetails {
    return [self sessionGetUTMDetails];
}

#if defined(CJM_HOST_WATCHOS)
- (BOOL)handleMessage:(NSDictionary<NSString *, id> *)message forWatchSession:(WCSession *)session  {
    NSString *type = [message objectForKey:@"clevertap_type"];
    
    BOOL handled = (type != nil);
    
    if ([type isEqualToString:@"recordEventWithProps"]) {
        [self recordEvent: message[@"event"] withProps: message[@"props"]];
    }
    return handled;
}
#endif


#pragma mark - App Inbox

#if !CJM_NO_INBOX_SUPPORT

#pragma mark Public

- (void)initializeInboxWithCallback:(CJMInboxSuccessBlock)callback {
    if ([[self class] runningInsideAppExtension]) {
        CJMLogDebug(self.config.logLevel, @"%@: Inbox unavailable in app extensions", self);
        self.inboxController = nil;
        return;
    }
    if (_config.analyticsOnly) {
        CJMLogDebug(self.config.logLevel, @"%@ is configured as analytics only, Inbox unavailable", self);
        self.inboxController = nil;
        return;
    }
    if (sizeof(void*) == 4) {
        CJMLogDebug(self.config.logLevel, @"%@: CleverTap Inbox is not available on 32-bit Architecture", self);
        self.inboxController = nil;
        return;
    }
    [self runSerialAsync:^{
        if (self.inboxController) {
            [[self class] runSyncMainQueue: ^{
                callback(self.inboxController.isInitialized);
            }];
            return;
        }
        if (self.deviceInfo.deviceId) {
            self.inboxController = [[CJMInboxController alloc] initWithAccountId: [self.config.accountId copy] guid: [self.deviceInfo.deviceId copy]];
            self.inboxController.delegate = self;
            [[self class] runSyncMainQueue: ^{
                callback(self.inboxController.isInitialized);
            }];
        }
    }];
}

- (NSUInteger)getInboxMessageCount {
    if (![self _isInboxInitialized]) {
        return -1;
    }
    return self.inboxController.count;
}

- (NSUInteger)getInboxMessageUnreadCount {
    if (![self _isInboxInitialized]) {
        return -1;
    }
    return self.inboxController.unreadCount;
}

- (NSArray<CJMInboxMessage *> * _Nonnull )getAllInboxMessages {
    NSMutableArray *all = [NSMutableArray new];
    if (![self _isInboxInitialized]) {
        return all;
    }
    for (NSDictionary *m in self.inboxController.messages) {
        @try {
            [all addObject: [[CJMInboxMessage alloc] initWithJSON:m]];
        } @catch (NSException *e) {
            CJMLogDebug(_config.logLevel, @"Error getting inbox message: %@", e.debugDescription);
        }
    };
    
    return all;
}

- (NSArray<CJMInboxMessage *> * _Nonnull )getUnreadInboxMessages {
    NSMutableArray *all = [NSMutableArray new];
    if (![self _isInboxInitialized]) {
        return all;
    }
    for (NSDictionary *m in self.inboxController.unreadMessages) {
        @try {
            [all addObject: [[CJMInboxMessage alloc] initWithJSON:m]];
        } @catch (NSException *e) {
            CJMLogDebug(_config.logLevel, @"Error getting inbox message: %@", e.debugDescription);
        }
    };
    return all;
}

- (CJMInboxMessage * _Nullable )getInboxMessageForId:(NSString * _Nonnull)messageId {
    if (![self _isInboxInitialized]) {
        return nil;
    }
    NSDictionary *m = [self.inboxController messageForId:messageId];
    return (m != nil) ? [[CJMInboxMessage alloc] initWithJSON:m] : nil;
}

- (void)deleteInboxMessage:(CJMInboxMessage * _Nonnull)message {
    if (![self _isInboxInitialized]) {
        return;
    }
    [self.inboxController deleteMessageWithId:message.messageId];
}

- (void)markReadInboxMessage:(CJMInboxMessage * _Nonnull) message {
    if (![self _isInboxInitialized]) {
        return;
    }
    [self.inboxController markReadMessageWithId:message.messageId];
}

- (void)recordInboxNotificationViewedEventForID:(NSString * _Nonnull)messageId {
    CJMInboxMessage *message = [self getInboxMessageForId:messageId];
    [self recordInboxMessageStateEvent:NO forMessage:message andQueryParameters:nil];
}

- (void)recordInboxNotificationClickedEventForID:(NSString * _Nonnull)messageId {
    CJMInboxMessage *message = [self getInboxMessageForId:messageId];
    [self recordInboxMessageStateEvent:YES forMessage:message andQueryParameters:nil];
}

- (void)deleteInboxMessageForID:(NSString *)messageId {
    if (![self _isInboxInitialized]) {
        return;
    }
    [self.inboxController deleteMessageWithId:messageId];
}

- (void)markReadInboxMessageForID:(NSString *)messageId{
    if (![self _isInboxInitialized]) {
        return;
    }
    [self.inboxController markReadMessageWithId:messageId];
}

- (void)registerInboxUpdatedBlock:(CJMInboxUpdatedBlock)block {
    if (!_inboxUpdateBlocks) {
        _inboxUpdateBlocks = [NSMutableArray new];
    }
    [_inboxUpdateBlocks addObject:block];
}

- (CJMInboxViewController * _Nullable)newInboxViewControllerWithConfig:(CJMInboxStyleConfig * _Nullable )config andDelegate:(id<CJMInboxViewControllerDelegate> _Nullable )delegate {
    if (![self _isInboxInitialized]) {
        return nil;
    }
    NSArray *messages = [self getAllInboxMessages];
    if (! messages) {
        return nil;
    }
    return [[CJMInboxViewController alloc] initWithMessages:messages config:config delegate:delegate analyticsDelegate:self];
}


#pragma mark Private

- (void)_resetInbox {
    if (self.inboxController && self.inboxController.isInitialized && self.deviceInfo.deviceId) {
        self.inboxController = [[CJMInboxController alloc] initWithAccountId: [self.config.accountId copy] guid: [self.deviceInfo.deviceId copy]];
        self.inboxController.delegate = self;
    }
}

- (BOOL)_isInboxInitialized {
    if ([[self class] runningInsideAppExtension]) {
        CJMLogDebug(self.config.logLevel, @"%@: Inbox unavailable in app extensions", self);
        return NO;
    }
    if (_config.analyticsOnly) {
        CJMLogDebug(self.config.logLevel, @"%@ is configured as analytics only, Inbox unavailable", self);
        return NO;
    }
    
    if (!self.inboxController || !self.inboxController.isInitialized) {
        CJMLogDebug(_config.logLevel, @"%@: Inbox not initialized.  Did you call initializeInboxWithCallback: ?", self);
        return NO;
    }
    return YES;
}


#pragma mark CTInboxDelegate

- (void)inboxMessagesDidUpdate {
    CJMLogInternal(self.config.logLevel, @"%@: Inbox messages did update: %@", self, [self getAllInboxMessages]);
    for (CJMInboxUpdatedBlock block in self.inboxUpdateBlocks) {
        if (block) {
            block();
        }
    }
}


#pragma mark CJMInboxViewControllerAnalyticsDelegate

- (void)messageDidShow:(CJMInboxMessage *)message {
    CJMLogDebug(_config.logLevel, @"%@: inbox message viewed: %@", self, message);
    [self markReadInboxMessage:message];
    [self recordInboxMessageStateEvent:NO forMessage:message andQueryParameters:nil];
}

- (void)messageDidSelect:(CJMInboxMessage *_Nonnull)message atIndex:(int)index withButtonIndex:(int)buttonIndex {
    CJMLogDebug(_config.logLevel, @"%@: inbox message clicked: %@", self, message);
    [self recordInboxMessageStateEvent:YES forMessage:message andQueryParameters:nil];
    
    CJMInboxMessageContent *content = (CJMInboxMessageContent*)message.content[index];
    NSURL *ctaURL;
    // no button index, means use the on message click url if any
    if (buttonIndex < 0) {
        if (content.actionHasUrl) {
            if (content.actionUrl && content.actionUrl.length > 0) {
                ctaURL = [NSURL URLWithString:content.actionUrl];
            }
        }
    }
    // button index so find the corresponding action link if any
    else {
        if (content.actionHasLinks) {
            NSDictionary *customExtras = [content customDataForLinkAtIndex:buttonIndex];
            if (customExtras && customExtras.count > 0) return;
            NSString *linkUrl = [content urlForLinkAtIndex:buttonIndex];
            if (linkUrl && linkUrl.length > 0) {
                ctaURL = [NSURL URLWithString:linkUrl];
            }
        }
    }
    
    if (ctaURL && ![ctaURL.absoluteString isEqual: @""]) {
#if !CJM_NO_INBOX_SUPPORT
        [[self class] runSyncMainQueue:^{
            [self openURL:ctaURL forModule:@"Inbox message"];
        }];
#endif
    }
}

- (void)recordInboxMessageStateEvent:(BOOL)clicked
                          forMessage:(CJMInboxMessage *)message andQueryParameters:(NSDictionary *)params {
    
    [self runSerialAsync:^{
        [CJMEventBuilder buildInboxMessageStateEvent:clicked forMessage:message andQueryParameters:params completionHandler:^(NSDictionary *event, NSArray<CJMValidationResult*>*errors) {
            if (event) {
                if (clicked) {
                    self.wzrkParams = [event[@"evtData"] copy];
                }
                [self queueEvent:event withType:CJMEventTypeRaised];
            };
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}


#pragma mark Inbox Message private

- (BOOL)didHandleInboxMessageTestFromPushNotificaton:(NSDictionary*)notification {
#if !CJM_NO_INBOX_SUPPORT
    if ([[self class] runningInsideAppExtension]) {
        return NO;
    }
    
    if (!notification || [notification count] <= 0 || !notification[@"wzrk_inbox"]) return NO;
    
    @try {
        CJMLogDebug(self.config.logLevel, @"%@: Received inbox message from push payload: %@", self, notification);
        
        NSDictionary *msg;
        id data = notification[@"wzrk_inbox"];
        if ([data isKindOfClass:[NSString class]]) {
            NSString *jsonString = (NSString*)data;
            msg = [NSJSONSerialization
                   JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                   options:0
                   error:nil];
            
        } else if ([data isKindOfClass:[NSDictionary class]]) {
            msg = (NSDictionary*)data;
        }
        
        if (!msg) {
            CJMLogDebug(self.config.logLevel, @"%@: Unable to decode inbox message from push payload: %@", self, notification);
        }
        
        NSDate *now = [NSDate date];
        NSTimeInterval nowEpochSeconds = [now timeIntervalSince1970];
        NSInteger epochTime = nowEpochSeconds;
        NSString *nowEpoch = [NSString stringWithFormat:@"%li", (long)epochTime];
        
        NSDate *expireDate = [now dateByAddingTimeInterval:(24 * 60 * 60)];
        NSTimeInterval expireEpochSeconds = [expireDate timeIntervalSince1970];
        NSUInteger expireTime = (long)expireEpochSeconds;
        
        NSMutableDictionary *message = [NSMutableDictionary dictionary];
        [message setObject:nowEpoch forKey:@"_id"];
        [message setObject:[NSNumber numberWithLong:expireTime] forKey:@"wzrk_ttl"];
        [message addEntriesFromDictionary:msg];
        
        NSMutableArray<NSDictionary*> *inboxMsg = [NSMutableArray new];
        [inboxMsg addObject:message];
        
        if (inboxMsg) {
            float delay = self.isAppForeground ? 0.5 : 2.0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @try {
                    [self initializeInboxWithCallback:^(BOOL success) {
                        if (success) {
                            [self runSerialAsync:^{
                                [self.inboxController updateMessages:inboxMsg];
                            }];
                        }
                    }];
                } @catch (NSException *e) {
                    CJMLogDebug(self.config.logLevel, @"%@: Failed to display the inbox message from payload: %@", self, e.debugDescription);
                }
            });
        } else {
            CJMLogDebug(self.config.logLevel, @"%@: Failed to parse the inbox message as JSON", self);
            return YES;
        }
        
    } @catch (NSException *e) {
        CJMLogDebug(self.config.logLevel, @"%@: Failed to display the inbox message from payload: %@", self, e.debugDescription);
        return YES;
    }
    
#endif
    return YES;
}

#endif  //!CJM_NO_INBOX_SUPPORT


#pragma mark - AB Testing

#if !CJM_NO_AB_SUPPORT

#pragma mark AB Testing public

+ (void)setUIEditorConnectionEnabled:(BOOL)enabled {
    [CJMPreferences putInt:enabled forKey:kWR_KEY_AB_TEST_EDITOR_ENABLED];
}

+ (BOOL)isUIEditorConnectionEnabled {
    return (BOOL) [CJMPreferences getIntForKey:kWR_KEY_AB_TEST_EDITOR_ENABLED withResetValue:NO];
}

- (void)registerBoolVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerBoolVariableWithName:name];
}


- (void)registerDoubleVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerDoubleVariableWithName:name];
}

- (void)registerIntegerVariableWithName:(NSString*)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerIntegerVariableWithName:name];
}

- (void)registerStringVariableWithName:(NSString*)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerStringVariableWithName:name];
}

- (void)registerArrayOfBoolVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerArrayOfBoolVariableWithName:name];
}

- (void)registerArrayOfDoubleVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerArrayOfDoubleVariableWithName:name];
}

- (void)registerArrayOfIntegerVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerArrayOfIntegerVariableWithName:name];
}

- (void)registerArrayOfStringVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerArrayOfStringVariableWithName:name];
}

- (void)registerDictionaryOfBoolVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerDictionaryOfBoolVariableWithName:name];
}

- (void)registerDictionaryOfDoubleVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerDictionaryOfDoubleVariableWithName:name];
}

- (void)registerDictionaryOfIntegerVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerDictionaryOfIntegerVariableWithName:name];
}

- (void)registerDictionaryOfStringVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerDictionaryOfStringVariableWithName:name];
}

- (BOOL)getBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(BOOL)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getBoolVariableWithName:name defaultValue:defaultValue];
}

- (double)getDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(double)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getDoubleVariableWithName:name defaultValue:defaultValue];
}

- (int)getIntegerVariableWithName:(NSString*)name defaultValue:(int)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getIntegerVariableWithName:name defaultValue:defaultValue];
}

- (NSString*)getStringVariableWithName:(NSString*)name defaultValue:(NSString*)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getStringVariableWithName:name defaultValue:defaultValue];
}

- (NSArray<NSNumber*>* _Nonnull)getArrayOfBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getArrayOfBoolVariableWithName:name defaultValue:defaultValue];
}

- (NSArray<NSNumber*>* _Nonnull)getArrayOfDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getArrayOfDoubleVariableWithName:name defaultValue:defaultValue];
}

- (NSArray<NSNumber*>* _Nonnull)getArrayOfIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getArrayOfIntegerVariableWithName:name defaultValue:defaultValue];
}

- (NSArray<NSString*>* _Nonnull)getArrayOfStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSString*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getArrayOfStringVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getDictionaryOfBoolVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getDictionaryOfDoubleVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getDictionaryOfIntegerVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSString*>* _Nonnull)getDictionaryOfStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSString*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getDictionaryOfStringVariableWithName:name defaultValue:defaultValue];
}


#pragma mark ABTesting private

- (void) _initABTesting {
    if (!self.config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
        if (!self.config.enableABTesting) {
            CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
            return;
        }
        _config.enableUIEditor = [[self class] isUIEditorConnectionEnabled];
        if (!self.abTestController) {
            self.abTestController = [[CJMABTestController alloc] initWithConfig:self->_config guid:[self profileGetCJMID] delegate:self];
        }
    }
}

- (void) _resetABTesting {
    if (!self.config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
        if (!self.config.enableABTesting) {
            CJMLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
            return;
        }
        if (self.abTestController) {
            [self.abTestController resetWithGuid:[self profileGetCJMID]];
        } else {
            [self _initABTesting];
        }
    }
}


#pragma mark CTABTestingDelegate

- (CJMDeviceInfo* _Nonnull)getDeviceInfo {
    return self.deviceInfo;
}

- (void)abExperimentsDidUpdate {
    CJMLogInternal(self.config.logLevel, @"%@: AB Experiments did update", self);
    for (CJMExperimentsUpdatedBlock block in self.experimentsUpdateBlocks) {
        if (block) {
            block();
        }
    }
}

- (void)registerExperimentsUpdatedBlock:(CJMExperimentsUpdatedBlock)block {
    if (!_experimentsUpdateBlocks) {
        _experimentsUpdateBlocks = [NSMutableArray new];
    }
    [_experimentsUpdateBlocks addObject:block];
}

#endif  //!CJM_NO_AB_SUPPORT


#pragma mark - Display Units

#if !CJM_NO_DISPLAY_UNIT_SUPPORT

- (void)initializeDisplayUnitWithCallback:(CJMDisplayUnitSuccessBlock)callback {
    [self runSerialAsync:^{
        if (self.displayUnitController) {
            [[self class] runSyncMainQueue: ^{
                callback(self.displayUnitController.isInitialized);
            }];
            return;
        }
        if (self.deviceInfo.deviceId) {
            self.displayUnitController = [[CJMDisplayUnitController alloc] initWithAccountId: [self.config.accountId copy] guid: [self.deviceInfo.deviceId copy]];
            self.displayUnitController.delegate = self;
            [[self class] runSyncMainQueue: ^{
                callback(self.displayUnitController.isInitialized);
            }];
        }
    }];
}

- (void)_resetDisplayUnit {
    if (self.displayUnitController && self.displayUnitController.isInitialized && self.deviceInfo.deviceId) {
        self.displayUnitController = [[CJMDisplayUnitController alloc] initWithAccountId: [self.config.accountId copy] guid: [self.deviceInfo.deviceId copy]];
        self.displayUnitController.delegate = self;
    }
}

- (void)setDisplayUnitDelegate:(id<CleverTapDisplayUnitDelegate>)delegate {
    if ([[self class] runningInsideAppExtension]){
        CJMLogDebug(self.config.logLevel, @"%@: setDisplayUnitDelegate is a no-op in an app extension.", self);
        return;
    }
    if (delegate && [delegate conformsToProtocol:@protocol(CleverTapDisplayUnitDelegate)]) {
        _displayUnitDelegate = delegate;
    } else {
        CJMLogDebug(self.config.logLevel, @"%@: CleverTap Display Unit Delegate does not conform to the CleverTapDisplayUnitDelegate protocol", self);
    }
}

- (id<CleverTapDisplayUnitDelegate>)displayUnitDelegate {
    return _displayUnitDelegate;
}

- (void)displayUnitsDidUpdate {
    if (self.displayUnitDelegate && [self.displayUnitDelegate respondsToSelector:@selector(displayUnitsUpdated:)]) {
        [self.displayUnitDelegate displayUnitsUpdated:self.displayUnitController.displayUnits];
    }
}

- (BOOL)didHandleDisplayUnitTestFromPushNotificaton:(NSDictionary*)notification {
#if !CJM_NO_DISPLAY_UNIT_SUPPORT
    if ([[self class] runningInsideAppExtension]) {
        return NO;
    }
    
    if (!notification || [notification count] <= 0 || !notification[@"wzrk_adunit"]) return NO;
    
    @try {
        CJMLogDebug(self.config.logLevel, @"%@: Received display unit from push payload: %@", self, notification);
        
        NSString *jsonString = notification[@"wzrk_adunit"];
        
        NSDictionary *displayUnitDict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                                        options:0
                                                                          error:nil];
        
        NSMutableArray<NSDictionary*> *displayUnits = [NSMutableArray new];
        [displayUnits addObject:displayUnitDict];
        
        if (displayUnits && displayUnits.count > 0) {
            float delay = self.isAppForeground ? 0.5 : 2.0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @try {
                    [self initializeDisplayUnitWithCallback:^(BOOL success) {
                        if (success) {
                            [self.displayUnitController updateDisplayUnits:displayUnits];
                        }
                    }];
                } @catch (NSException *e) {
                    CJMLogDebug(self.config.logLevel, @"%@: Failed to initialize the display unit from payload: %@", self, e.debugDescription);
                }
            });
        } else {
            CJMLogDebug(self.config.logLevel, @"%@: Failed to parse the display unit as JSON", self);
            return YES;
        }
        
    } @catch (NSException *e) {
        CJMLogDebug(self.config.logLevel, @"%@: Failed to initialize the display unit from payload: %@", self, e.debugDescription);
        return YES;
    }
    
#endif
    return YES;
}


#pragma mark Display Unit Public

- (NSArray<CJMDisplayUnit *>*)getAllDisplayUnits {
    return self.displayUnitController.displayUnits;
}

- (CJMDisplayUnit *_Nullable)getDisplayUnitForID:(NSString *)unitID {
    for (CJMDisplayUnit *displayUnit in self.displayUnitController.displayUnits) {
        if ([displayUnit.unitID isEqualToString:unitID]) {
            @try {
                return displayUnit;
            } @catch (NSException *e) {
                CJMLogDebug(_config.logLevel, @"Error getting display unit: %@", e.debugDescription);
            }
        }
    };
    return nil;
}

- (void)recordDisplayUnitViewedEventForID:(NSString *)unitID {
    // get the display unit data
    CJMDisplayUnit *displayUnit = [self getDisplayUnitForID:unitID];
#if !defined(CJM_TVOS)
    [self runSerialAsync:^{
        [CJMEventBuilder buildDisplayViewStateEvent:NO forDisplayUnit:displayUnit andQueryParameters:nil completionHandler:^(NSDictionary *event, NSArray<CJMValidationResult*>*errors) {
            if (event) {
                self.wzrkParams = [event[@"evtData"] copy];
                [self queueEvent:event withType:CJMEventTypeRaised];
            };
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
#endif
}

- (void)recordDisplayUnitClickedEventForID:(NSString *)unitID {
    // get the display unit data
    CJMDisplayUnit *displayUnit = [self getDisplayUnitForID:unitID];
#if !defined(CJM_TVOS)
    [self runSerialAsync:^{
        [CJMEventBuilder buildDisplayViewStateEvent:YES forDisplayUnit:displayUnit andQueryParameters:nil completionHandler:^(NSDictionary *event, NSArray<CJMValidationResult*>*errors) {
            if (event) {
                self.wzrkParams = [event[@"evtData"] copy];
                [self queueEvent:event withType:CJMEventTypeRaised];
            };
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
#endif
}

#endif


#pragma mark - Feature Flags

// run off main
- (void) _initFeatureFlags {
    if (_config.analyticsOnly) {
        CJMLogDebug(self.config.logLevel, @"%@ is configured as analytics only, Feature Flag unavailable", self);
        return;
    }
    self.featureFlags = [[CJMFeatureFlags alloc] initWithPrivateDelegate:self];
    [self runSerialAsync:^{
        if (self.featureFlagsController) {
            return;
        }
        if (self.deviceInfo.deviceId) {
            self.featureFlagsController = [[CJMFeatureFlagsController alloc] initWithConfig: self.config guid:[self.deviceInfo.deviceId copy] delegate:self];
        }
        [self fetchFeatureFlags];
    }];
}

// run off main
- (void)_resetFeatureFlags {
    if (self.featureFlagsController && self.featureFlagsController.isInitialized && self.deviceInfo.deviceId) {
        self.featureFlagsController = [[CJMFeatureFlagsController alloc] initWithConfig: self.config guid:[self.deviceInfo.deviceId copy] delegate:self];
        [self fetchFeatureFlags];
    }
}

- (void)setFeatureFlagsDelegate:(id<CleverTapFeatureFlagsDelegate>)delegate {
    if (delegate && [delegate conformsToProtocol:@protocol(CJMFeatureFlagsDelegate)]) {
        _featureFlagsDelegate = delegate;
    } else {
        CJMLogDebug(self.config.logLevel, @"%@: CleverTap Feature Flags Delegate does not conform to the CleverTapFeatureFlagsDelegate protocol", self);
    }
}

- (id<CleverTapFeatureFlagsDelegate>)featureFlagsDelegate {
    return _featureFlagsDelegate;
}

- (void)featureFlagsDidUpdate {
    if (self.featureFlagsDelegate && [self.featureFlagsDelegate respondsToSelector:@selector(ctFeatureFlagsUpdated)]) {
        [self.featureFlagsDelegate ctFeatureFlagsUpdated];
    }
}

- (void)fetchFeatureFlags {
    [self queueEvent:@{@"evtName": CLTAP_WZRK_FETCH_EVENT, @"evtData" : @{@"t": @1}} withType:CJMEventTypeFetch];
}

- (BOOL)getFeatureFlag:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue {
    if (self.featureFlagsController && self.featureFlagsController.isInitialized) {
        return [self.featureFlagsController get:key withDefaultValue: defaultValue];
    }
    CJMLogDebug(self.config.logLevel, @"%@: CleverTap Feature Flags not initialized", self);
    return defaultValue;
}


#pragma mark - Product Config

// run off main
- (void) _initProductConfig {
    if (_config.analyticsOnly) {
        CJMLogDebug(self.config.logLevel, @"%@ is configured as analytics only, Product Config unavailable", self);
        return;
    }
    self.productConfig = [[CJMProductConfig alloc]  initWithConfig: self.config privateDelegate:self];
    [self runSerialAsync:^{
        if (self.productConfigController) {
            return;
        }
        if (self.deviceInfo.deviceId) {
            self.productConfigController = [[CJMProductConfigController alloc] initWithConfig: self.config guid:[self.deviceInfo.deviceId copy] delegate:self];
        }
    }];
}

// run off main
- (void)_resetProductConfig {
    if (self.productConfigController && self.productConfigController.isInitialized && self.deviceInfo.deviceId) {
        [self.productConfig resetProductConfigSettings];
        self.productConfig = [[CJMProductConfig alloc]  initWithConfig: self.config privateDelegate:self];
        self.productConfigController = [[CJMProductConfigController alloc] initWithConfig: self.config guid:[self.deviceInfo.deviceId copy] delegate:self];
    }
}

- (NSDictionary *)_setProductConfig:(NSDictionary *)arp {
    if (arp) {
        NSMutableDictionary *configOptions = [NSMutableDictionary new];
        configOptions[@"rc_n"] = arp[@"rc_n"];
        configOptions[@"rc_w"] = arp[@"rc_w"];
        return [configOptions mutableCopy];
    }
    return nil;
}

- (void)setProductConfigDelegate:(id<CleverTapProductConfigDelegate>)delegate {
    if (delegate && [delegate conformsToProtocol:@protocol(CleverTapProductConfigDelegate)]) {
        _productConfigDelegate = delegate;
    } else {
        CJMLogDebug(self.config.logLevel, @"%@: CleverTap Product Config Delegate does not conform to the CleverTapProductConfigDelegate protocol", self);
    }
}

- (id<CleverTapProductConfigDelegate>)productConfigDelegate {
    return _productConfigDelegate;
}

- (void)productConfigDidFetch {
    if (self.productConfigDelegate && [self.productConfigDelegate respondsToSelector:@selector(ctProductConfigFetched)]) {
        [self.productConfigDelegate ctProductConfigFetched];
    }
}

- (void)productConfigDidActivate {
    if (self.productConfigDelegate && [self.productConfigDelegate respondsToSelector:@selector(ctProductConfigActivated)]) {
        [self.productConfigDelegate ctProductConfigActivated];
    }
}

- (void)productConfigDidInitialize {
    if (self.productConfigDelegate && [self.productConfigDelegate respondsToSelector:@selector(ctProductConfigInitialized)]) {
        [self.productConfigDelegate ctProductConfigInitialized];
    }
}

- (void)fetchProductConfig {
    [self queueEvent:@{@"evtName": CLTAP_WZRK_FETCH_EVENT, @"evtData" : @{@"t": @0}} withType:CJMEventTypeFetch];
}

- (void)activateProductConfig {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        [self.productConfigController activate];
    }
}

- (void)fetchAndActivateProductConfig {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        [self.productConfigController fetchAndActivate];
    }
}

- (void)resetProductConfig {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        [self.productConfigController reset];
    }
}

- (void)setDefaultsProductConfig:(NSDictionary<NSString *,NSObject *> *)defaults {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        [self.productConfigController setDefaults:defaults];
    }
}

- (void)setDefaultsFromPlistFileNameProductConfig:(NSString *)fileName {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        [self.productConfigController setDefaultsFromPlistFileName:fileName];
    }
}

- (CJMConfigValue *_Nullable)getProductConfig:(NSString* _Nonnull)key {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        return [self.productConfigController get:key];
    }
    CJMLogDebug(self.config.logLevel, @"%@: CleverTap Product Config not initialized", self);
    return nil;
}


#pragma mark - Geofence Public APIs

- (void)didFailToRegisterForGeofencesWithError:(NSError *)error {
    CJMValidationResult *result = [[CJMValidationResult alloc] init];
    [result setErrorCode:(int)error.code];
    [result setErrorDesc:error.localizedDescription];
    [self pushValidationResult:result];
}

- (void)recordGeofenceEnteredEvent:(NSDictionary *_Nonnull)geofenceDetails {
    [self _buildGeofenceStateEvent:YES forGeofenceDetails:geofenceDetails];
}

- (void)recordGeofenceExitedEvent:(NSDictionary *_Nonnull)geofenceDetails {
    [self _buildGeofenceStateEvent:NO forGeofenceDetails:geofenceDetails];
}

- (void)_buildGeofenceStateEvent:(BOOL)entered forGeofenceDetails:(NSDictionary *_Nonnull)geofenceDetails {
#if !defined(CJM_TVOS)
    [self runSerialAsync:^{
        [CJMEventBuilder buildGeofenceStateEvent:entered forGeofenceDetails:geofenceDetails completionHandler:^(NSDictionary *event, NSArray<CJMValidationResult*>*errors) {
            if (event) {
                [self queueEvent:event withType:CJMEventTypeRaised];
            };
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
#endif
}

//- (void)login {
//    [[CJMManager sharedInstance] loginCJM];
//    
//}
@end
