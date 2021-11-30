#import "CJMValueTransformers.h"

static NSDictionary *CJMCGAffineTransformCreateDictionaryRepresentation(CGAffineTransform transform)
{
    return @{
        @"a": @(transform.a),
        @"b": @(transform.b),
        @"c": @(transform.c),
        @"d": @(transform.d),
        @"tx": @(transform.tx),
        @"ty": @(transform.ty)
    };
}

static BOOL CJMCGAffineTransformMakeWithDictionaryRepresentation(NSDictionary *dictionary, CGAffineTransform *transform)
{
    if (transform) {
        id a = dictionary[@"a"];
        id b = dictionary[@"b"];
        id c = dictionary[@"c"];
        id d = dictionary[@"d"];
        id tx = dictionary[@"tx"];
        id ty = dictionary[@"ty"];
        
        if (a && b && c && d && tx && ty) {
            transform->a = (CGFloat)[a doubleValue];
            transform->b = (CGFloat)[b doubleValue];
            transform->c = (CGFloat)[c doubleValue];
            transform->d = (CGFloat)[d doubleValue];
            transform->tx = (CGFloat)[tx doubleValue];
            transform->ty = (CGFloat)[ty doubleValue];
            return YES;
        }
    }
    return NO;
}

@implementation CJMNSDictionaryFromCGAffineTransformValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector:@selector(CGAffineTransformValue)]) {
        return CJMCGAffineTransformCreateDictionaryRepresentation([value CGAffineTransformValue]);
    }
    return @{};
}

- (id)reverseTransformedValue:(id)value {
    CGAffineTransform transform = CGAffineTransformIdentity;
    if ([value isKindOfClass:[NSDictionary class]] && CJMCGAffineTransformMakeWithDictionaryRepresentation(value, &transform)) {
        return [NSValue valueWithCGAffineTransform:transform];
    }
    return [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
}

@end
