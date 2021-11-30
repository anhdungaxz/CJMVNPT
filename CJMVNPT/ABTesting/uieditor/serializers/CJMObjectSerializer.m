#import <objc/runtime.h>
#import "CJMConstants.h"

#import "CJMEnumDescription.h"
#import "CJMClassDescription.h"
#import "CJMObjectSerializer.h"
#import "NSInvocation+CJMHelper.h"
#import "CJMPropertyDescription.h"
#import "CJMObjectIdentityProvider.h"
#import "CJMObjectSerializerConfig.h"
#import "CJMObjectSerializerContext.h"

@interface CJMObjectSerializer ()

@end

@implementation CJMObjectSerializer {
    CJMObjectSerializerConfig *_configuration;
    CJMObjectIdentityProvider *_objectIdentityProvider;
}

- (instancetype)initWithConfiguration:(CJMObjectSerializerConfig *)configuration objectIdentityProvider:(CJMObjectIdentityProvider *)objectIdentityProvider {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _objectIdentityProvider = objectIdentityProvider;
    }
    return self;
}

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject {
    if (!rootObject) return nil;
    CJMObjectSerializerContext *context = [[CJMObjectSerializerContext alloc] initWithRootObject:rootObject];
    
    while ([context hasUnvisitedObjects]){
        [self visitObject:[context dequeueUnvisitedObject] withContext:context];
    }
    
    return @{@"objects": [context allSerializedObjects],
             @"rootObject": [_objectIdentityProvider identifierForObject:rootObject]
    };
}

- (void)visitObject:(NSObject *)object withContext:(CJMObjectSerializerContext *)context {
    if (object == nil || context == nil) return;
    [context addVisitedObject:object];
    NSMutableDictionary *propertyValues = [NSMutableDictionary dictionary];
    
    CJMClassDescription *classDescription = [self classDescriptionForObject:object];
    if (classDescription) {
        for (CJMPropertyDescription *propertyDescription in [classDescription propertyDescriptions]) {
            if ([propertyDescription shouldReadPropertyValueForObject:object]) {
                id propertyValue = [self propertyValueForObject:object withPropertyDescription:propertyDescription context:context];
                propertyValues[propertyDescription.name] = propertyValue ?: [NSNull null];
            }
        }
    }
    
    NSMutableArray *delegateMethods = [NSMutableArray array];
    id delegate;
    SEL delegateSelector = @selector(delegate);
    if ([classDescription delegateDetails].count > 0 && [object respondsToSelector:delegateSelector]) {
        delegate = ((id (*)(id, SEL))[object methodForSelector:delegateSelector])(object, delegateSelector);
        for (CJMDelegateDetail *delegateInfo in [classDescription delegateDetails]) {
            if ([delegate respondsToSelector:NSSelectorFromString(delegateInfo.selectorName)]) {
                [delegateMethods addObject:delegateInfo.selectorName];
            }
        }
    }
    
    NSDictionary *serializedObject = @{
        @"id": [_objectIdentityProvider identifierForObject:object],
        @"class": [self classHierarchyArrayForObject:object],
        @"properties": propertyValues,
        @"delegate": @{
                @"class": delegate ? NSStringFromClass([delegate class]) : @"",
                @"selectors": delegateMethods
        }
    };
    
    [context addSerializedObject:serializedObject];
}

- (NSArray *)classHierarchyArrayForObject:(NSObject *)object {
    NSMutableArray *classHierarchy = [NSMutableArray array];
    
    Class aClass = [object class];
    while (aClass)
    {
        [classHierarchy addObject:NSStringFromClass(aClass)];
        aClass = [aClass superclass];
    }
    return [classHierarchy copy];
}

- (NSArray *)allValuesForType:(NSString *)typeName {
    
    if (!typeName) return nil;
    
    CJMTypeDescription *typeDescription = [_configuration typeWithName:typeName];
    if ([typeDescription isKindOfClass:[CJMEnumDescription class]]) {
        CJMEnumDescription *enumDescription = (CJMEnumDescription *)typeDescription;
        return [enumDescription allValues];
    }
    return @[];
}

- (NSArray *)parameterVariationsForPropertySelector:(CJMPropertySelectorDescription *)selectorDescription {
    if (selectorDescription.parameters.count > 1) {
        CJMLogStaticDebug(@"Selectors with only 0 and 1 arugments are supported by CleverTap SDK.");
        return nil;
    }
    
    NSMutableArray *variations = [NSMutableArray array];
    
    if (selectorDescription.parameters.count > 0) {
        CJMPropertySelectorParameterDescription *parameterDescription = selectorDescription.parameters[0];
        for (id value in [self allValuesForType:parameterDescription.type]) {
            [variations addObject:@[ value ]];
        }
    } else {
        [variations addObject:@[]];
    }
    
    return [variations copy];
}

