//
//  list_applications.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "list_applications.h"

NSString *const kListApplicationsName = @"com.selander.listapplications.appname";
NSString *const kListApplicationsKey = @"com.selander.listapplications.key";

int list_applications(AMDeviceRef d, NSDictionary *options) {
    
    NSDictionary *dict;
    NSString *name = [options objectForKey:kListApplicationsName];
    
    if (name) {
        AMDeviceLookupApplications(d, @{ @"ReturnAttributes": @YES, @"ShowLaunchProhibitedApps" : @YES }, &dict);
        if (![dict objectForKey:name]) {
            dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor(dc_yellow), [name UTF8String], colorEnd(), dcolor(dc_bold), colorEnd());
            return 1;
        }
        
        NSString *key = [options objectForKey:kListApplicationsKey];
        if (key) {
            if (getenv("DSPLIST")) {
                global_options.quiet = NO;
                dsprintf(stdout, "%s\n", [[[dict objectForKey:name] objectForKey:key] dsformattedOutput]);
            } else {
                dsprintf(stdout, "Dumping info for \"%s%s%s\" with key: \"%s%s%s\"\n%s\n", dcolor(dc_red), [name UTF8String], colorEnd(), dcolor(dc_red),  [key UTF8String], colorEnd(), [[[dict objectForKey:name] objectForKey:key] dsformattedOutput]);
            }
            if (![[dict objectForKey:name] objectForKey:key]) {
                return 1;
            }
        } else {
            if (getenv("DSPLIST")) {
                global_options.quiet = NO;
                dsprintf(stdout, "%s\n", [[dict objectForKey:name] dsformattedOutput]);
            } else {
                dsprintf(stdout, "%sDumping info for \"%s\"%s\n\n%s\n", dcolor(dc_red), [name UTF8String], colorEnd(),  [[dict objectForKey:name] dsformattedOutput]);
            }
        }
    } else {
        // name is nil
        AMDeviceLookupApplications(d, @{@"ReturnAttributes": @[@"ProfileValidated", @"CFBundleIdentifier", @"SBAppTags", @"ApplicationType", @"CFBundleDisplayName"], @"ShowLaunchProhibitedApps" : @YES}, &dict);
        NSMutableString *output = [NSMutableString string];
        for (NSString *key in [dict allKeys]) {
            NSDictionary *appDict = dict[key];
            NSString *appName = appDict[@"CFBundleDisplayName"];
            if ([appDict[@"ProfileValidated"] boolValue]) {
                [output appendString:[NSString stringWithFormat:@"%s%@, %@%s\n", dcolor(dc_cyan), key, appName, colorEnd()]];
            } else if ([appDict[@"ApplicationType"] isEqualToString:@"Internal"]) {
                [output appendString:[NSString stringWithFormat:@"%s%@, %@%s\n", dcolor(dc_magenta), key, appName, colorEnd()]];
            } else if ([appDict[@"SBAppTags"] containsObject:@"hidden"]) {
                [output appendString:[NSString stringWithFormat:@"%s%@, %@%s\n", dcolor(dc_yellow), key, appName, colorEnd()]];
            } else if ([appDict[@"ApplicationType"] isEqualToString:@"System"]) {
                [output appendString:[NSString stringWithFormat:@"%s%@, %@%s\n", dcolor(dc_red), key, appName, colorEnd()]];
            }
            else {
                [output appendString:[NSString stringWithFormat:@"%@, %@\n", key, appName]];
            }
          
        }
        
        NSString *colorHelper = @"";
        if (getenv("DSCOLOR")) {
            colorHelper = [NSString stringWithFormat:@"\t%s█ Hidden%s\t%s█ Developer%s\t%s█ System%s\t%s█ Internal%s\n", dcolor(dc_yellow), colorEnd(), dcolor(dc_cyan), colorEnd(), dcolor(dc_red), colorEnd(), dcolor(dc_magenta), colorEnd()];
        }
        dsprintf(stdout, "Dumping bundleIDs for all apps\n\n%s%s", [colorHelper UTF8String],  [output UTF8String]);
    }
    
    AMDeviceDisconnect(d);
    
    return 0;
}
