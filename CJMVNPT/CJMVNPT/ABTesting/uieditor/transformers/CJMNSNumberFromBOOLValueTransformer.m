#import "CJMValueTransformers.h"

@implementation CJMNSNumberFromBOOLValueTransformer

+ (Class)transformedValueClass {
    return [@YES class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector:@selector(boolValue)]) {
        return @([value boolValue]);
    }
    return nil;
}

@end
