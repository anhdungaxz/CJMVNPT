#import <Foundation/Foundation.h>

@class CJMInstanceConfig;
@class CJMEventDetail;

@interface CJMLocalDataStore : NSObject

- (instancetype)initWithConfig:(CJMInstanceConfig *)config andProfileValues:(NSDictionary*)profileValues;

- (void)persistEvent:(NSDictionary *)event;

- (void)addDataSyncFlag:(NSMutableDictionary *)event;

- (NSDictionary*)syncWithRemoteData:(NSDictionary *)responseData;

- (NSTimeInterval)getFirstTimeForEvent:(NSString *)event;

- (NSTimeInterval)getLastTimeForEvent:(NSString *)event;

- (int)getOccurrencesForEvent:(NSString *)event;

- (NSDictionary *)getEventHistory;

- (CJMEventDetail *)getEventDetail:(NSString *)event;

- (void)setProfileFields:(NSDictionary *)fields;

- (void)setProfileFieldWithKey:(NSString *)key andValue:(id)value;

- (void)removeProfileFieldsWithKeys:(NSArray *)keys;

- (void)removeProfileFieldForKey:(NSString *)key;

- (id)getProfileFieldForKey:(NSString *)key;

- (void)persistLocalProfileIfRequired;

- (NSDictionary*)generateBaseProfile;

- (void)changeUser;

@end
