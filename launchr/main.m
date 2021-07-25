//
//  main.m
//  launchr
//
//  Created by jim on 03/07/2021.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "PrivateApiSupport.h"

void load_private_framework(NSString const* framework) {
    NSBundle *b = [NSBundle bundleWithPath: [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/%@.framework",framework]];
    
    if (![b load]) {
        NSLog(@"Error loading %@.framework!", framework);
        exit(1);
    }
}

void print_usage(void) {
    fprintf(stderr, "Usage: launchr [-platform macos|ios] [-mode suspended|running] [-envfile <path_to_env_plist>] -exec <path_to_executable>\n");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        load_private_framework(@"RunningBoardServices");

        NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
        NSString const* runMode = [standardDefaults stringForKey:@"mode"];
        NSString const* platform = [standardDefaults stringForKey:@"platform"];
        NSString* executablePath = [standardDefaults stringForKey:@"exec"];

        int platformIdentifier = PLATFORM_IOS; // 2 for ios, 1 for macos
        int lsSpawnFlags = 0; // 0 for normal launch, 1 to launch suspended
        
        if (!([executablePath length] > 0)) {
            print_usage();
            exit(1);
        }
        
        if ([platform isEqualToString:@"macos"]) {
            platformIdentifier = PLATFORM_MACOS;
        }

        if ([runMode isEqualToString:@"suspended"]) {
            lsSpawnFlags = 1;
        }
                
        Class cRbsLaunchContext = NSClassFromString(@"RBSLaunchContext");
        Class cRbsLaunchRequest = NSClassFromString(@"RBSLaunchRequest");
        Class cRbsProcessIdentity = NSClassFromString(@"RBSProcessIdentity");

        // TODO: find out how to get rid of the runningboard watchdog, our child is being killed in ~30s when launched suspended now. This is Jetsam, find out how to configure
        // TODO: create proper container for data
        
        NSMutableDictionary *infoPlistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/Info.plist", [executablePath stringByDeletingLastPathComponent]]];

        NSString* jobLabel;
        NSString const* bundleId = [infoPlistDic objectForKey:@"CFBundleIdentifier"];

        NSUUID *uuid = [NSUUID UUID];
        NSString *envFile = [standardDefaults stringForKey:@"envfile"];
        NSDictionary *env = nil;
        
        if ([envFile length] > 0) {
            
            env = [[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@", envFile]];

            if ([env count] < 1) {
                print_usage();
                exit(1);
            }
            
            NSLog(@"Using additional environment variables:\n%@", env);
        }
        
        jobLabel = [NSString stringWithFormat:@"%@-%@",bundleId,uuid]; // Add the UUID to have unique job names if spawning multiple instances of the same app

        NSLog(@"Submitting job: %@", jobLabel);
        
        RBSProcessIdentity* identity = [cRbsProcessIdentity identityForApplicationJobLabel:jobLabel bundleID:bundleId platform:platformIdentifier];
        RBSLaunchContext* context = [cRbsLaunchContext contextWithIdentity:identity];
        
        NSString *outPath = NSTemporaryDirectory();
        NSString *stdoutPath = [outPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_stdout.txt",jobLabel]];
        NSString *stderrPath = [outPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_stderr.txt",jobLabel]];
        
        [context setExecutablePath:executablePath];
        [context setLsSpawnFlags:lsSpawnFlags];
        [context setStandardOutputPath:stdoutPath];
        [context setStandardErrorPath:stderrPath];
        // TODO: below is not effective, WIP
        [context setLsInitialRole:7]; // Activate (foreground) app upon launch
        [context setEnvironment:env];

        RBSLaunchRequest* request = [[cRbsLaunchRequest alloc] initWithContext:context];
        
        NSError* errResult;
        BOOL success = [request execute:&context error:&errResult];

        if (!success) {
            NSLog(@"Error: %@", errResult);
            exit(1);
        }
        
        NSLog(@"Redirecting child's output to %@", outPath);

    }
    return 0;
}
