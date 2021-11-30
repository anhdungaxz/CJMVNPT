#import "CJMValueTransformers.h"

@implementation CJMCGFloatFromNSNumberValueTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *) value;
        if (strcmp(number.objCType, @encode(CGFloat)) != 0) {
            if (strcmp(@encode(CGFloat), @encode(double)) == 0) {
                value = @(number.doubleValue);
            } else {
                value = @(number.floatValue);
            }
        }
        return value;
    }
    return nil;
}

@end

