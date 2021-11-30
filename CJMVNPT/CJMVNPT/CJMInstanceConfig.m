#import "CJMInstanceConfig.h"
#import "CJMInstanceConfigPrivate.h"
#import "CJMPlistInfo.h"
#import "CJMConstants.h"

@implementation CJMInstanceConfig

- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                  accountPasscode:(NSString *)accountPasscode{
    return [self initWithAccountId:accountId
                      accountToken:accountToken
                   accountPasscode:accountPasscode
                     accountRegion:nil
                 isDefaultInstance:NO];    
}

- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                  accountPasscode:(NSString *)accountPasscode
                    accountRegion:(NSString *)accountRegion {
    return [self initWithAccountId:accountId
                      accountToken:accountToken
                   accountPasscode:accountPasscode
                     accountRegion:accountRegion
                 isDefaultInstance:NO];
}
// SDK private
- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                  accountPasscode:(NSString *)accountPasscode
                    accountRegion:(NSString *)accountRegion
                isDefaultInstance:(BOOL)isDefault {
    if (accountId.length <= 0) {
        CJMLogStaticInfo("CleverTap accountId is empty");
    }
    
    if (accountToken.length <= 0) {
        CJMLogStaticInfo("CleverTap accountToken is empty");
    }
    
    if (self = [super init]) {
        _accountId = accountId;
        _accountToken = accountToken;
        _accountRegion = accountRegion;
        _accountPasscode = accountPasscode;
        _isDefaultInstance = isDefault;
        
        CJMPlistInfo *plist = [CJMPlistInfo sharedInstance];
        _disableAppLaunchedEvent = isDefault ? plist.disableAppLaunchedEvent : NO;
        _useCustomCJMId = isDefault ? plist.useCustomCJMId : NO;
        _enablePersonalization = YES;
        _logLevel = 0;
        _queueLabel = [NSString stringWithFormat:@"com.clevertap.serialQueue:%@",accountId];
        _beta = plist.beta;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone*)zone {
    CJMInstanceConfig *copy = [[[self class] allocWithZone:zone] initWithAccountId:self.accountId accountToken:self.accountToken accountPasscode:self.accountPasscode accountRegion:self.accountRegion isDefaultInstance:self.isDefaultInstance];
    copy.analyticsOnly = self.analyticsOnly;
    copy.disableAppLaunchedEvent = self.disableAppLaunchedEvent;
    copy.enablePersonalization = self.enablePersonalization;
    copy.logLevel = self.logLevel;
    copy.enableABTesting = self.enableABTesting;
    copy.enableUIEditor = self.enableUIEditor;
    copy.useCustomCJMId = self.useCustomCJMId;
    copy.beta = self.beta;
    return copy;
}

@end
