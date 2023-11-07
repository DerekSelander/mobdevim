//
//  install_application.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "install_application.h"
#import "progressbar.h"
#import <dlfcn.h>

NSString * const kInstallApplicationPath = @"com.selander.installapplication.path";
static progressbar *progress = nil;


void installCallback(CFDictionaryRef d) {
    
    if (progress) {
        NSDictionary *dict = (__bridge NSDictionary *)(d);
        NSNumber *complete = dict[@"PercentComplete"];
        if (complete) {
            unsigned long value = [complete unsignedIntegerValue];
            progressbar_update(progress, value);
        }
    }
}

void printInstallErrorAndDie(mach_error_t error, const char *path) {
    switch (error) {
        default:
            dsprintf(stderr, "Error installing \"%s\", err: 0x%x\n", path, error);
            break;
    }
    
    exit(1);
}

int install_application(AMDeviceRef d, NSDictionary *options) {
    // Get path to generated file
    NSString *path = [(NSString *)[options objectForKey:kInstallApplicationPath] stringByStandardizingPath];

    extern int gLogLevel;
    
    if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        ErrorMessageThenDie("Couldn't find a valid path at \"%s\"\n", [path fileSystemRepresentation]);
    }
    dsdebug("Installing app from \"%s\"\n", [path UTF8String]);
    NSURL *local_app_url = [NSURL fileURLWithPath:path isDirectory:TRUE];
    NSDictionary *params = @{@"PackageType" : @"Customer"};
    NSString *deviceName = AMDeviceCopyValue(d, nil, @"DeviceName", 0);
    
    // Get a secure path
    
    if (global_options.quiet) {
        assert(!AMDeviceSecureTransferPath(0, d, local_app_url, params, NULL, 0));
        return AMDeviceSecureInstallApplication(0, d, local_app_url, params, NULL, 0);
    } else {
        progress = progressbar_new("Processing... ", 100);
        assert(!AMDeviceSecureTransferPath(0, d, local_app_url, params, installCallback, 0));
        progressbar_update(progress, 100);
        int error = 0;
        progressbar_update_label(progress, "Installing...");
        progressbar_update(progress, 0);
        error = AMDeviceSecureInstallApplication(0, d, local_app_url, params, installCallback, 0);
        
        progressbar_update(progress, 100);
        if (error) {
            progressbar_update_label(progress, "Error:");
            progressbar_update(progress, 0);
            progressbar_finish(progress);
            printInstallErrorAndDie(error, [path UTF8String]);
        } else {
            progressbar_update_label(progress, "Installed!");
            progressbar_finish(progress);
            dsprintf(stdout, "Success: \"%s\" app successfully installed on \"%s\"\n", [[[path lastPathComponent] stringByDeletingPathExtension] UTF8String], [deviceName UTF8String]);
        }
    }
    
    return 0;
}
