#import <objc/runtime.h>
#import "CJMSwizzler.h"
#import "CJMConstants.h"

#define MIN_ARGS 2
#define MAX_ARGS 5

@interface CJMSwizzle : NSObject

@property (nonatomic, assign) Class class;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) IMP originalMethod;
@property (nonatomic, assign) uint numArgs;
@property (nonatomic, copy) NSMapTable *blocks;

- (instancetype)initWithBlock:(swizzleBlock)aBlock
                        named:(NSString *)aName
                     forClass:(Class)aClass
                     selector:(SEL)aSelector
               originalMethod:(IMP)aMethod
                  withNumArgs:(uint)numArgs;

@end

static NSMapTable *swizzles;

static void CJM_swizzledMethod_2(id self, SEL _cmd){
    Method aMethod = class_getInstanceMethod([self class], _cmd);
    CJMSwizzle *swizzle = (CJMSwizzle *)[swizzles objectForKey:MAPTABLE_ID(aMethod)];
    if (swizzle) {
        ((void(*)(id, SEL))swizzle.originalMethod)(self, _cmd);
        NSEnumerator *blocks = [swizzle.blocks objectEnumerator];
        swizzleBlock block;
        while ((block = [blocks nextObject])) {
            block(self, _cmd);
        }
    }
}

static void CJM_swizzledMethod_3(id self, SEL _cmd, id arg) {
    Method aMethod = class_getInstanceMethod([self class], _cmd);
    CJMSwizzle *swizzle = (CJMSwizzle *)[swizzles objectForKey:MAPTABLE_ID(aMethod)];
    if (swizzle) {
        ((void(*)(id, SEL, id))swizzle.originalMethod)(self, _cmd, arg);
        
        NSEnumerator *blocks = [swizzle.blocks objectEnumerator];
        swizzleBlock block;
        while ((block = [blocks nextObject])) {
            block(self, _cmd, arg);
        }
    }
}

static void CJM_swizzledMethod_4(id self, SEL _cmd, id arg, id arg2) {
    Method aMethod = class_getInstanceMethod([self class], _cmd);
    CJMSwizzle *swizzle = (CJMSwizzle *)[swizzles objectForKey:(__bridge id)((void *)aMethod)];
    if (swizzle) {
        ((void(*)(id, SEL, id, id))swizzle.originalMethod)(self, _cmd, arg, arg2);
        NSEnumerator *blocks = [swizzle.blocks objectEnumerator];
        swizzleBlock block;
        while ((block = [blocks nextObject])) {
            block(self, _cmd, arg, arg2);
        }
    }
}

