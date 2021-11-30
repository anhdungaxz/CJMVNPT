#import <Foundation/Foundation.h>

@interface CJMInstanceConfig () <NSCopying> {}

@property (nonatomic, assign, readonly) BOOL isDefaultInstance;
@property (nonatomic, strong, readonly, nonnull) NSString *queueLabel;
@property (nonatomic, assign) BOOL isCreatedPostAppLaunched;
@property (nonatomic, assign) BOOL enableABTesting;
@property (nonatomic, assign) BOOL enableUIEditor;
@property (nonatomic, assign) BOOL beta;

- (instancetype _Nonnull)initWithAccountId:(NSString * _Nonnull)accountId
                              accountToken:(NSString * _Nonnull)accountToken
                           accountPasscode:(NSString * _Nonnull)accountPasscode
                             accountRegion:(NSString * _Nullable)accountRegion
                         isDefaultInstance:(BOOL)isDefault;

@end
