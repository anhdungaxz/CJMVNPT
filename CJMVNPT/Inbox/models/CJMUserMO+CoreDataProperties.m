#import "CJMUserMO.h"
#import "CJMMessageMO.h"
#import "CJMConstants.h"

@interface CJMUserMO ()
- (void)insertObject:(CJMMessageMO *)value inMessagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMessagesAtIndex:(NSUInteger)idx;
- (void)insertMessages:(NSArray<CJMMessageMO *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMessagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMessagesAtIndex:(NSUInteger)idx withObject:(CJMMessageMO *)value;
- (void)replaceMessagesAtIndexes:(NSIndexSet *)indexes withMessages:(NSArray<CJMMessageMO *> *)values;
- (void)addMessagesObject:(CJMMessageMO *)value;
- (void)removeMessagesObject:(CJMMessageMO *)value;
- (void)addMessages:(NSOrderedSet<CJMMessageMO *> *)values;
- (void)removeMessages:(NSOrderedSet<CJMMessageMO *> *)values;
@end

@implementation CJMUserMO (CoreDataProperties)

+ (instancetype)fetchOrCreateFromJSON:(NSDictionary *)json forContext:(NSManagedObjectContext *)context {
    CJMUserMO *_user;
    @try {
        NSString *identifier = json[@"identifier"];
        
        if (!identifier) {
            CJMLogStaticInternal(@"CTUserMO fetchOrCreate for: %@ requires an identifier returning nil", json);
            return nil;
        }
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"CJMUser"];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", identifier]];
        
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
        if (!results) {
            CJMLogStaticDebug(@"Error fetching CTUser objects: %@\n%@", [error localizedDescription], [error userInfo]);
        }
        if ([results count] > 0) {
            _user = results[0];
            CJMLogStaticInternal(@"Found existing %@", _user);
        } else {
            _user = [[CJMUserMO alloc] initWithJSON:json forContext:context];
        }
        
    } @catch (NSException *e) {
        CJMLogStaticDebug(@"Failed to fetchOrCreate CTUser: %@", e.debugDescription);
        return nil;
    }
    return _user;
}

- (instancetype)initWithJSON:(NSDictionary *)json forContext:(NSManagedObjectContext *)context {
    CJMLogStaticInternal(@"Initializing new CTUserMO with data: %@", json);
    self = [self initWithEntity:[NSEntityDescription entityForName:@"CJMUser" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    NSString *accountId = json[@"accountId"];
    if (accountId) {
        self.accountId = accountId;
    }
    NSString *guid = json[@"guid"];
    if (guid) {
        self.guid = guid;
    }
    NSString *identifier = json[@"identifier"];
    if (identifier) {
        self.identifier = identifier;
    }
    return self;
}

- (BOOL)updateMessages:(NSArray<NSDictionary*> *)messages forContext:(NSManagedObjectContext *)context {
    // de-dupe incoming batch
    NSMutableDictionary *deduped = [NSMutableDictionary new];
    for (NSDictionary *message in messages) {
        NSString *messageId = message[@"_id"];
        if (!messageId) {
            CJMLogStaticDebug(@"CTUserMO dropping message: %@, missing id property", message);
            continue;
        }
        NSDictionary *existing = deduped[messageId];
        if (!existing) {
            deduped[messageId] = message;
        } else {
            if ([message[@"date"] longValue] > [existing[@"date"] longValue]) {
                deduped[messageId] = message;
            }
        }
    }
    
    BOOL haveUpdates = NO;
    NSMutableOrderedSet *newMessages = [NSMutableOrderedSet new];
    NSTimeInterval now = (int)[[NSDate date] timeIntervalSince1970];
    
    for (NSString *key in [deduped allKeys]) {
        NSDictionary *message = deduped[key];
        NSOrderedSet *results = [self.messages filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"id == %@", message[@"_id"]]];
        
        BOOL existing = results && [results count] > 0;
        if (existing) {
            CJMMessageMO *msg = (CJMMessageMO*)results[0];
            int ttl = (int)msg.expires;
            if (ttl > 0 && now >= ttl) {
                CJMLogStaticInternal(@"%@: message expires: %@, deleting", self, message);
                [context deleteObject:msg];
                haveUpdates = YES;
            } else {
                CJMLogStaticInternal(@"%@: already have message: %@, updating", self, message);
                [msg setValue:message forKey:@"json"];
                haveUpdates = YES;
            }
            continue;
        } else {
            int ttl = (int)[message[@"wzrk_ttl"] longValue];
            if (ttl > 0 && now >= ttl){
                CJMLogStaticInternal(@"%@: message expires: %@, deleting", self, message);
                continue;
            }
        }
        CJMMessageMO *_msg = [[CJMMessageMO alloc] initWithJSON:message forContext:context];
        if (_msg) {
            [newMessages addObject:_msg];
        }
    }
    
    if ([newMessages count] > 0) {  
        [self addMessages:newMessages];
        haveUpdates = YES;
    }
    return haveUpdates;
}

@dynamic accountId;
@dynamic guid;
@dynamic identifier;
@dynamic messages;

@end
