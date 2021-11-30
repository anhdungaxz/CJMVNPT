#import <Foundation/Foundation.h>

@interface CJMValidationResult : NSObject

- (NSString *)errorDesc;

- (NSObject *)object;

- (int)errorCode;

- (void)setErrorDesc:(NSString *)errorDsc;

- (void)setObject:(NSObject *)obj;

- (void)setErrorCode:(int)errorCod;

+ (CJMValidationResult *) resultWithErrorCode:(int) code andMessage:(NSString*) message;

@end
