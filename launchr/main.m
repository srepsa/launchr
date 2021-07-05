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
    fprintf(stderr, "Usage: launchr <platform> <launch_suspended> <path_to_executable>\n");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        if (argc < 4) {
            print_usage();
            exit(1);
        }
        
        const int platform = atoi(argv[1]);  // 1 for macos, 2 for iOS
        const int lsSpawnFlags = atoi(argv[2]); // 0 for normal launch, 1 to launch suspended

        NSString const* executablePath = [NSString stringWithUTF8String:argv[3]];
        
        load_private_framework(@"RunningBoardServices");
        
        Class cRbsLaunchContext = NSClassFromString(@"RBSLaunchContext");
        Class cRbsLaunchRequest = NSClassFromString(@"RBSLaunchRequest");
        Class cRbsProcessIdentity = NSClassFromString(@"RBSProcessIdentity");

        // TODO: find out how to get rid of the runningboard watchdog, our child is being killed in ~30s when launched suspended now
        // TODO: create proper container for data
        
        NSMutableDictionary *infoPlistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/Info.plist", [executablePath stringByDeletingLastPathComponent]]];

        NSString* jobLabel;
        NSString const* bundleId = [infoPlistDic objectForKey:@"CFBundleIdentifier"];


        NSUUID *uuid = [NSUUID UUID];
        jobLabel = [NSString stringWithFormat:@"%@-%@",bundleId,uuid];
        
        NSLog(@"Submitting job: %@", jobLabel);
        RBSProcessIdentity* identity = [cRbsProcessIdentity identityForApplicationJobLabel:jobLabel bundleID:bundleId platform:platform];

        RBSLaunchContext* context = [cRbsLaunchContext contextWithIdentity:identity];
        [context setExecutablePath:executablePath];
        [context setLsSpawnFlags:lsSpawnFlags];

        RBSLaunchRequest* request = [[cRbsLaunchRequest alloc] initWithContext:context];
        
        NSError* errResult;
        BOOL success = [request execute:&context error:&errResult];

        NSLog(@"errResult: %@, Success: %x", errResult, success);

    }
    return 0;
}
