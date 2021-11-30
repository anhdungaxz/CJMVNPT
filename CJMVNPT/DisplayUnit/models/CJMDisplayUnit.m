#import "CJM+DisplayUnit.h"
#import "CJMConstants.h"

@implementation CJMDisplayUnit

- (instancetype)initWithJSON:(NSDictionary *)json {
    if (self = [super init]) {
        @try {
            _json = json;
            
            NSString *wzrkId = json[@"wzrk_id"];
            if (wzrkId) {
                _unitID = wzrkId;
            } else {
                _unitID= @"0_0";
            }
            
            NSString *type = json[@"type"];
            if (type) {
                _type = type;
            }
            
            NSString *bgColor = json[@"bg"];
            if (bgColor) {
                _bgColor = bgColor;
            }
            
            NSDictionary *customExtras = (NSDictionary *) json[@"custom_kv"];
            if (!customExtras) customExtras = [NSDictionary new];
            _customExtras = customExtras;
            
            NSMutableArray<CJMDisplayUnitContent *> *contentList = [NSMutableArray new];
            NSArray *displayUnitContent = json[@"content"];
            if (displayUnitContent) {
                for (NSDictionary *obj in displayUnitContent) {
                    CJMDisplayUnitContent *content = [[CJMDisplayUnitContent alloc] initWithJSON:obj];
                    [contentList addObject:content];
                }
            }
            _contents = contentList;
            
        } @catch (NSException *e) {
            CJMLogStaticDebug(@"Error intitializing CleverTapDisplayUnit: %@", e.reason);
            return nil;
        }
    }
    return self;
}

@end
