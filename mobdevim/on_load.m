//
//  OnLoad.c
//  mobdevim
//
//  
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mach-o/getsect.h>
#import "Helpers.h"
#import <dlfcn.h>
#import <mach-o/loader.h>

__attribute__((constructor)) void onLoad(void) {
    if (getenv("DSPLIST")) {
        global_options.quiet = YES;
    }
    
    /*
     MobileDevice has a function called mobdevlog that logs what's happening
     It's gated by a global var called "gLogLevel"
     
     This gLogLevel doesn't have external linkage (i.e. can't use dlsym), but
     does have the symbol name present. It is an aligned int, so jump by 4 to find it
     */
    if (getenv("DSDEBUG")) {
        dsdebug("Verbose mode enabled...\n");
        unsigned long size = 0;
        uint32_t* data = (uint32_t*)getsectdatafromFramework("MobileDevice", "__DATA", "__data", &size);
        for (int i = 0; i < size / sizeof(uint32_t); i++) {
            Dl_info info;
            dladdr(&data[i], &info);
            if (strcmp(info.dli_sname, "gLogLevel") == 0) {
                // Let's crank it ALLLLLL THE WAY UP
                *(uint32_t*)info.dli_saddr = INT32_MAX - 1;
                break;
            }
        }
    }
}
