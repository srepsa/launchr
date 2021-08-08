//
//  main.m
//  launchr
//
//  Created by jim on 03/07/2021.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "PrivateApiSupport.h"

#include <sys/resource.h>
#include "dyld_patch.h"

void load_private_framework(NSString const* framework) {
    NSBundle *b = [NSBundle bundleWithPath: [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/%@.framework",framework]];
    
    if (![b load]) {
        NSLog(@"Error loading %@.framework!", framework);
        exit(1);
    }
}

void print_usage(void) {
    fprintf(stderr, "Usage: launchr [-platform macos|ios] [-allowinterpose yes] [-mode suspended|running] [-envfile <path_to_env_plist>] -exec <path_to_executable>\n");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        load_private_framework(@"RunningBoardServices");

        NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
        NSString const* runMode = [standardDefaults stringForKey:@"mode"];
        NSString const* platform = [standardDefaults stringForKey:@"platform"];
        NSString const* allowinterpose = [standardDefaults stringForKey:@"allowinterpose"];
        NSString* executablePath = [standardDefaults stringForKey:@"exec"];

        int platformIdentifier = PLATFORM_IOS; // 2 for ios, 1 for macos
        int lsSpawnFlags = 1; // 0 for normal launch, 1 to launch suspended
        
        if (!([executablePath length] > 0)) {
            print_usage();
            exit(1);
        }
        
        if ([platform isEqualToString:@"macos"]) {
            platformIdentifier = PLATFORM_MACOS;
        }
                
        Class cRbsLaunchContext = NSClassFromString(@"RBSLaunchContext");
        Class cRbsLaunchRequest = NSClassFromString(@"RBSLaunchRequest");
        Class cRbsProcessIdentity = NSClassFromString(@"RBSProcessIdentity");
        Class cRbsProcessHandle = NSClassFromString(@"RBSProcessHandle");
        Class cRbsProcessPredicate = NSClassFromString(@"RBSProcessPredicate");

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
                fprintf(stderr, "Environment file specified, but no variables found! Ensure the file has a correct format (plist) and contains at least one variable/value combo!\n");
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
        
        // Look at -[RBLaunchdJobManager _generateDataWithIdentity:context:] to learn about the meaning of the context properties
        [context setExecutablePath:executablePath];
        [context setLsSpawnFlags:lsSpawnFlags];
        [context setStandardOutputPath:stdoutPath];
        [context setStandardErrorPath:stderrPath];
        [context setEnvironment:env];
        [context setExecutionOptions:0x8]; // Looking inside runningboard code it looks like this disabled pointer auth? Might come in handy
        [context setLsInitialRole:0x7]; // This value is mapped to PRIO_DARWIN_ROLE_UI_FOCAL by RBSDarwinRoleFromRBSRole()
        
        RBSLaunchRequest* request = [[cRbsLaunchRequest alloc] initWithContext:context];
        
        NSError* errResult;
        BOOL success = [request execute:&context error:&errResult];

        if (!success) {
            NSLog(@"Error: %@", errResult);
            exit(1);
        }
        
        RBSProcessPredicate* predicate = [cRbsProcessPredicate predicateMatchingIdentity:identity];
        RBSProcessHandle* process = [cRbsProcessHandle handleForPredicate:predicate error:nil];

        int pid = [process rbs_pid];
    
        if ([allowinterpose isEqualToString:@"yes"]) {
            NSLog(@"Patching dyld to allow for interposing...");
            if (patch_dyld_in_process(pid)) {
                NSLog(@"Error while patching, am I signed with debugger entitlements?");
                return -1;
            }
        }
        
        if (![runMode isEqualToString:@"suspended"]) {
            kill(pid, SIGCONT);
        }
        
        NSLog(@"Redirecting child's output to: %@", outPath);
        NSLog(@"Child PID: %d", pid);
    }
    return 0;
}
