#import <Foundation/Foundation.h>

@interface CJMEventDetail : NSObject

@property (nonatomic, strong) NSString *eventName;
@property (nonatomic) NSTimeInterval firstTime;
@property (nonatomic) NSTimeInterval lastTime;
@property (nonatomic) NSUInteger count;

@end