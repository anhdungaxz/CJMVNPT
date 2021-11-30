#import "CJMEventDetail.h"

@implementation CJMEventDetail

- (NSString*) description {
    return [NSString stringWithFormat:@"CleverTapEventDetail (event name = %@; first time = %d, last time = %d; count = %lu)",
            self.eventName, (int) self.firstTime, (int) self.lastTime, (unsigned long)self.count];
}

@end
