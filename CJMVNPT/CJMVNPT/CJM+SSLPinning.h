@import Foundation;
#import "CJM.h"

@interface CJM (SSLPinning)

//#ifdef CJM_SSL_PINNING
@property (nonatomic, assign, readonly) BOOL sslPinningEnabled;
//#endif

@end
