#import <Foundation/Foundation.h>

@interface CJMLogger : NSObject

+ (void)setDebugLevel:(int)level;
+ (int)getDebugLevel;

@end
