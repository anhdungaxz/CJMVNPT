#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CJMInAppType){
    CJMInAppTypeUnknown,
    CJMInAppTypeHTML,
    CJMInAppTypeInterstitial,
    CJMInAppTypeHalfInterstitial,
    CJMInAppTypeCover,
    CJMInAppTypeHeader,
    CJMInAppTypeFooter,
    CJMInAppTypeAlert,
    CJMInAppTypeInterstitialImage,
    CJMInAppTypeHalfInterstitialImage,
    CJMInAppTypeCoverImage,
};

@interface CJMInAppUtils : NSObject

+ (CJMInAppType)inAppTypeFromString:(NSString*_Nonnull)type;
+ (NSBundle *_Nullable)bundle;
+ (NSString *_Nullable)XibNameForControllerName:(NSString *_Nonnull)controllerName;
+ (UIImage *_Nullable)imageForName:(NSString *_Nonnull)name type:(NSString *_Nonnull)type;
+ (UIColor *_Nullable)CJM_colorWithHexString:(NSString* _Nonnull)string;
+ (UIColor * _Nullable)CJM_colorWithHexString:(NSString * _Nonnull)string withAlpha:(CGFloat)alpha;

@end
