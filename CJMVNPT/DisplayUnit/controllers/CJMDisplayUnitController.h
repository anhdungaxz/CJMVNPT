#import <Foundation/Foundation.h>
#import "CJM+DisplayUnit.h"

@protocol CJMDisplayUnitDelegate <NSObject>
@required
- (void)displayUnitsDidUpdate;
@end

@interface CJMDisplayUnitController : NSObject

@property (nonatomic, assign, readonly) BOOL isInitialized;
@property (nonatomic, copy, readonly) NSArray <CJMDisplayUnit *> * _Nullable displayUnits;

@property (nonatomic, weak) id<CJMDisplayUnitDelegate> _Nullable delegate;

- (instancetype _Nullable ) init __unavailable;

// blocking, call off main thread
- (instancetype _Nullable)initWithAccountId:(NSString *_Nonnull)accountId
                                       guid:(NSString *_Nonnull)guid;

- (void)updateDisplayUnits:(NSArray<NSDictionary*> *_Nullable)displayUnits;

@end

