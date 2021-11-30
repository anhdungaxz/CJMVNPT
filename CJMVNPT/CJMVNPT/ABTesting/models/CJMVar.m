#import "CJMVar.h"
#import "CJMConstants.h"

@interface CJMVar () {}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSNumber *numberValue;
@property (nonatomic, strong) NSArray<id> *arrayValue;
@property (nonatomic, strong) NSDictionary<NSString*, id> *dictionaryValue;
@property (nonatomic, strong) id value;
@property (nonatomic, assign) CJMVarType type;

@end

@implementation CJMVar

@synthesize stringValue=_stringValue;
@synthesize numberValue=_numberValue;
@synthesize arrayValue=_arrayValue;
@synthesize dictionaryValue=_dictionaryValue;

- (instancetype _Nonnull)initWithName:(NSString * _Nonnull)name type:(CJMVarType)type andValue:(id _Nullable)value {
    self = [super init];
    if (self) {
        _name = name;
        _type = type;
        _value = value;
        [self _computeValue];
    }
    return self;
}

- (void)clearValue {
    _value = nil;
    [self _computeValue];
}

- (void)updateWithValue:(id)value andType:(CJMVarType)type {
    if (value == nil) {
        return;
    }
    _value = value;
    _type = type;
    [self _computeValue];
}

- (void)_computeValue {
    _stringValue = nil;
    _numberValue = nil;
    _arrayValue = nil;
    _dictionaryValue = nil;
    
    if (_value == nil) {
        return;
    }
    
    @try {
        if ([_value isKindOfClass:NSString.class]) {
            _stringValue = (NSString *) _value;
        } else {
            _stringValue = [NSString stringWithFormat:@"%@", _value];
        }
        
        switch (self.type) {
            case CJMVarTypeBool:
                _numberValue = [NSNumber numberWithBool:[_stringValue boolValue]];
                break;
            case CJMVarTypeDouble:
                _numberValue = [NSNumber numberWithDouble:[_stringValue doubleValue]];
                break;
            case CJMVarTypeInteger:
                _numberValue = [NSNumber numberWithInteger:[_stringValue integerValue]];
                break;
            case CJMVarTypeString:
                // no-op already have stringValue set
                break;
            case CJMVarTypeArrayOfBool:
                _arrayValue = [self toArrayValue:_stringValue];
                break;
            case CJMVarTypeArrayOfDouble:
                _arrayValue = [self toArrayValue:_stringValue];
                break;
            case CJMVarTypeArrayOfInteger:
                _arrayValue = [self toArrayValue:_stringValue];
                break;
            case CJMVarTypeArrayOfString:
                _arrayValue = [self toArrayValue:_stringValue];
                break;
            case CJMVarTypeDictionaryOfBool:
                _dictionaryValue = [self toDictionaryValue:_stringValue];
                break;
            case CJMVarTypeDictionaryOfDouble:
                _dictionaryValue = [self toDictionaryValue:_stringValue];
                break;
            case CJMVarTypeDictionaryOfInteger:
                _dictionaryValue = [self toDictionaryValue:_stringValue];
                break;
            case CJMVarTypeDictionaryOfString:
                _dictionaryValue = [self toDictionaryValue:_stringValue];
                break;
            default:
                break;
        }
    } @catch (NSException *e) {
        CJMLogStaticInternal(@"Error computing value for CJMVar: %@ withType: %@, error: %@", self.name, [CJMABTestUtils StringFromCJMVarType:self.type], e.debugDescription);
    }
}

- (NSArray *)toArrayValue:(NSString *)stringValue {
    NSArray *tempArray;
    NSError *err;
    NSData *data = [stringValue dataUsingEncoding:NSUTF8StringEncoding];
    if(data != nil){
        id response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
        if (response && [response isKindOfClass:[NSArray class]]) {
            tempArray = [response copy];
            for (id value in tempArray) {
                if (self.type == CJMVarTypeArrayOfString) {
                    if (![value isKindOfClass:[NSString class]]){
                        CJMLogStaticInternal(@"%@: Failed to parse the array value, invalid value provided: %@", self, stringValue);
                        return nil;
                    }
                } else {
                    if (![value isKindOfClass:[NSNumber class]]){
                        CJMLogStaticInternal(@"%@: Failed to parse the array value, invalid value provided: %@", self, stringValue);
                        return nil;
                    }
                }
            }
        } else {
            CJMLogStaticInternal(@"%@: Failed to parse the array value: %@", self, stringValue);
        }
    }
    return tempArray;
}

- (NSDictionary *)toDictionaryValue:(NSString *)stringValue {
    NSDictionary *tempDict;
    NSError *err;
    NSData *data = [stringValue dataUsingEncoding:NSUTF8StringEncoding];
    if(data != nil){
        id response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
        if (response && [response isKindOfClass:[NSDictionary class]]) {
            tempDict = [response copy];
            for (id value in tempDict.allValues) {
                if (self.type == CJMVarTypeDictionaryOfString) {
                    if (![value isKindOfClass:[NSString class]]){
                        CJMLogStaticInternal(@"%@: Failed to parse the dictionary value, invalid value provided: %@", self, stringValue);
                        return nil;
                    }
                } else {
                    if (![value isKindOfClass:[NSNumber class]]){
                        CJMLogStaticInternal(@"%@: Failed to parse the dictionary value, invalid value provided: %@", self, stringValue);
                        return nil;
                    }
                }
            }
        } else {
            CJMLogStaticInternal(@"%@: Failed to parse the dictionary value: %@", self, stringValue);
        }
    }
    return tempDict;
}

- (NSNumber *)numberValue {
    return _numberValue;
}

- (NSString *)stringValue {
    return _stringValue;
}

- (NSArray<id>* _Nullable)arrayValue {
    return _arrayValue;
}

- (NSDictionary<NSString *, id>* _Nullable)dictionaryValue {
    return _dictionaryValue;
}

- (NSDictionary *)toJSON {
    NSMutableDictionary *json = [NSMutableDictionary new];
    json[@"name"] = self.name;
    json[@"type"] = [CJMABTestUtils StringFromCJMVarType:self.type];
    return json;
}

@end
