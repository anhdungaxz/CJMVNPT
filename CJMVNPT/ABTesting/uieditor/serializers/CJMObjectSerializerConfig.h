#import <Foundation/Foundation.h>

@class CJMEnumDescription;
@class CJMClassDescription;
@class CJMTypeDescription;

@interface CJMObjectSerializerConfig : NSObject

@property (nonatomic, readonly) NSArray *classDescriptions;
@property (nonatomic, readonly) NSArray *enumDescriptions;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (CJMTypeDescription *)typeWithName:(NSString *)name;
- (CJMEnumDescription *)enumWithName:(NSString *)name;
- (CJMClassDescription *)classWithName:(NSString *)name;

@end
