#import <Foundation/Foundation.h>

typedef NS_ENUM(int, CJMValidatorContext) {
    CJMValidatorContextEvent,
    CJMValidatorContextProfile,
    CJMValidatorContextOther
};

@class CJMValidationResult;

@interface CJMValidator : NSObject

+ (CJMValidationResult *)cleanEventName:(NSString *)name;

+ (CJMValidationResult *)cleanObjectKey:(NSString *)name;

+ (CJMValidationResult *)cleanMultiValuePropertyKey:(NSString *)name;

+ (CJMValidationResult *)cleanMultiValuePropertyValue:(NSString *)value;

+ (CJMValidationResult *)cleanMultiValuePropertyArray:(NSArray *)multi forKey:(NSString*)key;

+ (CJMValidationResult *)cleanObjectValue:(NSObject *)o context:(CJMValidatorContext)context;

+ (BOOL)isRestrictedEventName:(NSString *)name;

+ (BOOL)isDiscaredEventName:(NSString *)name;

+ (void)setDiscardedEvents:(NSArray *)events;

+ (BOOL)isValidCJMId:(NSString *)cjmID;

@end
