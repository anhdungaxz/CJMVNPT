#import "CJMPlistInfo.h"
#import "CJM.h"
#import "CJMConstants.h"

static NSDictionary *plistRootInfoDict;
static NSArray *registeredURLSchemes;

@implementation CJMPlistInfo

+ (id)getValueForKey:(NSString *)key {
    if (!plistRootInfoDict) {
        plistRootInfoDict = [[NSBundle mainBundle] infoDictionary];
    }
    return plistRootInfoDict[key];
}

+ (NSString *)getMetaDataForAttribute:(NSString *)name {
    @try {
        id _value = [self getValueForKey:name];
        
        if(_value && ![_value isKindOfClass:[NSString class]]) {
            _value = [NSString stringWithFormat:@"%@", _value];
        }
        
        NSString *value = (NSString *)_value;
        
        if (value == nil || [[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
            CJMLogStaticDebug(@"%@: not specified in Info.plist", name);
            value = nil;
        } else {
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            CJMLogStaticDebug(@"%@: %@", name, value);
        }
        return value;
        
    } @catch (NSException *e) {
        CJMLogStaticInternal(@"Requested meta data entry not found: %@", name);
        return nil;
    }
}
+ (NSArray *)getRegisteredURLSchemes {
    
    if (!registeredURLSchemes) {
        registeredURLSchemes = [NSArray new];
        
        @try {
            NSArray *cfBundleURLTypes = [[self class] getValueForKey:@"CFBundleURLTypes"];
            if (cfBundleURLTypes && [cfBundleURLTypes isKindOfClass:[NSArray class]]) {
                for (NSDictionary *item in cfBundleURLTypes) {
                    NSArray* cfBundleURLSchemes = item[@"CFBundleURLSchemes"];
                    if (cfBundleURLSchemes && [cfBundleURLSchemes isKindOfClass:[NSArray class]]) {
                        registeredURLSchemes = [cfBundleURLSchemes copy];
                    }
                }
            }
        } @catch (NSException *e) {
            // no-op
        }
    }
    return registeredURLSchemes;
}

+ (instancetype)sharedInstance {
    static CJMPlistInfo *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-   (instancetype)init {
    if ((self = [super init])) {
        _accountId = [CJMPlistInfo getMetaDataForAttribute:CLTAP_ACCOUNT_ID_LABEL];
        _accountToken = [CJMPlistInfo getMetaDataForAttribute:CLTAP_TOKEN_LABEL];
        _accountRegion = [CJMPlistInfo getMetaDataForAttribute:CLTAP_REGION_LABEL];
        _accountPasscode = [CJMPlistInfo getMetaDataForAttribute:CLTAP_PASSCODE_LABEL];
        _registeredUrlSchemes = [CJMPlistInfo getRegisteredURLSchemes];
                
        NSString *useCustomCJMId = [CJMPlistInfo getMetaDataForAttribute:CLTAP_USE_CUSTOM_CLEVERTAP_ID_LABEL];
        _useCustomCJMId = (useCustomCJMId && [useCustomCJMId isEqualToString:@"1"]);
        
        NSString *shouldDisableAppLaunchReporting = [CJMPlistInfo getMetaDataForAttribute:CLTAP_DISABLE_APP_LAUNCH_LABEL];
        _disableAppLaunchedEvent = (shouldDisableAppLaunchReporting && [shouldDisableAppLaunchReporting isEqualToString:@"1"]);
        
        NSString *enableBeta = [CJMPlistInfo getMetaDataForAttribute:CLTAP_BETA_LABEL];
        _beta = (enableBeta && [enableBeta isEqualToString:@"1"]);
    }
    return self;
}

- (void)changeCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token passcode:(NSString * _Nonnull)passcode region:(NSString *)region {
    _accountId = accountID;
    _accountToken = token;
    _accountRegion = region;
    _accountPasscode = passcode;
}
@end
