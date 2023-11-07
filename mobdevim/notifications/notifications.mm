//
//  springboardservices.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "springboardservices.h"
#include <time.h>
#include <utime.h>
#include <sys/stat.h>


//NSString * const kSBSFileBundleID = @"com.selander.springboard_services.bundleid";

//NSString * const kSBCommand = @"com.selander.springboard_services.command";

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
#import <dlfcn.h>

//static void preload() {
//    XRUniqueIssueAccumulator *responder = [XRUniqueIssueAccumulator new];
//    XRPackageConflictErrorAccumulator *accumulator = [[XRPackageConflictErrorAccumulator alloc] initWithNextResponder:responder];
//    [DVTDeveloperPaths initializeApplicationDirectoryName:@"Instruments"];
//
//    void (*PFTLoadPlugin)(id, id) = dlsym(RTLD_DEFAULT, "PFTLoadPlugins");
//    PFTLoadPlugin(nil, accumulator);
//}

#ifdef __cplusplus
extern "C" {
#endif

static NSDictionary* handleNoFilepathGiven() {
    if (global_options.pushNotificationPayloadPath) {
        NSDictionary* payload = [NSDictionary dictionaryWithContentsOfFile:global_options.pushNotificationPayloadPath];
        if (!payload) {
            printf("Invalid payload from \"%s\"\n", global_options.pushNotificationPayloadPath.UTF8String);
            exit(1);
        }
        return payload;
    }
    NSString *path = @"/tmp/apns_payload.plist";
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSDictionary * tmpDictionary = @{@"aps" :
                                             @{@"alert" : @{ @"title": @"Alert title",
                                                             @"body" : @"Alert body" },
                                               @"badge" : @1,
                                               @"sound" : @"default" }};
        
        [tmpDictionary writeToFile:path atomically:YES];
        printf("No payload dictionary given! Created one at \"%s\", see https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html\n", path.UTF8String);
    } else {
        printf("No payload dictionary given! See https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html\n");
    }
    exit(1);
}

int notification_proxy2(AMDeviceRef d, NSDictionary *options) {
    NSString *name = global_options.programBundleID;
    NSDictionary *dict = nil;
    mach_error_t err = AMDeviceLookupApplications(d, @{ @"ReturnAttributes": @YES, @"ShowLaunchProhibitedApps" : @YES }, &dict);
    if (err) {
        derror("Err looking up application, exiting...\n");
        exit(1);
    }
    
    if (!name) {
        derror("%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor(dc_yellow), [name UTF8String], colorEnd(), dcolor(dc_bold), colorEnd());
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
    AMDServiceConnectionRef serviceConnection = nil;
    AMDStartService(d, @"com.apple.mobile.notification_proxy", &serviceConnection);
    
    // gets the max counts for what springboard will allow
    handle_err(AMDServiceConnectionSendMessage(serviceConnection,  @{ @"command" : @"getHomeScreenIconMetrics" }, kCFPropertyListXMLFormat_v1_0));
    
    NSDictionary *metricDict = nil;
    handle_err(AMDServiceConnectionReceiveMessage(serviceConnection, &metricDict, nil));
    
    return 0;
}
    
int notification_proxy(AMDeviceRef d, NSDictionary *options) {
//    if (!getenv("YAYYAY")) {
//        return 0;
//    }
    NSString *name = global_options.programBundleID;
    NSDictionary *dict = nil;
    NSDictionary *payloadDictionary = handleNoFilepathGiven();
    mach_error_t err = AMDeviceLookupApplications(d, @{ @"ReturnAttributes": @YES, @"ShowLaunchProhibitedApps" : @YES }, &dict);
    if (err) {
        dsprintf(stderr, "Err looking up application, exiting...\n");
        exit(1);
    }
    
    if (!name) {
        dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor(dc_yellow), [name UTF8String], colorEnd(), dcolor(dc_bold), colorEnd());
        return 1;
    }
    
    NSDictionary *appParams = [dict objectForKey:name];
    NSString *path = appParams[@"Path"];
    if (!path) {
        dsprintf(stderr, "couldn't get the path for app %s\n", name.UTF8String);
        return 1;
    }
    NSString *bundleID = appParams[@"CFBundleIdentifier"];
    if (!bundleID) {
        dsprintf(stderr, "couldn't get the bundleID\n");
        return 1;
    }
    
//    preload();
    XRMobileDevice* device  = [[NSClassFromString(@"XRMobileDevice") alloc] initWithDevice:d];
    if (!device) {
        dsprintf(stderr, "couldn't maintain a device connection\n");
        return 1;
    }
    id connection = [device connection];
    NSString *identifier = @"com.apple.instruments.server.services.processcontrol.feature.deviceio";
    int version = [connection remoteCapabilityVersion:identifier];
    if (!version) {
        printf("Couldn't find capability on device!\n");
        [connection  cancel];
        return 1;
    }
    
    id springboardChannel = [connection makeChannelWithIdentifier:identifier];
    //    id springboardChannel = [connection makeChannelWithIdentifier:@"com.apple.instruments.server.services.processcontrol.feature.deviceio"];
    //    com.apple.instruments.server.services.processcontrol.feature.deviceio
    // [DTXConnection remoteCapabilityVersion:@"com.apple.instruments.server.services.processcontrol.capability.signal"];
    
    
    //    id channel = [device deviceInfoService];
    //    id processControlChannel = [device defaultProcessControlChannel];
    id msg = [NSClassFromString(@"DTXMessage") messageWithSelector:NSSelectorFromString(@"processIdentifierForBundleIdentifier:") objectArguments: name, nil];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    __block NSNumber* pidNumber = nil;
    [springboardChannel sendMessageSync:msg replyHandler:^(DTXMessage *response, int extra) {
        if ([response error]) {
            printf("%s\n", response.error.description.UTF8String);
        }
        pidNumber = response.payloadObject;
        dispatch_group_leave(group);
    }];
    dispatch_group_wait(group, 10);
    if (!pidNumber) {
        printf("Couldn't find pid for \"%s\"", name.UTF8String);
        [connection  cancel];
        return 1;
    }
    
    // We here if we have a valid PID
simulateNotificationForBundleID:payload:withError:
    dispatch_group_enter(group);
    NSDictionary *payload = @{@"PCEventType" : @"SimulateNotification",
                              @"BundleIdentifier": name,
                              @"NotificationPayload" : payloadDictionary};
    id msg_2 = [NSClassFromString(@"DTXMessage") messageWithSelector:NSSelectorFromString(@"sendProcessControlEvent:toPid:") objectArguments: [NSKeyedArchiver archivedDataWithRootObject:payload], pidNumber,  nil];
    [springboardChannel sendMessageSync:msg_2 replyHandler:^(DTXMessage *response, int extra) {
        if ([response error]) {
            printf("%s\n", response.error.description.UTF8String);
        }
        dispatch_group_leave(group);
    }];
    
    dispatch_group_wait(group, 10);
    
    
    return 0;
}

#ifdef __cplusplus
}
#endif 
