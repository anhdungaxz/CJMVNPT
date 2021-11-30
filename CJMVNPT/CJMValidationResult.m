#import "CJMValidationResult.h"

@interface CJMValidationResult () {
    NSObject *object;
    int errorCode;
    NSString *errorDesc;
}

@end

@implementation CJMValidationResult

+ (CJMValidationResult *) resultWithErrorCode:(int) code andMessage:(NSString*) message {
    CJMValidationResult *vr = [[CJMValidationResult alloc] init];
    [vr setErrorCode:code];
    [vr setErrorDesc:message];
    return vr;
}

- (id)init {
    if (self = [super init]) {
        errorCode = 0;
    }
    return self;
}

- (NSString *)errorDesc {
    return errorDesc;
}

- (NSObject *)object {
    return object;
}

- (int)errorCode {
    return errorCode;
}

- (void)setErrorDesc:(NSString *)errorDsc {
    errorDesc = errorDsc;
}

- (void)setObject:(NSObject *)obj {
    object = obj;
}

- (void)setErrorCode:(int)errorCod {
    errorCode = errorCod;
}

@end
