#import "CJMABTestEditorVarsMessageResponse.h"

NSString *const CJMABTestEditorVarsMessageResponseType = @"vars_response";

@implementation CJMABTestEditorVarsMessageResponse

+ (instancetype)message {
    return [[[self class] alloc] initWithType:CJMABTestEditorVarsMessageResponseType];
}

- (void)setVars:(NSArray *)vars {
    [self setDataObject:vars forKey:@"vars"];
}

- (NSArray *)vars {
    return [self dataObjectForKey:@"vars"];
}
@end
