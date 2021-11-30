#import <Foundation/Foundation.h>

@interface NSInvocation (CJMHelper)

- (void)CJM_setArgumentsFromArray:(NSArray *)argumentArray;
- (id)CJM_returnValue;

@end

