#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJMInAppResources : NSObject

+ (NSBundle *)bundle;
+ (NSString *)XibNameForControllerName:(NSString *)controllerName;
+ (UIImage *)imageForName:(NSString *)name type:(NSString *)type;
+ (UIApplication *_Nullable)getSharedApplication;

@end

NS_ASSUME_NONNULL_END
