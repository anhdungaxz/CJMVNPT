
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CJMVideoThumbnailGenerator : NSObject

- (void)generateImageFromUrl:(NSString *)videoURL withCompletionBlock:(void (^)(UIImage *image, NSString *sourceUrl))completion;
- (void)cleanup;

@end
