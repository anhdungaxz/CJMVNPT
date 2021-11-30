#import <Foundation/Foundation.h>

extern NSString * _Nullable const kCJMSessionVariantKey;
extern NSString * _Nullable const kSnapshotSerializerConfigKey;

extern NSString * _Nullable const CJMABTestEditorChangeMessageRequestType;
extern NSString * _Nullable const CJMABTestEditorSessionStartRequestType;
extern NSString * _Nullable const CJMABTestEditorClearMessageRequestType;
extern NSString * _Nullable const CJMABTestEditorDisconnectMessageRequestType;
extern NSString * _Nullable const CJMABTestVarsRequestType;

typedef NS_ENUM(NSUInteger, CJMVarType){
    CJMVarTypeUnknown,
    CJMVarTypeBool,
    CJMVarTypeDouble,
    CJMVarTypeInteger,
    CJMVarTypeString,
    CJMVarTypeArrayOfBool,
    CJMVarTypeArrayOfDouble,
    CJMVarTypeArrayOfInteger,
    CJMVarTypeArrayOfString,
    CJMVarTypeDictionaryOfBool,
    CJMVarTypeDictionaryOfDouble,
    CJMVarTypeDictionaryOfInteger,
    CJMVarTypeDictionaryOfString,
};

@interface CJMABTestUtils : NSObject

+ (CJMVarType)CJMVarTypeFromString:(NSString*_Nonnull)type;

+ (NSString* _Nonnull)StringFromCJMVarType:(CJMVarType)type;

@end

