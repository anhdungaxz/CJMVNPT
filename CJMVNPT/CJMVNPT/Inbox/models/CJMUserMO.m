#import "CJMUserMO.h"

@implementation CJMUserMO

- (NSString*)description {
    return [NSString stringWithFormat:@"CTUserMO: %@ messages count=%lu", self.identifier, (long)[self.messages count]];
}

@end
