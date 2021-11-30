#import <Foundation/Foundation.h>
#import "CJMABTestUtils.h"

@interface CJMVar : NSObject

- (instancetype _Nonnull)initWithName:(NSString * _Nonnull)name type:(CJMVarType)type andValue:(id _Nullable)value;
- (void)updateWithValue:(id _Nonnull)value andType:(CJMVarType)type;

- (void)clearValue;
- (NSNumber * _Nullable)numberValue;
- (NSString * _Nullable)stringValue;
- (NSArray<id>* _Nullable)arrayValue;
- (NSDictionary<NSString *, id>* _Nullable)dictionaryValue;
- (NSDictionary* _Nonnull)toJSON;

@end
