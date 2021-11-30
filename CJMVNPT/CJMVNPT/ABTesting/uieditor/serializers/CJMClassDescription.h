#import "CJMTypeDescription.h"

@interface CJMClassDescription : CJMTypeDescription

@property (nonatomic, readonly) CJMClassDescription *superclassDescription;
@property (nonatomic, readonly) NSArray *propertyDescriptions;
@property (nonatomic, readonly) NSArray *delegateDetails;

- (instancetype)initWithSuperclassDescription:(CJMClassDescription *)superclassDescription dictionary:(NSDictionary *)dictionary;

- (BOOL)isDescriptionForKindOfClass:(Class)aClass;

@end

@interface CJMDelegateDetail : NSObject

@property (nonatomic, readonly) NSString *selectorName;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

