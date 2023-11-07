//
//  open_program.m
//  mobdevim
//
//  
//  Copyright © 2020 Selander. All rights reserved.
//

#import "open_program.h"
#import "../misc/InstrumentsPlugin.h"
#import "../Debug Application/debug_application.h"
#import "ios_instruments_client.h"
#import <dlfcn.h>


int open_program(AMDeviceRef d, NSDictionary *options) {
   
    NSString *name = global_options.programBundleID;
    NSDictionary *dict = nil;
    mach_error_t err = AMDeviceLookupApplications(d, @{ @"ReturnAttributes": @YES, @"ShowLaunchProhibitedApps" : @YES }, &dict);
    if (err) {
        derror("Err looking up application, exiting...\n");
        return 1;
    }
    
    if (!name) {
        dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor(dc_yellow), [name UTF8String], colorEnd(), dcolor(dc_bold), colorEnd());
        return 1;
    }
    
    NSDictionary *appParams = [dict objectForKey:name];
    NSString *path = appParams[@"Path"];
    if (!path) {
        derror("couldn't get the path for app %s\n", name.UTF8String);
        return 1;
    }
    NSString *bundleID = appParams[@"CFBundleIdentifier"];
    if (!bundleID) {
        derror("couldn't get the bundleID\n");
        return 1;
    }
    
//    preload();
//    XRMobileDevice* device  = [[NSClassFromString(@"XRMobileDevice") alloc] initWithDevice:d];
//    if (!device) {
//        dsprintf(stderr, "couldn't maintain a device connection\n");
//        return 1;
//    }
    // ___lldb_unnamed_symbol79$$XRMobileDeviceDiscoveryPlugIn
    // AMDCopyArrayOfDevicesMatchingQuery

//    NSString *arguments = @"-NSAccentuateLocalizedStrings YES";
//    NSDictionary *environme   nt = @{};
    NSString *arguments = global_options.programArguments;
    NSArray *environment = options[kProcessEnvVars];
    
    NSMutableDictionary *dictionaryEnvironment = [NSMutableDictionary new];
    for (NSString *val in environment) {
        NSArray *components = [val componentsSeparatedByString:@"="];;
        if ([components count] != 2) {
            dsprintf(stderr, "Couldn't process \"%s\"\n", val.UTF8String);
            continue;
        }
        NSString *key = components.firstObject;
        NSString *object = components.lastObject;
        [dictionaryEnvironment setObject:object forKey:key];
    }
    
    
    am_device_service_connection* instruments_connection = (am_device_service_connection*) connect_to_instruments_server(d);

    launch_application(instruments_connection, bundleID.UTF8String, [arguments componentsSeparatedByString:@" "], dictionaryEnvironment);
    
//    launch_application(instruments_connection, NULL, NULL, NULL);
//
//    PFTProcess *process = [[PFTProcess alloc] initWithDevice:device path:path bundleIdentifier:bundleID arguments:arguments environment:dictionaryEnvironment launchOptions:nil];
//
//    NSError *error = nil;
//    [device launchProcess:process suspended:NO error:&error];
//    if (error) {
//        printf("%s\n", error.localizedDescription.UTF8String);
//    }

    return 0;
}
