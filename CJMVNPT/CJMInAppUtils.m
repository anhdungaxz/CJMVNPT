#import <UIKit/UIKit.h>
#import "CJMInAppUtils.h"
#if !CLEVERTAP_NO_INAPP_SUPPORT
#import "CJMInAppResources.h"
#endif

static NSDictionary *_inAppTypeMap;

@implementation CJMInAppUtils

+ (CJMInAppType)inAppTypeFromString:(NSString*)type {
    if (_inAppTypeMap == nil) {
        _inAppTypeMap = @{
            @"custom-html": @(CJMInAppTypeHTML),
            @"interstitial": @(CJMInAppTypeInterstitial),
            @"cover": @(CJMInAppTypeCover),
            @"header-template": @(CJMInAppTypeHeader),
            @"footer-template": @(CJMInAppTypeFooter),
            @"half-interstitial": @(CJMInAppTypeHalfInterstitial),
            @"alert-template": @(CJMInAppTypeAlert),
            @"interstitial-image": @(CJMInAppTypeInterstitialImage),
            @"half-interstitial-image": @(CJMInAppTypeHalfInterstitialImage),
            @"cover-image": @(CJMInAppTypeCoverImage)
        };
    }
    
    NSNumber *_type = type != nil ? _inAppTypeMap[type] : @(CJMInAppTypeUnknown);
    if (_type == nil) {
        _type = @(CJMInAppTypeUnknown);
    }
    return [_type integerValue];
}

+ (NSBundle *)bundle {
#if CLEVERTAP_NO_INAPP_SUPPORT
    return nil;
#else
    return [CJMInAppResources bundle];
#endif
}

+ (NSString *)XibNameForControllerName:(NSString *)controllerName {
#if CLEVERTAP_NO_INAPP_SUPPORT
    return nil;
#else
    return [CJMInAppResources XibNameForControllerName:controllerName];
#endif
}

+ (UIImage *)imageForName:(NSString *)name type:(NSString *)type {
#if CLEVERTAP_NO_INAPP_SUPPORT
    return nil;
#else
    return [CJMInAppResources imageForName:name type:type];
#endif
    
}

+ (UIColor * _Nullable)CJM_colorWithHexString:(NSString *)string {
    
    return  [self CJM_colorWithHexString:string withAlpha:1.0];
}

+ (UIColor * _Nullable)CJM_colorWithHexString:(NSString *)string withAlpha:(CGFloat)alpha {
    
    if (![string isKindOfClass:[NSString class]] || [string length] == 0) {
        return [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
    }
    
    // Convert hex string to an integer
    unsigned int hexint = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:string];
    
    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet
                                       characterSetWithCharactersInString:@"#"]];
    [scanner scanHexInt:&hexint];
    
    // Create color object, specifying alpha
    UIColor *color =
    [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255
                    green:((CGFloat) ((hexint & 0xFF00) >> 8))/255
                     blue:((CGFloat) (hexint & 0xFF))/255
                    alpha:alpha];
    
    return color;
}

@end
