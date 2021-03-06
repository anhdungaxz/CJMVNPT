#import "CJMFeatureFlagsController.h"
#import "CJMConstants.h"
#import "CJMPreferences.h"
#import "CJMInstanceConfig.h"

@interface CJMFeatureFlagsController() {
    NSOperationQueue *_commandQueue;
}

@property (atomic, copy) NSString *guid;
@property (atomic, strong) CJMInstanceConfig *config;
@property (atomic) NSMutableDictionary<NSString *, NSNumber *> *store;

@property (nonatomic, weak) id<CJMFeatureFlagsDelegate> _Nullable delegate;

@end

typedef void (^CJMFeatureFlagsOperationBlock)(void);

@implementation CJMFeatureFlagsController

- (instancetype _Nullable)initWithConfig:(CJMInstanceConfig *_Nonnull)config
                                    guid:(NSString *_Nonnull)guid
                                delegate:(id<CJMFeatureFlagsDelegate>_Nonnull)delegate {
    self = [super init];
    if (self) {
        _isInitialized = YES;
        _config = config;
        _guid = guid;
        _delegate = delegate;
        _commandQueue = [[NSOperationQueue alloc] init];
        _commandQueue.maxConcurrentOperationCount = 1;
        [self _unarchiveDataSync:YES];
    }
    return self;
}

- (void)updateFeatureFlags:(NSArray<NSDictionary *> *)featureFlags {
    [self _updateFeatureFlags:featureFlags isNew:YES];
}

// be sure to call off the main thread
- (void)_updateFeatureFlags:(NSArray<NSDictionary*> *)featureFlags isNew:(BOOL)isNew {
    CJMLogInternal(_config.logLevel, @"%@: updating feature flags: %@", self, featureFlags);
    NSMutableDictionary *store = [NSMutableDictionary new];
    for (NSDictionary *flag in featureFlags) {
        @try {
            store[flag[@"n"]] = [NSNumber numberWithBool: [flag[@"v"] boolValue]];
        } @catch (NSException *e) {
            CJMLogDebug(_config.logLevel, @"%@: error parsing feature flag: %@, %@", self, flag, e.debugDescription);
            continue;
        }
    }
    self.store = store;
    
    if (isNew) {
        [self _archiveData:featureFlags sync:NO];
    }
    [self notifyUpdate];
}

- (void)notifyUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(featureFlagsDidUpdate)]) {
        [self.delegate featureFlagsDidUpdate];
    }
}

- (BOOL)get:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue {
    CJMLogInternal(_config.logLevel, @"%@: get feature flag: %@ with default: %i", self, key, defaultValue);
    @try {
        NSNumber *value = self.store[key];
        if (value != nil) {
            return [value boolValue];
        } else {
            CJMLogDebug(_config.logLevel, @"%@: feature flag %@ not found, returning default value", self, key);
            return defaultValue;
        }
    } @catch (NSException *e) {
        CJMLogDebug(_config.logLevel, @"%@: error parsing feature flag: %@ not found, returning default value", self, key);
        return defaultValue;
    }
}

- (NSString*)dataArchiveFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-feature-flags.plist", _config.accountId, _guid];
}

- (void)_unarchiveDataSync:(BOOL)sync {
    NSString *filePath = [self dataArchiveFileName];
    __weak CJMFeatureFlagsController *weakSelf = self;
    CJMFeatureFlagsOperationBlock opBlock = ^{
        NSArray *featureFlags = [CJMPreferences unarchiveFromFile:filePath removeFile:NO];
        if (featureFlags) {
            [weakSelf _updateFeatureFlags:featureFlags isNew:NO];
        }
    };
    if (sync) {
        opBlock();
    } else {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:opBlock];
        _commandQueue.suspended = NO;
        [_commandQueue addOperation:operation];
    }
}

- (void)_archiveData:(NSArray*)data sync:(BOOL)sync {
    NSString *filePath = [self dataArchiveFileName];
    CJMFeatureFlagsOperationBlock opBlock = ^{
        [CJMPreferences archiveObject:data forFileName:filePath];
    };
    if (sync) {
        opBlock();
    } else {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:opBlock];
        _commandQueue.suspended = NO;
        [_commandQueue addOperation:operation];
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"CleverTap.%@.CTFeatureFlagsController", _config.accountId];
}

@end
