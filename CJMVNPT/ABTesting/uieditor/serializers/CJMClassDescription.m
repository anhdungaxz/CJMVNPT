#import "CJMClassDescription.h"
#import "CJMPropertyDescription.h"

@implementation CJMDelegateDetail

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _selectorName = dictionary[@"selector"];
    }
    return self;
}

@end

@implementation CJMClassDescription {
    NSArray *_propertyDescriptions;
    NSArray *_delegateDetails;
}

- (instancetype)initWithSuperclassDescription:(CJMClassDescription *)superclassDescription dictionary:(NSDictionary *)dictionary {
    self = [super initWithDictionary:dictionary];
    if (self) {
        _superclassDescription = superclassDescription;
        NSMutableArray *propertyDescriptions = [NSMutableArray array];
        for (NSDictionary *propertyDictionary in dictionary[@"properties"]) {
            [propertyDescriptions addObject:[[CJMPropertyDescription alloc] initWithDictionary:propertyDictionary]];
        }
        
        _propertyDescriptions = [propertyDescriptions copy];
        NSMutableArray *delegateDetails = [NSMutableArray array];
        for (NSDictionary *delegateDetailsDictionary in dictionary[@"delegateImplements"]) {
            [delegateDetails addObject:[[CJMDelegateDetail alloc] initWithDictionary:delegateDetailsDictionary]];
        }
        _delegateDetails = [_delegateDetails copy];
    }
    return self;
}

- (NSArray *)propertyDescriptions {
    NSMutableDictionary *allPropertyDescriptions = [NSMutableDictionary dictionary];
    CJMClassDescription *classDescription = self;
    while (classDescription) {
        for (CJMPropertyDescription *propertyDescription in classDescription->_propertyDescriptions) {
            if (!allPropertyDescriptions[propertyDescription.name]) {
                allPropertyDescriptions[propertyDescription.name] = propertyDescription;
            }
        }
        classDescription = classDescription.superclassDescription;
    }
    return allPropertyDescriptions.allValues;
}

- (BOOL)isDescriptionForKindOfClass:(Class)aClass {
    return [self.name isEqualToString:NSStringFromClass(aClass)] && [self.superclassDescription isDescriptionForKindOfClass:[aClass superclass]];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@:%p name='%@' superclass='%@'>", NSStringFromClass([self class]), (__bridge void *)self, self.name, self.superclassDescription ? self.superclassDescription.name : @""];
}

@end
