#import <Foundation/Foundation.h>

@class CJMInstanceConfig;
@class CJMValidationResult;

@interface CJMDeviceInfo : NSObject

@property (strong, readonly) NSString *sdkVersion;
@property (strong, readonly) NSString *appVersion;
@property (strong, readonly) NSString *appBuild;
@property (strong, readonly) NSString *bundleId;
@property (strong, readonly) NSString *osName;
@property (strong, readonly) NSString *osVersion;
@property (strong, readonly) NSString *manufacturer;
@property (strong, readonly) NSString *model;
@property (strong, readonly) NSString *carrier;
@property (strong, readonly) NSString *countryCode;
@property (strong, readonly) NSString *timeZone;
@property (strong, readonly) NSString *radio;
@property (strong, readonly) NSString *vendorIdentifier;
@property (strong, readonly) NSString *deviceWidth;
@property (strong, readonly) NSString *deviceHeight;
@property (atomic, readonly) NSString *deviceId;
@property (atomic, readonly) NSString *deviceName;
@property (atomic, readonly) NSString *fallbackDeviceId;
@property (atomic, readwrite) NSString *library;
@property (assign, readonly) BOOL wifi;
@property (strong, readonly) NSMutableArray<CJMValidationResult*>* validationErrors;

- (instancetype)initWithConfig:(CJMInstanceConfig *)config andCJMID:(NSString *)CJMID;
- (void)forceUpdateDeviceID:(NSString *)newDeviceID;
- (void)forceNewDeviceID;
- (void)forceUpdateCustomDeviceID:(NSString *)CJMID;
- (BOOL)isErrorDeviceID;

@end
