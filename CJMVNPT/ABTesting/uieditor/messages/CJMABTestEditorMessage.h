#import <Foundation/Foundation.h>
#import "CJMEditorSession.h"
#import "CJMABTestUtils.h"
#import "CJMConstants.h"

@interface CJMABTestEditorMessage : NSObject

@property (nonatomic, readonly, copy) NSString *type;
@property (nonatomic, readonly, strong) CJMEditorSession *session;

+ (instancetype)messageWithOptions:(NSDictionary *)options;

- (instancetype)initWithType:(NSString *)type;

- (void)setDataObject:(id)object forKey:(NSString *)key;
- (id)dataObjectForKey:(NSString *)key;
- (NSDictionary *)data;

- (NSData *)JSONData;
- (CJMABTestEditorMessage *)response;

@end


