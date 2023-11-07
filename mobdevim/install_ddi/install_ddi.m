//
//  springboardservices.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//




#import "install_ddi.h"
#import "progressbar.h"

static progressbar *progress = nil;

static void image_callback(CFDictionaryRef d, id something) {

//    dprint("progress: %s\n", [progress[@"Status"] UTF8String]);
    if (progress) {
        NSDictionary *dict = (__bridge NSDictionary *)(d);
        NSNumber *complete = dict[@"PercentComplete"];
        if (complete) {
            unsigned long value = [complete unsignedIntegerValue];
            progressbar_update(progress, value);
        }
    }
//    NSLog(@"%@ %@", something, progress );
//    printf("");
}

int uninstall_ddi(AMDeviceRef d, NSDictionary *options) {
    
    dprint("attempting to unmount the /Developer image... ");
    amd_err er = AMDeviceUnmountImage(d, @"/Developer");
    if ( er != ERR_SUCCESS)
    {
        derror("Error (%s) %d\n", AMDErrorString(er), er);
        return 1;
    } else {
        dprint("Image successfully unmounted!\n");
    }
    return 0;
}


int install_ddi(AMDeviceRef d, NSDictionary *options) {

    if (!global_options.ddiInstallPath || !global_options.ddiSignatureInstallPath)
    {
        derror("<DDI> <DDI Signature> needed\n");
        exit(1);
    }
    

    NSData *dataSIG = [NSData dataWithContentsOfFile:global_options.ddiSignatureInstallPath];
//    NSData *dataSIG = [NSData dataWithContentsOfFile:@"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/15.0/DeveloperDiskImage.dmg.signature"];
    if (!dataSIG) {
        printf("Need a valid signature\n");
        exit(1);
    }
    NSDictionary *op = @{@"ImageSignature" :  dataSIG, @"ImageType": @"Developer", @"DiskImage" : @"/Developer"};

    progress = progressbar_new("Installing... ", 100);
    progressbar_update(progress, 0);
    
     amd_err er = AMDeviceMountImage(d,  global_options.ddiInstallPath, op, image_callback, nil);
    
    
    if ( er != ERR_SUCCESS)
    {
        progressbar_update_label(progress, "Error:");
        progressbar_update(progress, 0);
        progressbar_finish(progress);
        derror("Error (%s) %d\n", AMDErrorString(er), er);
        return 1;
    } else {
        progressbar_update(progress, 100);
        progressbar_update_label(progress, "DDI mounted to /Developer!");
        progressbar_finish(progress);
    }
    AMDeviceStopSession(d);
    AMDeviceDisconnect(d);
    

     
    
    return 0;
}
