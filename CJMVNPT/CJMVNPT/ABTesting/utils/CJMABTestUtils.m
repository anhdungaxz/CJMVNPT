#import "CJMABTestUtils.h"

NSString * const kCJMSessionVariantKey = @"session_variant";
NSString * const kSnapshotSerializerConfigKey = @"snapshot_class_descriptions";

NSString * const CJMABTestEditorSessionStartRequestType = @"matched";
NSString * const CJMABTestEditorChangeMessageRequestType = @"change_request";
NSString * const CJMABTestEditorClearMessageRequestType = @"clear_request";
NSString * const CJMABTestEditorDisconnectMessageRequestType = @"disconnect";
NSString * const CJMABTestVarsRequestType = @"test_vars";


static NSDictionary *_varTypeMap;

NSString* const kUnknown = @"unknown";
NSString* const kBool = @"bool";
NSString* const kDouble = @"double";
NSString* const kInteger = @"integer";
NSString* const kString = @"string";
NSString* const kArrayOfBool = @"arrayofbool";
NSString* const kArrayOfDouble = @"arrayofdouble";
NSString* const kArrayOfInteger = @"arrayofinteger";
NSString* const kArrayOfString = @"arrayofstring";
NSString* const kDictionaryOfBool = @"dictionaryofbool";
NSString* const kDictionaryOfDouble = @"dictionaryofdouble";
NSString* const kDictionaryOfInteger = @"dictionaryofinteger";
NSString* const kDictionaryOfString = @"dictionaryofstring";

@implementation CJMABTestUtils

+ (void)load {
    _varTypeMap = @{
        kBool: @(CJMVarTypeBool),
        kDouble: @(CJMVarTypeDouble),
        kInteger: @(CJMVarTypeInteger),
        kString: @(CJMVarTypeString),
        kArrayOfBool: @(CJMVarTypeArrayOfBool),
        kArrayOfDouble: @(CJMVarTypeArrayOfDouble),
        kArrayOfInteger: @(CJMVarTypeArrayOfInteger),
        kArrayOfString: @(CJMVarTypeArrayOfString),
        kDictionaryOfBool: @(CJMVarTypeDictionaryOfBool),
        kDictionaryOfDouble: @(CJMVarTypeDictionaryOfDouble),
        kDictionaryOfInteger: @(CJMVarTypeDictionaryOfInteger),
        kDictionaryOfString: @(CJMVarTypeDictionaryOfString)
    };
}

+ (CJMVarType)CJMVarTypeFromString:(NSString*_Nonnull)type {
    NSNumber *_type = type != nil ? _varTypeMap[type] : @(CJMVarTypeUnknown);
    if (_type == nil) {
        _type = @(CJMVarTypeUnknown);
    }
    return [_type integerValue];
}

+ (NSString* _Nonnull)StringFromCJMVarType:(CJMVarType)type {
    NSString *val = kUnknown;
    switch (type) {
        case CJMVarTypeBool:
            val = kBool;
            break;
        case CJMVarTypeDouble:
            val = kDouble;
            break;
        case CJMVarTypeInteger:
            val = kInteger;
            break;
        case CJMVarTypeString:
            val = kString;
            break;
        case CJMVarTypeArrayOfBool:
            val = kArrayOfBool;
            break;
        case CJMVarTypeArrayOfDouble:
            val = kArrayOfDouble;
            break;
        case CJMVarTypeArrayOfInteger:
            val = kArrayOfInteger;
            break;
        case CJMVarTypeArrayOfString:
            val = kArrayOfString;
            break;
        case CJMVarTypeDictionaryOfBool:
            val = kDictionaryOfBool;
            break;
        case CJMVarTypeDictionaryOfDouble:
            val = kDictionaryOfDouble;
            break;
        case CJMVarTypeDictionaryOfInteger:
            val = kDictionaryOfInteger;
            break;
        case CJMVarTypeDictionaryOfString:
            val = kDictionaryOfString;
            break;
        default:
            break;
    }
    return val;
}

@end
