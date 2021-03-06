#import <Foundation/Foundation.h>

@interface CJMUtils : NSObject

+ (NSString *)dictionaryToJsonString:(NSDictionary *)dict;
+ (NSString *)urlEncodeString:(NSString*)s;
+ (BOOL)doesString:(NSString *)s startWith:(NSString *)prefix;
+ (NSString *)deviceTokenStringFromData:(NSData *)tokenData;
+ (double)toTwoPlaces:(double)x;

@end
