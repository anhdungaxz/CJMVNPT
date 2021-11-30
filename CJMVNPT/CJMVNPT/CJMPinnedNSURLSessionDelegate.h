//#if CJM_SSL_PINNING
@import Foundation;

@class CJMInstanceConfig;

@interface CJMPinnedNSURLSessionDelegate : NSObject <NSURLSessionDelegate>

- (instancetype)initWithConfig:(CJMInstanceConfig *)config;

- (void)pinSSLCerts:(NSArray *)filenames forDomains:(NSArray *)domains;

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;

@end
//#endif
