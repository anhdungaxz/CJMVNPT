#if !(TARGET_OS_TV)
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
@class CJMInstanceConfig;

/*!
 
 @abstract
 The `CJMJSInterface` class is a bridge to communicate between Webviews and CJM SDK. Calls to forward record events or set user properties fired within a Webview to CJM SDK.
 */

@interface CJMJSInterface : NSObject <WKScriptMessageHandler>

@property (nonatomic, strong) WKUserContentController *userContentController;

- (instancetype)initWithConfig:(CJMInstanceConfig *)config;

@end
#endif

