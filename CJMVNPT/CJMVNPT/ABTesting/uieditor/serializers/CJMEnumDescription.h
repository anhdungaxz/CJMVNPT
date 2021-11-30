#import "CJMTypeDescription.h"

@interface CJMEnumDescription : CJMTypeDescription

@property (nonatomic, assign, getter=isFlagsSet, readonly) BOOL flagSet;
@property (nonatomic, copy, readonly) NSString *baseType;

- (NSArray *)allValues;

@end

