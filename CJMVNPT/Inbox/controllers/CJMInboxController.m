
@import CoreData;
#import "CJMInboxController.h"
#import "CJMConstants.h"
#import "CJMUserMO.h"
#import "CJMMessageMO.h"

static NSManagedObjectContext *mainContext;
static NSManagedObjectContext *privateContext;

@interface CJMInboxController ()

@property (nonatomic, copy, readonly) NSString *accountId;
@property (nonatomic, copy, readonly) NSString *guid;
@property (nonatomic, copy, readonly) NSString *userIdentifier;
@property (nonatomic, strong, readonly) CJMUserMO *user;

@end

@implementation CJMInboxController

@synthesize count=_count;
@synthesize unreadCount=_unreadCount;
@synthesize messages=_messages;
@synthesize unreadMessages=_unreadMessages;


// blocking run off main thread
- (instancetype)initWithAccountId:(NSString *)accountId guid:(NSString *)guid {
    self =  [super init];
    if (self) {
        [self staticInit];
        _isInitialized = (mainContext != nil && privateContext != nil);
        if (_isInitialized) {
            _accountId = accountId;
            _guid = guid;
            NSString *userIdentifier = [NSString stringWithFormat:@"%@:%@", accountId, guid];
            _userIdentifier = userIdentifier;
            [privateContext performBlockAndWait:^{
                self->_user = [CJMUserMO fetchOrCreateFromJSON:@{@"accountId":accountId, @"guid":guid, @"identifier": userIdentifier} forContext:privateContext];
                [self _save];
            }];
        }
    }
    return self;
}

- (void)staticInit {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            NSURL *modelURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Inbox" withExtension:@"momd"];
            NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
            NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
            
            NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [context setPersistentStoreCoordinator:coordinator];
            
            NSPersistentStoreCoordinator *psc = [context persistentStoreCoordinator];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"CleverTap-Inbox.sqlite"];
            NSError *error = nil;
            NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
            if (!store) {
                CJMLogStaticDebug(@"Failed to initalize core data persistent store: %@\n%@", [error localizedDescription], [error userInfo]);
                return;
            }
            NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [private setParentContext:context];
            mainContext = context;
            privateContext = private;
        } @catch (NSException *e) {
            CJMLogStaticDebug(@"Failed to initalize core data store: %@", e.debugDescription);
            mainContext = nil;
            privateContext = nil;
        }
    });
}


#pragma mark - Public

- (void)updateMessages:(NSArray<NSDictionary*> *)messages {
    if (!self.isInitialized) return;
    [privateContext performBlock:^{
        CJMLogStaticInternal(@"%@: updating messages: %@", self.user, messages);
        BOOL haveUpdates = [self.user updateMessages:messages forContext:privateContext];
        if (haveUpdates) {
            [self notifyUpdate];
            [self _save];
        }
    }];
}

- (void)deleteMessageWithId:(NSString *)messageId {
    CJMMessageMO *message = [self _messageForId:messageId];
    if (!message) return;
    [self _deleteMessages:@[message]];
}

- (void)markReadMessageWithId:(NSString *)messageId {
    [privateContext performBlock:^{
        CJMMessageMO *message = [self _messageForId:messageId];
        if (message) {
            [message setValue:@YES forKey:@"isRead"];
            [self notifyUpdate];
            [self _save];
        }
    }];
}

- (NSDictionary *)messageForId:(NSString *)messageId {
    if (!self.isInitialized) return nil;
    CJMMessageMO *msg = [self _messageForId:messageId];
    if (!msg) {
        return nil;
    }
    return [msg toJSON];
}

- (NSUInteger)count {
    if (!self.isInitialized) return -1;
    return [self.messages count];
}

- (NSUInteger)unreadCount {
    if (!self.isInitialized) return -1;
    return [self.unreadMessages count];
}

- (NSArray<NSDictionary *> *)messages {
    if (!self.isInitialized) return nil;
    NSTimeInterval now = (int)[[NSDate date] timeIntervalSince1970];
    NSMutableArray *messages = [NSMutableArray new];
    NSMutableArray *toDelete = [NSMutableArray new];
    for (CJMMessageMO *msg in self.user.messages) {
        int ttl = (int)msg.expires;
        if (ttl > 0 && now >= ttl) {
            CJMLogStaticInternal(@"%@: message expires: %@, deleting", self, msg);
            [toDelete addObject:msg];
        } else {
            [messages addObject:[msg toJSON]];
        }
    }
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [messages sortUsingDescriptors:@[sortDescriptor]];
    
    if ([toDelete count] > 0) {
        [self _deleteMessages:toDelete];
    }
    return messages;
}

- (NSArray<NSDictionary *> *)unreadMessages {
    if (!self.isInitialized) return nil;
    NSTimeInterval now = (int)[[NSDate date] timeIntervalSince1970];
    NSMutableArray *messages = [NSMutableArray new];
    NSMutableArray *toDelete = [NSMutableArray new];
    NSOrderedSet *results = [self.user.messages filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"isRead == NO"]];
    for (CJMMessageMO *msg in results) {
        int ttl = (int)msg.expires;
        if (ttl > 0 && now >= ttl) {
            CJMLogStaticInternal(@"%@: message expires: %@, deleting", self, msg);
            [toDelete addObject:msg];
        } else {
            [messages addObject:[msg toJSON]];
        }
    }
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [messages sortUsingDescriptors:@[sortDescriptor]];
    
    if ([toDelete count] > 0) {
        [self _deleteMessages:toDelete];
    }
    return messages;
}


#pragma mark - Private

- (CJMMessageMO *)_messageForId:(NSString *)messageId {
    if (!self.isInitialized) return nil;
    NSOrderedSet *results = [self.user.messages filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"id == %@", messageId]];
    BOOL existing = results && [results count] > 0;
    return existing ? results[0] : nil;
}

- (void)_deleteMessages:(NSArray<CJMMessageMO*>*)messages {
    [privateContext performBlock:^{
        for (CJMMessageMO *msg in messages) {
            [privateContext deleteObject:msg];
        }
        [self notifyUpdate];
        [self _save];
    }];
}

// always call from inside privateContext performBlock
- (BOOL)_save {
    NSError *error = nil;
    BOOL res = YES;
    res = [privateContext save:&error];
    if (!res) {
        CJMLogStaticDebug(@"Error saving core data private context: %@\n%@", [error localizedDescription], [error userInfo]);
    }
    res = [mainContext save:&error];
    if (!res) {
        CJMLogStaticDebug(@"Error saving core data main context: %@\n%@", [error localizedDescription], [error userInfo]);
    }
    return res;
}


#pragma mark - Delegate

- (void)notifyUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inboxMessagesDidUpdate)]) {
        [self.delegate inboxMessagesDidUpdate];
    }
}

@end
