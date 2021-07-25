//
//  PrivateApiSupport.h
//  launchr
//
//  Created by jim on 04/07/2021.
//

#ifndef PrivateApiSupport_h
#define PrivateApiSupport_h

#define PLATFORM_IOS 2
#define PLATFORM_MACOS 1

@class RBSProcessIdentity;

@interface RBSProcessIdentity : NSObject
+ (id)identityOfCurrentProcess;
+ (id)identityForApplicationJobLabel:(id)arg1 bundleID:(id)arg2 platform:(int)arg3;
@end

@interface RBSLaunchContext : NSObject
@property (nonatomic,copy) NSDictionary * environment;
@property (nonatomic,copy) NSString * standardOutputPath;
@property (nonatomic,copy) NSString * standardErrorPath;
@property (nonatomic,copy) NSString * executablePath;
@property (nonatomic) unsigned long lsSpawnFlags;
@property (nonatomic) unsigned int lsInitialRole;

+ (id)contextWithIdentity:(id)arg1;
+ (id)context;
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
