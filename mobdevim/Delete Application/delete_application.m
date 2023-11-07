//
//  install_application.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "install_application.h"

NSString * const kDeleteApplicationIdentifier = @"com.selander.delete.bundleidentifier";


int delete_application(AMDeviceRef d, NSDictionary *options) {
    
    NSDictionary *dict;
    NSString *name = [options objectForKey:kDeleteApplicationIdentifier];
    if (!name) {
        dsprintf(stderr, "You must provide a bundleIdentifier to delete\n");
        return 1;
    }
    
    AMDeviceLookupApplications(d, @{ @"ReturnAttributes": @YES, @"ShowLaunchProhibitedApps" : @YES }, &dict);
    if (![dict objectForKey:name]) {
        dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor(dc_yellow), [name UTF8String], colorEnd(), dcolor(dc_bold), colorEnd());
        return 1;
    }
    
    if (!global_options.quiet) {
        dsprintf(stdout, "Are you sure you want to delete \"%s\"? [Y] ", [name UTF8String]);
        if (getchar() != 89) {
            dsprintf(stdout, "Exiting...\n");
            return 0;
        }
    }
    
    AMDServiceConnectionRef serviceConnection = nil;
    NSDictionary *inputDict = @{@"CloseOnInvalidate" : @YES};
    AMDeviceSecureStartService(d, @"com.apple.mobile.installation_proxy", inputDict, &serviceConnection);
    if (!serviceConnection) {
        return EACCES;
    }
    int error = AMDeviceSecureUninstallApplication(serviceConnection, NULL, name, @{}, NULL);
    if (error) {
        dsprintf(stderr, "Error removing \"%s\"\n", [name UTF8String]);
        return 1;
    }
    
    dsprintf(stdout, "Successfully removed \"%s\"\n", [name UTF8String]);
    return 0;
}
