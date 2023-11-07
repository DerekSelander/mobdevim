//
//  springboardservices.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

//#import "springboardservices.h"
#include <time.h>
#include <utime.h>
#include <sys/stat.h>
#import <dlfcn.h>

#import "ios_instruments_client.h"
#import "process.h"

extern bool ssl_enabled;

AMDServiceConnectionRef connect_to_instruments_server(AMDeviceRef d) {
    AMDServiceConnectionRef serviceConnection = nil;
    NSDictionary *inputDict = @{@"CloseOnInvalidate" : @YES};
    mach_error_t err = AMDeviceSecureStartService(d, @"com.apple.instruments.remoteserver", inputDict, &serviceConnection);
    
    if ( err != kAMDSuccess ) {
        mach_error_t err = AMDeviceSecureStartService(d, @"com.apple.instruments.remoteserver.DVTSecureSocketProxy", inputDict, &serviceConnection);
        
        if ( err != kAMDSuccess ) {
            derror("Unable to establish connection: %s\n",  AMDErrorString(err));
            exit(1);
        } else {
            ssl_enabled = true;
        }
        
    }
    
    if ( serviceConnection ) {
        
        load_extern_implementation();
        perform_handshake((am_device_service_connection*)serviceConnection);

    }
    else {
        derror("Couldn't establish connection\n");
        exit(1);
    }
    
    return serviceConnection;
}

int kill_process(AMDeviceRef d, NSDictionary *options) {
    am_device_service_connection *serviceConnection = (am_device_service_connection*)connect_to_instruments_server(d);
    

//    print_proclist(serviceConnection);
    NSString *killpid = options[kProcessKillPID];
    if (killpid == nil) {
        printf("No PID!\n");
        exit(1);
    }
    
    NSString *trimmedString = [killpid stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];

    if([trimmedString length])
    {
        NSArray* pids = get_proclist_matching_name(serviceConnection, killpid);
        for (NSNumber *p in pids) {
            printf("killing \"%s\" %d\n", killpid.UTF8String, p.intValue);
            kill(serviceConnection, p.intValue);
        }
    }
    else
    {
        kill(serviceConnection, killpid.intValue);
    }

    AMDeviceStopSession(d);
    AMDeviceDisconnect(d);
    return 0;
}

int running_processes(AMDeviceRef d, NSDictionary *options) {

//    preload();
    am_device_service_connection *serviceConnection = (am_device_service_connection*)connect_to_instruments_server(d);
    

    print_proclist(serviceConnection);

    AMDeviceStopSession(d);
    AMDeviceDisconnect(d);
//    // launch the instruments server
//    mach_error_t err = MobileDevice.AMDeviceSecureStartService(
//                                                               cbi->dev,
//                                                               CFSTR("com.apple.instruments.remoteserver"),
//                                                               NULL,
//                                                               connptr);
//
//    if ( err != kAMDSuccess )
//    {
//        // try again with an SSL-enabled service, commonly used after iOS 14
//        err = MobileDevice.AMDeviceSecureStartService(
//                                                      cbi->dev,
//                                                      CFSTR("com.apple.instruments.remoteserver.DVTSecureSocketProxy"),
//                                                      NULL,
//                                                      connptr);
//
//        if ( err != kAMDSuccess )
//        {
//            fprintf(stderr, "Failed to start the instruments server (0x%x). "
//                    "Perhaps DeveloperDiskImage.dmg is not installed on the device?\n", err);
//            break;
//        }
//
//        ssl_enabled = true;
//    }
//
//    if ( verbose )
//        printf("successfully launched instruments server\n");
//}
//while ( false );
//
//MobileDevice.AMDeviceStopSession(cbi->dev);
//MobileDevice.AMDeviceDisconnect(cbi->dev);
//
//
//    perform_handshake(GDeviceConnection);
//    print_proclist(GDeviceConnection);
//    XRMobileDevice* device  = [[NSClassFromString(@"XRMobileDevice") alloc] initWithDevice:d];
//    if (!device) {
//        dsprintf(stderr, "couldn't maintain a device connection\n");
//        return 1;
//    }
//    id connection = [device connection];
//    NSString *identifier = @"com.apple.instruments.server.services.deviceinfo";
//    int version = [connection remoteCapabilityVersion:identifier];
//    if (!version) {
//        printf("Couldn't find capability on device!\n");
//        [connection  cancel];
//        return 1;
//    }
//
//
//    id channel = [connection makeChannelWithIdentifier:identifier];
//
////    NSURL *url = [NSURL fileURLWithPath:@"/tmp/yay"];
////    NSData *data = [NSData dataWithContentsOfURL:url];
//      id msg = [NSClassFromString(@"DTXMessage") messageWithSelector:NSSelectorFromString(@"runningProcesses") objectArguments:   nil];
//
//    dispatch_group_t group = dispatch_group_create();
//    dispatch_group_enter(group);
//
//    [channel sendMessageSync:msg replyHandler:^(DTXMessage *response, int extra) {
//        if (response.error) {
//            printf("%s\n", response.error.description.UTF8String);
//        }
//        for (NSDictionary *dict in response.payloadObject) {
//
//            printf(" %s%7s%s %s%s%s\n", dcolor(dc_cyan), [[dict[@"pid"] description] UTF8String], colorEnd(), [dict[@"isApplication"] boolValue] ? dcolor(dc_yellow) : dcolor(dc_bold), [[dict[@"realAppName"] description] UTF8String], colorEnd());
//        }
//        dispatch_group_leave(group);
//    }];
//    dispatch_group_wait(group, 10);
    
 
    return 0;
}
