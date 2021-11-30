#import "CJMMessageMO.h"

@class CJMUserMO;

@interface CJMMessageMO (CoreDataProperties)
- (instancetype _Nullable)initWithJSON:(NSDictionary *_Nullable)json forContext:(NSManagedObjectContext *_Nullable)context;
- (NSDictionary *_Nullable)toJSON;

@property (nonatomic, assign) NSUInteger date;
@property (nonatomic, assign) NSUInteger expires;
@property (nullable, nonatomic, copy) NSString *wzrk_id;
@property (nullable, nonatomic, copy) NSString *id;
@property (nullable, nonatomic, copy) id tags;
@property (nullable, nonatomic, retain) CJMUserMO *user;
@property (nullable, nonatomic, copy) id json;
@property (nonatomic, assign) BOOL isRead;

@end
