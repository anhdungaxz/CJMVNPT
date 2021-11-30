//#if CJM_SSL_PINNING
#import "CJMPinnedNSURLSessionDelegate.h"
#import "CJMCertificatePinning.h"
#import "CJMConstants.h"
#import "CJMInstanceConfig.h"
#import "CJMInstanceConfigPrivate.h"

@interface CJMPinnedNSURLSessionDelegate () {}

@property (nonatomic, strong) CJMInstanceConfig *config;

@end

@implementation CJMPinnedNSURLSessionDelegate

- (NSString*)description {
    return [NSString stringWithFormat:@"CleverTap.%@", self.config.accountId];
}

- (instancetype)initWithConfig:(CJMInstanceConfig *)config {
    if (self = [super init]) {
        _config = config;
    }
    return self;
}

- (void)pinSSLCerts:(NSArray *)filenames forDomains:(NSArray *)domains {
    CJMLogDebug(self.config.logLevel, @"%@: Pinning SSL certs", self);
    NSMutableArray *certs = [NSMutableArray array];
    for (NSString *filename in filenames) {
        NSString *certPath =  [[NSBundle bundleForClass:[self class]] pathForResource:filename ofType:@"crt"];
        NSData *certData = [[NSData alloc] initWithContentsOfFile:certPath];
        if (certData == nil) {
            CJMLogDebug(_config.logLevel, @"%@: Failed to load ssl certificate : %@", self, filename);
            return;
        }
        [certs addObject:certData];
    }
    NSMutableDictionary *pins = [[NSMutableDictionary alloc] init];
    for (NSString *domain in domains) {
        [pins setObject:certs forKey:domain];
    }
    if (pins == nil) {
        CJMLogDebug(_config.logLevel, @"Failed to pin ssl certificates");
        return;
    }
    
    if ([CJMCertificatePinning setupSSLPinsUsingDictionnary:pins forAccountId:self.config.accountId] != YES) {
        CJMLogDebug(_config.logLevel, @"%@: Failed to pin ssl certificates", self);
    }
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
            return;
//        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
//        NSString *domain = [[challenge protectionSpace] host];
//        SecTrustResultType trustResult;
//
//        // Validate the certificate chain with the device's trust store anyway
//        // This *might* give use revocation checking
//        SecTrustEvaluate(serverTrust, &trustResult);
//        if (trustResult == kSecTrustResultUnspecified) {
//
//            // Look for a pinned certificate in the server's certificate chain
//            if ([CTCertificatePinning verifyPinnedCertificateForTrust:serverTrust andDomain:domain forAccountId:self.config.accountId]) {
//
//                // Found the certificate; continue connecting
//                completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
//            }
//            else {
//                // The certificate wasn't found in the certificate chain; cancel the connection
//                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
//            }
//        }
//        else {
//            // Certificate chain validation failed; cancel the connection
//            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
//        }
    }
}

@end

//#endif
