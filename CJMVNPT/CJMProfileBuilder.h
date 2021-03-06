#import <Foundation/Foundation.h>

@class CJMValidationResult;
@class CJMLocalDataStore;

@interface CJMProfileBuilder : NSObject

+ (void)build:(NSDictionary *_Nonnull)profile completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)buildGraphUser:(id _Nonnull)graphUser completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)buildGooglePlusUser:(id _Nonnull)googleUser completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)buildRemoveValueForKey:(NSString *_Nonnull)key completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)buildSetMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nullable)key localDataStore:(CJMLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSArray* _Nullable updatedMultiValue, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)buildAddMultiValue:(NSString *_Nonnull)value forKey:(NSString *_Nullable)key localDataStore:(CJMLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)buildAddMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nullable)key localDataStore:(CJMLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)buildRemoveMultiValue:(NSString *_Nonnull)value forKey:(NSString *_Nullable)key localDataStore:(CJMLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CJMValidationResult*>* _Nullable errors))completion;

+ (void)buildRemoveMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nullable)key localDataStore:(CJMLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CJMValidationResult*>* _Nullable errors))completion;

@end