static void CJM_swizzledMethod_5(id self, SEL _cmd, id arg, id arg2, id arg3) {
    Method aMethod = class_getInstanceMethod([self class], _cmd);
    CJMSwizzle *swizzle = (CJMSwizzle *)[swizzles objectForKey:(__bridge id)((void *)aMethod)];
    if (swizzle) {
        ((void(*)(id, SEL, id, id, id))swizzle.originalMethod)(self, _cmd, arg, arg2, arg3);
        NSEnumerator *blocks = [swizzle.blocks objectEnumerator];
        swizzleBlock block;
        while ((block = [blocks nextObject])) {
            block(self, _cmd, arg, arg2, arg3);
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
static void (*CJM_swizzledMethods[MAX_ARGS - MIN_ARGS + 1])() = {CJM_swizzledMethod_2, CJM_swizzledMethod_3, CJM_swizzledMethod_4, CJM_swizzledMethod_5};
#pragma clang diagnostic pop

@implementation CJMSwizzler

+ (void)initialize {
    swizzles = [NSMapTable mapTableWithKeyOptions:(NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality)
                                     valueOptions:(NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality)];
}

+ (void)printSwizzles {
    NSEnumerator *en = [swizzles objectEnumerator];
    CJMSwizzle *swizzle;
    while ((swizzle = (CJMSwizzle *)[en nextObject])) {
        CJMLogStaticDebug(@"%@", swizzle);
    }
}

+ (CJMSwizzle *)swizzleForMethod:(Method)aMethod {
    return (CJMSwizzle *)[swizzles objectForKey:MAPTABLE_ID(aMethod)];
}

+ (void)removeSwizzleForMethod:(Method)aMethod {
    [swizzles removeObjectForKey:MAPTABLE_ID(aMethod)];
}

+ (void)setSwizzle:(CJMSwizzle *)swizzle forMethod:(Method)aMethod {
    [swizzles setObject:swizzle forKey:MAPTABLE_ID(aMethod)];
}

+ (BOOL)isLocallyDefinedMethod:(Method)aMethod onClass:(Class)aClass {
    uint count;
    BOOL isLocal = NO;
    Method *methods = class_copyMethodList(aClass, &count);
    for (NSUInteger i = 0; i < count; i++) {
        if (aMethod == methods[i]) {
            isLocal = YES;
            break;
        }
    }
    free(methods);
    return isLocal;
}

+ (void)CJM_swizzleSelector:(SEL)aSelector onClass:(Class)aClass withBlock:(swizzleBlock)aBlock named:(NSString *)aName {
    Method aMethod = class_getInstanceMethod(aClass, aSelector);
    if (aMethod) {
        uint numArgs = method_getNumberOfArguments(aMethod);
        if (numArgs >= MIN_ARGS && numArgs <= MAX_ARGS) {
            
            BOOL isLocal = [self isLocallyDefinedMethod:aMethod onClass:aClass];
            IMP swizzledMethod = (IMP)CJM_swizzledMethods[numArgs - 2];
            CJMSwizzle *swizzle = [self swizzleForMethod:aMethod];
            
            if (isLocal) {
                if (!swizzle) {
                    IMP originalMethod = method_getImplementation(aMethod);
                    
                    method_setImplementation(aMethod,swizzledMethod);
                    
                    swizzle = [[CJMSwizzle alloc] initWithBlock:aBlock named:aName forClass:aClass selector:aSelector originalMethod:originalMethod withNumArgs:numArgs];
                    [self setSwizzle:swizzle forMethod:aMethod];
                    
                } else {
                    [swizzle.blocks setObject:aBlock forKey:aName];
                }
            } else {
                IMP originalMethod = swizzle ? swizzle.originalMethod : method_getImplementation(aMethod);
                
                if (!class_addMethod(aClass, aSelector, swizzledMethod, method_getTypeEncoding(aMethod))) {
                    NSAssert(NO, @"SwizzlerAssert: Could not add swizzled for %@::%@, even though it didn't already exist locally", NSStringFromClass(aClass), NSStringFromSelector(aSelector));
                    return;
                }
                Method newMethod = class_getInstanceMethod(aClass, aSelector);
                if (aMethod == newMethod) {
                    NSAssert(NO, @"SwizzlerAssert: Newly added method for %@::%@ was the same as the old method", NSStringFromClass(aClass), NSStringFromSelector(aSelector));
                    return;
                }
                
                CJMSwizzle *newSwizzle = [[CJMSwizzle alloc] initWithBlock:aBlock named:aName forClass:aClass selector:aSelector originalMethod:originalMethod withNumArgs:numArgs];
                [self setSwizzle:newSwizzle forMethod:newMethod];
            }
        } else {
            NSAssert(NO, @"SwizzlerAssert: Cannot swizzle method with %d args", numArgs);
        }
    } else {
        NSAssert(NO, @"SwizzlerAssert: Cannot find method for %@ on %@", NSStringFromSelector(aSelector), NSStringFromClass(aClass));
    }
}

+ (void)unswizzleSelector:(SEL)aSelector onClass:(Class)aClass {
    Method aMethod = class_getInstanceMethod(aClass, aSelector);
    CJMSwizzle *swizzle = [self swizzleForMethod:aMethod];
    if (swizzle) {
        method_setImplementation(aMethod, swizzle.originalMethod);
        [self removeSwizzleForMethod:aMethod];
    }
}

+ (void)CJM_unswizzleSelector:(SEL)aSelector onClass:(Class)aClass named:(NSString *)aName {
    Method aMethod = class_getInstanceMethod(aClass, aSelector);
    CJMSwizzle *swizzle = [self swizzleForMethod:aMethod];
    if (swizzle) {
        if (aName) {
            [swizzle.blocks removeObjectForKey:aName];
        }
        if (!aName || swizzle.blocks.count == 0) {
            method_setImplementation(aMethod, swizzle.originalMethod);
            [self removeSwizzleForMethod:aMethod];
        }
    }
}

@end

@implementation CJMSwizzle

- (instancetype)init {
    if ((self = [super init])) {
        self.blocks = [NSMapTable mapTableWithKeyOptions:(NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality)
                                            valueOptions:(NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality)];
    }
    return self;
}

- (instancetype)initWithBlock:(swizzleBlock)aBlock
                        named:(NSString *)aName
                     forClass:(Class)aClass
                     selector:(SEL)aSelector
               originalMethod:(IMP)aMethod
                  withNumArgs:(uint)numArgs {
    if ((self = [self init])) {
        self.class = aClass;
        self.selector = aSelector;
        self.numArgs = numArgs;
        self.originalMethod = aMethod;
        [self.blocks setObject:aBlock forKey:aName];
    }
    return self;
}

- (NSString *)description {
    NSString *descriptors = @"";
    NSString *key;
    NSEnumerator *keys = [self.blocks keyEnumerator];
    while ((key = [keys nextObject])) {
        descriptors = [descriptors stringByAppendingFormat:@"\t%@ : %@\n", key, [self.blocks objectForKey:key]];
    }
    return [NSString stringWithFormat:@"Swizzle on %@::%@ [\n%@]", NSStringFromClass(self.class), NSStringFromSelector(self.selector), descriptors];
}

@end

