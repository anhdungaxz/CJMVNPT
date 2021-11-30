#import "CJMABTestEditorMessage.h"

@interface CJMABTestEditorMessage ()

@property (nonatomic, strong)NSMutableDictionary *data;
@property (nonatomic, readwrite, strong) CJMEditorSession *session;

@end

@implementation CJMABTestEditorMessage

+ (instancetype)message {
    // overide in sub-class
    return [[[self class] alloc] initWithType:@"unknown"];
}

+ (instancetype)messageWithOptions:(NSDictionary *)options {
    CJMABTestEditorMessage *message = [[self class] message];
    message.data = options[@"data"] ? [options[@"data"] mutableCopy] : [NSMutableDictionary new];
    message.session = options[@"session"];
    return message;
}

- (instancetype)initWithType:(NSString *)type {
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}

- (void)setDataObject:(id)object forKey:(NSString *)key {
    _data[key] = object ?: [NSNull null];
}

- (id)dataObjectForKey:(NSString *)key {
    id object = _data[key];
    return [object isEqual:[NSNull null]] ? nil : object;
}

- (NSDictionary *)data {
    return [_data copy];
}

- (NSData *)JSONData {
    NSDictionary *jsonObject = @{ @"type": _type, @"data": [_data copy] };
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:(NSJSONWritingOptions)0 error:&error];
    if (error) {
        CJMLogStaticInternal(@"%@: Failed to serialise websocket editor message", error)
    }
    return jsonData;
}

- (CJMABTestEditorMessage *)response {
    // no-op
    return nil;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@:%p type='%@'>", NSStringFromClass([self class]), (__bridge void *)self, self.type];
}

@end
