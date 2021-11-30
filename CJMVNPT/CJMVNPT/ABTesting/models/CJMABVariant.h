#import <Foundation/Foundation.h>

@interface CJMABVariant : NSObject <NSCoding>

@property (nonatomic) NSString *variantId;
@property (nonatomic) NSString *experimentId;
@property (nonatomic) NSUInteger variantVersion;

@property (nonatomic, readonly) BOOL running;
@property (nonatomic, readonly) BOOL finished;

@property (nonatomic, readonly) NSArray<NSDictionary*>* vars;

+ (CJMABVariant *)variantWithData:(NSDictionary *)variantData;

- (void)addActions:(NSArray *)actions andApply:(BOOL)apply;
- (void)removeActionWithName:(NSString *)name;

- (void)applyActions;

- (void)revertActions;

- (void)finish;

- (void)restart;

- (void)cleanup;

@end

@interface CJMABVariantAction : NSObject <NSCoding>

@end


