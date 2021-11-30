#import <Foundation/Foundation.h>
#import "CJMVar.h"

@interface CJMVarCache : NSObject

- (void)registerVarWithName:(NSString* _Nonnull)name type:(CJMVarType)type andValue:(id _Nullable)value;
- (CJMVar* _Nullable)getVarWithName:(NSString* _Nonnull)name;
- (void)clearVarWithName:(NSString* _Nonnull)name;
- (void)reset;
- (NSArray<NSDictionary*>* _Nonnull)serializeVars;

@end
