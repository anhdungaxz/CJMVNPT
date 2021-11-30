#import <Foundation/Foundation.h>

@interface CJMTypeDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSString *name;

@end

