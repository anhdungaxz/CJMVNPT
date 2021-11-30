#import "CJMABTestEditorSnapshotMessageRequest.h"
#import "CJMABTestEditorSnapshotMessageResponse.h"
#import "CJMApplicationStateSerializer.h"
#import "CJMObjectSerializerConfig.h"
#import "CJMObjectIdentityProvider.h"
#import "CJMInAppResources.h"

NSString * const CJMABTestEditorSnapshotMessageRequestType = @"snapshot_request";

static NSString * const kObjectIdentityProviderKey = @"object_identity_provider";
static NSString * const kSnapshot_hierarchyKey = @"snapshot_hierarchy";

@implementation CJMABTestEditorSnapshotMessageRequest

+ (instancetype)message {
    return [[[self class] alloc] initWithType:CJMABTestEditorSnapshotMessageRequestType];
}

- (CJMABTestEditorMessage *)response {
    CJMObjectSerializerConfig *serializerConfig = [self.session sessionObjectForKey:kSnapshotSerializerConfigKey];
    if (serializerConfig == nil) {
        CJMLogStaticDebug(@"Failed to serialized because serializer config is not present.");
        return nil;
    }
    
    // Get the object identity provider from the connection's session store or create one if there is none already.
    CJMObjectIdentityProvider *objectIdentityProvider = [self.session sessionObjectForKey:kObjectIdentityProviderKey];
    if (objectIdentityProvider == nil) {
        objectIdentityProvider = [[CJMObjectIdentityProvider alloc] init];
        [self.session setSessionObject:objectIdentityProvider forKey:kObjectIdentityProviderKey];
    }
    
    CJMApplicationStateSerializer *serializer = [[CJMApplicationStateSerializer alloc]
                                                initWithApplication:[CJMInAppResources getSharedApplication]
                                                configuration:serializerConfig objectIdentityProvider:objectIdentityProvider];
    
    CJMABTestEditorSnapshotMessageResponse *snapshotMessage = [CJMABTestEditorSnapshotMessageResponse messageWithOptions:nil];
    __block UIImage *screenshot = nil;
    __block NSDictionary *serializedObjects = nil;
    __block NSString *orientation = nil;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        screenshot = [serializer snapshotForWindowAtIndex:0];
        orientation = [self orientation];
    });
    snapshotMessage.orientation = orientation;
    snapshotMessage.screenshot = screenshot;
    NSString *imageHash = [self dataObjectForKey:@"image_hash"];
    
    if ([imageHash isEqualToString:snapshotMessage.imageHash]) {
        serializedObjects = [self.session sessionObjectForKey:@"snapshot_hierarchy"];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            serializedObjects = [serializer objectHierarchyForWindowAtIndex:0];
        });
        [self.session setSessionObject:serializedObjects forKey:@"snapshot_hierarchy"];
    }
    
    snapshotMessage.serializedObjects = serializedObjects;
    return snapshotMessage;
}

- (NSString *)orientation {
    UIInterfaceOrientation orientation = [[CJMInAppResources getSharedApplication] statusBarOrientation];
    BOOL landscape = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
    if (landscape) {
        return @"landscape";
    } else {
        return @"portrait";
    }
}

@end
