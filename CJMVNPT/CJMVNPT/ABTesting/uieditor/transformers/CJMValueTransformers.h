#import <UIKit/UIKit.h>

@interface CJMPassThroughValueTransformer : NSValueTransformer

@end

@interface CJMNSStringFromCGColorRefValueTransformer : NSValueTransformer

@end

@interface CJMNSStringFromUIColorValueTransformer : NSValueTransformer

@end

@interface CJMNSDictionaryFromCATransform3DValueTransformer : NSValueTransformer

@end

@interface CJMNSDictionaryFromCGAffineTransformValueTransformer : NSValueTransformer

@end

@interface CJMNSDictionaryFromCGPointValueTransformer : NSValueTransformer

@end

@interface CJMNSDictionaryFromCGRectValueTransformer : NSValueTransformer

@end

@interface CJMNSDictionaryFromCGSizeValueTransformer : NSValueTransformer

@end

@interface CJMNSDictionaryFromNSAttributedStringValueTransformer : NSValueTransformer

@end

@interface CJMNSDictionaryFromUIEdgeInsetsValueTransformer : NSValueTransformer

@end

@interface CJMNSDictionaryFromUIFontValueTransformer : NSValueTransformer

@end

@interface CJMNSDictionaryFromUIImageValueTransformer : NSValueTransformer

+ (UIImage *)imageFromDictionary: (NSDictionary *)imagesDictionary;

@end

@interface CJMCGFloatFromNSNumberValueTransformer : NSValueTransformer

@end

@interface CJMNSNumberFromBOOLValueTransformer : NSValueTransformer

@end

__unused static id transformValue(id inputValue, NSString *toTypeName){
    
    if (!inputValue) return nil;
    
    if ([inputValue isKindOfClass:[NSClassFromString(toTypeName) class]]) {
        return [[NSValueTransformer valueTransformerForName:@"CTPassThroughValueTransformer"] transformedValue:inputValue];
    }
    
    NSString *fromTypeName = nil;
    NSArray *validClasses = @[[NSString class], [NSNumber class], [NSDictionary class], [NSArray class], [NSNull class]];
    for (Class c in validClasses) {
        if ([inputValue isKindOfClass:c]) {
            fromTypeName = NSStringFromClass(c);
            break;
        }
    }
    
    if (!fromTypeName) return nil;
    
    NSValueTransformer *transformer = nil;
    NSString *forwardTransformer = [NSString stringWithFormat:@"CT%@From%@ValueTransformer", toTypeName, fromTypeName];
    transformer = [NSValueTransformer valueTransformerForName:forwardTransformer];
    if (transformer) {
        return [transformer transformedValue:inputValue];
    }
    
    NSString *reverseTransformer = [NSString stringWithFormat:@"CT%@From%@ValueTransformer", fromTypeName, toTypeName];
    transformer = [NSValueTransformer valueTransformerForName:reverseTransformer];
    if (transformer && [[transformer class] allowsReverseTransformation]) {
        return [transformer reverseTransformedValue:inputValue];
    }
    
    return [[NSValueTransformer valueTransformerForName:@"CTPassThroughValueTransformer"] transformedValue:inputValue];
}


