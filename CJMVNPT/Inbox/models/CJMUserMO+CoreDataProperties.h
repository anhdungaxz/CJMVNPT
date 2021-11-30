#import "CJMUserMO.h"

@class CJMMessageMO;

NS_ASSUME_NONNULL_BEGIN

@interface CJMUserMO (CoreDataProperties)

+ (instancetype)fetchOrCreateFromJSON:(NSDictionary *)json forContext:(NSManagedObjectContext *)context;
- (BOOL)updateMessages:(NSArray<NSDictionary*> *)messages forContext:(NSManagedObjectContext *)context;

@property (nullable, nonatomic, copy) NSString *accountId;
@property (nullable, nonatomic, copy) NSString *guid;
@property (nullable, nonatomic, copy) NSString *identifier;
@property (nullable, nonatomic, retain) NSOrderedSet<CJMMessageMO *> *messages;

@end

@interface CJMUserMO (CoreDataGeneratedAccessors)

@end

NS_ASSUME_NONNULL_END
