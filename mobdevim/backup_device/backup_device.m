//
//  install_application.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "backup_device.h"
#import "progressbar.h"
#import <dlfcn.h>

//
//NSString * const kInstallApplicationPath = @"com.selander.installapplication.path";
//static progressbar *progress = nil;
//
//
//void installCallback(CFDictionaryRef d) {
//
//    if (progress) {
//        NSDictionary *dict = (__bridge NSDictionary *)(d);
//        NSNumber *complete = dict[@"PercentComplete"];
//        if (complete) {
//            unsigned long value = [complete unsignedIntegerValue];
//            progressbar_update(progress, value);
//        }
//    }
//}
//
//void printInstallErrorAndDie(mach_error_t error, const char *path) {
//    switch (error) {
//        default:
//            dsprintf(stderr, "Error installing \"%s\", err: 0x%x\n", path, error);
//            break;
//    }
//
//    exit(1);
//}
static progressbar *progress = nil;
// iff percent is less than zero, it's gonna be an error
static void backup_callback(NSString * identifier, int percent, void *context) {
    if (percent == -35) {
        dprint("user canceled backup request\n");
        return;
    }
    if (percent < 0) {
        printf(" err: ProcessLinkSetupParent%d\n", percent);
        return;
    }
    
    if (!progress) {
        dprint("Remote side complete!\n");
        progress = progressbar_new("Extracting...", 100);
    }
    
    progressbar_update(progress, percent);
    
}

int backup_device(AMDeviceRef d, NSDictionary *options) {
#if 0
    {
    "Display Name" = "iPhone (8)";
    "Product Type" = "iPhone14,4";
    "Product Version" = "16.5";
    "Target Identifier" = "00008110-...";
    "Target Type" = Tahoe;
    }
#endif
    
    NSString *deviceUUID = AMDeviceGetName(d);
    

    
    NSString *deviceName = AMDeviceCopyValue(d, nil, @"DeviceName", 0);
    NSString *productVersion = AMDeviceCopyValue(d, nil, @"ProductVersion", 0);
    NSString *productType = AMDeviceCopyValue(d, nil, @"ProductType", 0);
   
    
    NSDictionary *info =  @{
        @"Display Name" : deviceName,
        @"Product Type" : productType,
        @"Target Identifier" : deviceUUID,
        @"Product Version" : productVersion,
        @"Notes" : @"created by mobdevim",
    };
    
    ams_err err;
    
    if ((err = AMSInitialize(@"/System/Library/PrivateFrameworks/MobileDevice.framework/Versions/Current/"))) {
        derror("err %d\n", err);
        goto cleanup;
    }
    
    
//    progressbar_update_label(progress, "Extracting...");
//    progressbar_update(progress, 0);
    dprint("Enter the device password (present iOS 16+), your will start preparing the backup remotely. You can verify with the rotating circular arrows in the upper corner of the device. Once complete, you'll start to see the download transfer progress.\nDo not exit this program\n");
    
    if ((err = AMSBackupWithOptions(@"-1", deviceUUID, info, @{@"ForceFullBackup" : @YES, @"WillEncrypt": @NO}, backup_callback, d))) {
        derror("err %d\n", err);
        goto cleanup;
    }
    
    if (err) {
        printf("err %d\n", err);
    } else {
        
        dprint("backup created @ \"%s/Library/Application Support/MobileSync/Backup/%s\"\n", [[[NSFileManager defaultManager] homeDirectoryForCurrentUser] path].UTF8String, deviceUUID.UTF8String);
    }
cleanup:
    
    err = AMSCleanup();
    
    return 0;
}