- (id)instanceVariableValueForObject:(id)object propertyDescription:(CJMPropertyDescription *)propertyDescription {
    
    if (object == nil || propertyDescription == nil) return nil;
    
    Ivar ivar = class_getInstanceVariable([object class], [propertyDescription.name UTF8String]);
    if (ivar) {
        const char *objCType = ivar_getTypeEncoding(ivar);
        
        ptrdiff_t ivarOffset = ivar_getOffset(ivar);
        const void *objectBaseAddress = (__bridge const void *)object;
        const void *ivarAddress = (((const uint8_t *)objectBaseAddress) + ivarOffset);
        
        switch (objCType[0])
        {
            case _C_ID:       return object_getIvar(object, ivar);
            case _C_CHR:      return @(*((char *)ivarAddress));
            case _C_UCHR:     return @(*((unsigned char *)ivarAddress));
            case _C_SHT:      return @(*((short *)ivarAddress));
            case _C_USHT:     return @(*((unsigned short *)ivarAddress));
            case _C_INT:      return @(*((int *)ivarAddress));
            case _C_UINT:     return @(*((unsigned int *)ivarAddress));
            case _C_LNG:      return @(*((long *)ivarAddress));
            case _C_ULNG:     return @(*((unsigned long *)ivarAddress));
            case _C_LNG_LNG:  return @(*((long long *)ivarAddress));
            case _C_ULNG_LNG: return @(*((unsigned long long *)ivarAddress));
            case _C_FLT:      return @(*((float *)ivarAddress));
            case _C_DBL:      return @(*((double *)ivarAddress));
            case _C_BOOL:     return @(*((_Bool *)ivarAddress));
            case _C_SEL:      return NSStringFromSelector(*((SEL*)ivarAddress));
            default:
                NSAssert(NO, @"Not supported return type!");
                break;
        }
    }
    
    return nil;
}

- (NSInvocation *)invocationForObject:(id)object withSelectorDescription:(CJMPropertySelectorDescription *)selectorDescription {
    NSUInteger __unused parameterCount = selectorDescription.parameters.count;
    
    SEL aSelector = NSSelectorFromString(selectorDescription.selectorName);
    NSAssert(aSelector != nil, @"Expected non-nil selector!");
    
    NSMethodSignature *methodSignature = [object methodSignatureForSelector:aSelector];
    NSInvocation *invocation = nil;
    
    if (methodSignature) {
        NSAssert(methodSignature.numberOfArguments == (parameterCount + 2), @"Unexpected number of arguments!");
        
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.selector = aSelector;
    }
    return invocation;
}

- (id)propertyValue:(id)propertyValue propertyDescription:(CJMPropertyDescription *)propertyDescription context:(CJMObjectSerializerContext *)context {
    if (propertyValue != nil) {
        if ([context isVisitedObject:propertyValue]) {
            return [_objectIdentityProvider identifierForObject:propertyValue];
        } else if ([self isNestedObjectType:propertyDescription.type]){
            [context enqueueUnvisitedObject:propertyValue];
            return [_objectIdentityProvider identifierForObject:propertyValue];
        } else if ([propertyValue isKindOfClass:[NSArray class]] || [propertyValue isKindOfClass:[NSSet class]]){
            NSMutableArray *arrayOfIdentifiers = [NSMutableArray array];
            for (id value in propertyValue) {
                if ([context isVisitedObject:value] == NO) {
                    [context enqueueUnvisitedObject:value];
                }
                
                [arrayOfIdentifiers addObject:[_objectIdentityProvider identifierForObject:value]];
            }
            propertyValue = [arrayOfIdentifiers copy];
        }
    }
    return [propertyDescription.valueTransformer transformedValue:propertyValue];
}

- (id)propertyValueForObject:(NSObject *)object withPropertyDescription:(CJMPropertyDescription *)propertyDescription context:(CJMObjectSerializerContext *)context {
    NSMutableArray *values = [NSMutableArray array];
    
    CJMPropertySelectorDescription *selectorDescription = propertyDescription.getSelectorDescription;
    
    if (propertyDescription.useKeyValueCoding) {
        id valueForKey = [object valueForKey:selectorDescription.selectorName];
        id value = [self propertyValue:valueForKey
                   propertyDescription:propertyDescription
                               context:context];
        NSDictionary *valueDictionary = @{@"value": (value ?: [NSNull null])};
        [values addObject:valueDictionary];
        
    }  else if (propertyDescription.useInstanceVariableAccess) {
        id valueForIvar = [self instanceVariableValueForObject:object propertyDescription:propertyDescription];
        id value = [self propertyValue:valueForIvar
                   propertyDescription:propertyDescription
                               context:context];
        
        NSDictionary *valueDictionary = @{@"value": (value ?: [NSNull null])};
        [values addObject:valueDictionary];
    } else {
        NSInvocation *invocation = [self invocationForObject:object withSelectorDescription:selectorDescription];
        if (invocation) {
            NSArray *parameterVariations = [self parameterVariationsForPropertySelector:selectorDescription];
            for (NSArray *parameters in parameterVariations) {
                [invocation CJM_setArgumentsFromArray:parameters];
                [invocation invokeWithTarget:object];
                id returnValue = [invocation CJM_returnValue];
                id value = [self propertyValue:returnValue
                           propertyDescription:propertyDescription
                                       context:context];
                NSDictionary *valueDictionary = @{
                    @"where": @{ @"parameters": parameters },
                    @"value": (value ?: [NSNull null])
                };
                [values addObject:valueDictionary];
            }
        }
    }
    return @{@"values": values};
}

- (BOOL)isNestedObjectType:(NSString *)typeName {
    return [_configuration classWithName:typeName] != nil;
}

- (CJMClassDescription *)classDescriptionForObject:(NSObject *)object {
    if (!object) return nil;
    Class aClass = [object class];
    while (aClass != nil)
    {
        CJMClassDescription *classDescription = [_configuration classWithName:NSStringFromClass(aClass)];
        if (classDescription) {
            return classDescription;
        }
        
        aClass = [aClass superclass];
    }
    return nil;
}

@end
