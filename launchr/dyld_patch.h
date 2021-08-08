//
//  dyld_patch.h
//  launchr
//
//  Created by jim on 08/08/2021.
//

#ifndef dyld_patch_h
#define dyld_patch_h

#include <stdio.h>

int patch_dyld_in_process(pid_t pid);

#endif /* dyld_patch_h */
