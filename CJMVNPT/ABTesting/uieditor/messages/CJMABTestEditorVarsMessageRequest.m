#import "CJMABTestEditorVarsMessageRequest.h"
#import "CJMABTestEditorVarsMessageResponse.h"

NSString *const CJMABTestEditorVarsMessageRequestType = @"vars_request";

@interface CJMABTestEditorVarsMessageRequest ()

@property (nonatomic, strong)NSArray<NSDictionary*> *serializedVars;

@end

@implementation CJMABTestEditorVarsMessageRequest

+ (instancetype)message {
    return [(CJMABTestEditorVarsMessageRequest *)[self alloc] initWithType:CJMABTestEditorVarsMessageRequestType];
}

+ (instancetype)messageWithOptions:(NSDictionary *)options {
    CJMABTestEditorVarsMessageRequest *message = [CJMABTestEditorVarsMessageRequest message];
    message.serializedVars = options[@"vars"];
    return message;
}

- (CJMABTestEditorMessage *)response {
    CJMABTestEditorVarsMessageResponse *message = [CJMABTestEditorVarsMessageResponse messageWithOptions:nil];
    message.vars = self.serializedVars;
    return message;
}

@end
