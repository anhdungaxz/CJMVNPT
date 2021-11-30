#import "CJMObjectSerializerConfig.h"
#import "CJMTypeDescription.h"
#import "CJMEnumDescription.h"
#import "CJMClassDescription.h"

@implementation CJMObjectSerializerConfig {
    NSDictionary *_classes;
    NSDictionary *_enums;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        NSMutableDictionary *classDescriptions = [NSMutableDictionary dictionary];
        for (NSDictionary *dict in dictionary[@"classes"]) {
            NSString *superclassName = dict[@"superclass"];
            CJMClassDescription *superclassDescription = superclassName ? classDescriptions[superclassName] : nil;
            CJMClassDescription *classDescription = [[CJMClassDescription alloc] initWithSuperclassDescription:superclassDescription
                                                                                                  dictionary:dict];
            classDescriptions[classDescription.name] = classDescription;
        }
        
        NSMutableDictionary *enumDescriptions = [NSMutableDictionary dictionary];
        for (NSDictionary *dict in dictionary[@"enums"]) {
            CJMEnumDescription *enumDescription = [[CJMEnumDescription alloc] initWithDictionary:dict];
            enumDescriptions[enumDescription.name] = enumDescription;
        }
        
        _classes = [classDescriptions copy];
        _enums = [enumDescriptions copy];
    }
    
    return self;
}

- (NSArray *)classDescriptions {
    return _classes.allValues;
}

- (CJMEnumDescription *)enumWithName:(NSString *)name {
    return _enums[name];
}

- (CJMClassDescription *)classWithName:(NSString *)name {
    return _classes[name];
}

- (CJMTypeDescription *)typeWithName:(NSString *)name {
    CJMEnumDescription *enumDescription = [self enumWithName:name];
    if (enumDescription) {
        return enumDescription;
    }
    
    CJMClassDescription *classDescription = [self classWithName:name];
    if (classDescription) {
        return classDescription;
    }
    return nil;
}

@end
