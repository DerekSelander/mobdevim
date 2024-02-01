//
//  install_application.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "wifie_connect.h"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

//#define CURRENT_DMG @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/14.2/DeveloperDiskImage.dmg"

//#define CURRENT_DMG_SIG @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/14.2/DeveloperDiskImage.dmg.signature"

NSString *const kWifiConnectUUID = @"com.selander.wificonnect.uuid";
NSString *const kWifiConnectUUIDDisable = @"com.selander.wificonnect.uuid.disable";

int wifi_connect(AMDeviceRef d, NSDictionary *options) {
 
    long flags;
    BOOL should_disable = [[options objectForKey:kWifiConnectUUIDDisable] boolValue];
    NSString *uuid_param = [options objectForKey:kWifiConnectUUID];
    if (uuid_param) {
        CFUUIDRef ref = CFUUIDCreateFromString(kCFAllocatorDefault, (CFStringRef)uuid_param);
        NSString *resolved_uuid = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, ref));
        if ([resolved_uuid isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
            derror("Couldn't resolve UUID: \"%s\"\n", uuid_param.UTF8String);
            exit(1);
        }
        uuid_param = resolved_uuid;
    } else {
        uuid_param = GetHostUUID();
    }
    
    handle_err(AMDeviceGetWirelessBuddyFlags(d, &flags));
    dprint("original wifi flags are 0x%x\n", flags);
    if (should_disable) {
        dprint("disbling wifi...\n");
        handle_err(AMDeviceSetWirelessBuddyFlags(d, 0));
        AMDeviceSetValue(d, @"com.apple.mobile.wireless_lockdown", @"EnableWifiDebugging", @NO);
        AMDeviceSetValue(d, @"com.apple.mobile.wireless_lockdown", @"EnableWifiConnections", @NO);
        AMDeviceSetValue(d, @"com.apple.xcode.developerdomain", @"WirelessHosts", @[]);
        return 0;
    } else {
        handle_err(AMDeviceSetWirelessBuddyFlags(d, flags | 3)) // 1 enable wifi, 2 broadcast;
    }
    
    NSArray <NSString*>*hosts = AMDeviceCopyValue(d, @"com.apple.xcode.developerdomain", @"WirelessHosts", 0);
    if (!hosts) {
        hosts = @[];
    }
    BOOL foundIt = NO;
    for (NSString *h in hosts) {
        if ([h containsString:uuid_param]) {
            foundIt = YES;
        }
    }
    
    if (!foundIt) {
        NSMutableArray *mutableHosts = [hosts mutableCopy];
        [mutableHosts addObject:uuid_param];
        AMDeviceSetValue(d, @"com.apple.xcode.developerdomain", @"WirelessHosts", mutableHosts);
    }

    AMDeviceSetValue(d, @"com.apple.mobile.wireless_lockdown", @"EnableWifiDebugging", @YES);
    AMDeviceSetValue(d, @"com.apple.mobile.wireless_lockdown", @"EnableWifiConnections", @YES);
    
    dprint("Enabled WIFI debugging on host \"%s\"\n", uuid_param.UTF8String);
    return 0;
}
