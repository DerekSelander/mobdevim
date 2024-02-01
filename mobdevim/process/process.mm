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
        perform_handshake((__bridge am_device_service_connection*)serviceConnection);

    }
    else {
        derror("Couldn't establish connection\n");
        exit(1);
    }
    
    return serviceConnection;
}

int kill_process(AMDeviceRef d, NSDictionary *options) {
    am_device_service_connection *serviceConnection = (__bridge am_device_service_connection*)connect_to_instruments_server(d);
    

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

    
//     NSString *name = global_options.programBundleID;
//     NSDictionary *dict = nil;
//     mach_error_t err = AMDeviceLookupApplications(d, @{ @"ReturnAttributes": @YES, @"ShowLaunchProhibitedApps" : @YES }, &dict);
//     if (err) {
//         derror("Err looking up application, exiting...\n");
//         return 1;
//     }
//     
//     if (!name) {
//         dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor(dc_yellow), [name UTF8String], colorEnd(), dcolor(dc_bold), colorEnd());
//         return 1;
//     }
//     
//     NSDictionary *appParams = [dict objectForKey:name];
//     NSString *path = appParams[@"Path"];
//     if (!path) {
//         derror("couldn't get the path for app %s\n", name.UTF8String);
//         return 1;
//     }
//     NSString *bundleID = appParams[@"CFBundleIdentifier"];
//     if (!bundleID) {
//         derror("couldn't get the bundleID\n");
//         return 1;
//     }
//     
//     NSString *arguments = global_options.programArguments;
//     NSArray *environment = options[kProcessEnvVars];
//     
//     NSMutableDictionary *dictionaryEnvironment = [NSMutableDictionary new];
//     for (NSString *val in environment) {
//         NSArray *components = [val componentsSeparatedByString:@"="];;
//         if ([components count] != 2) {
//             dsprintf(stderr, "Couldn't process \"%s\"\n", val.UTF8String);
//             continue;
//         }
//         NSString *key = components.firstObject;
//         NSString *object = components.lastObject;
//         [dictionaryEnvironment setObject:object forKey:key];
//     }
//     
     
    am_device_service_connection* instruments_connection = (__bridge am_device_service_connection*) connect_to_instruments_server(d);

//     launch_application(instruments_connection, bundleID.UTF8String, [arguments componentsSeparatedByString:@" "], dictionaryEnvironment);
     
//    am_device_service_connection *serviceConnection = (am_device_service_connection*)connect_to_instruments_server(d);
//    
//
    print_proclist(instruments_connection);
//
//    AMDeviceStopSession(d);
//    AMDeviceDisconnect(d);
    return 0;
}
