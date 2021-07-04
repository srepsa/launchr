//
//  PrivateApiSupport.h
//  launchr
//
//  Created by jim on 04/07/2021.
//

#ifndef PrivateApiSupport_h
#define PrivateApiSupport_h

@class RBSProcessIdentity;

@interface RBSProcessIdentity : NSObject
+ (id)identityOfCurrentProcess;
+ (id)identityForApplicationJobLabel:(id)arg1 bundleID:(id)arg2 platform:(int)arg3;
@end

@interface RBSLaunchContext : NSObject
+ (id)contextWithIdentity:(id)arg1;
+ (id)context;
- (void)setExecutablePath:(id)arg1;
- (void)setLsSpawnFlags:(int)arg1;
- (void)setLsInitialRole:(int)arg1;
@end

@interface RBSLaunchRequest : NSObject
- (_Bool)execute:(out id *)arg1 error:(out id *)arg2;
- (id)initWithContext:(id)arg1;
@end

@interface MIInstallerClient : NSObject
- (id)init;
- (void)fetchInfoForAppWithBundleID:(id)arg1 wrapperURL:(id)arg2 completion:(id)arg3;
@end

#endif /* PrivateApiSupport_h */
