#import <Foundation/Foundation.h>

@interface CJMUriHelper : NSObject

+ (NSDictionary *)getUrchinFromUri:(NSString *)uri withSourceApp:(NSString *)sourceApp;
+ (NSDictionary *)getQueryParameters:(NSURL *)url andDecode:(BOOL)decode;

@end
