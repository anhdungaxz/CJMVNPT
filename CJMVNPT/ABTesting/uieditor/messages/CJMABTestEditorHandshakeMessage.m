#import "CJMABTestEditorHandshakeMessage.h"

@implementation CJMABTestEditorHandshakeMessage

+ (instancetype)message {
    return [[[self class] alloc] initWithType:@"handshake"];
}

- (CJMABTestEditorMessage *)response {
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ type=%@, data=%@>", NSStringFromClass([self class]), self.type, self.data];
}

@end
