//
//  get_provisioning_profiles.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

@import Security;
#import "get_provisioning_profiles.h"
NSString * const kProvisioningProfilesCopyDeveloperCertificates =  @"com.selander.provisioningprofiles.copydevelopercertificates";

NSString * const kProvisioningProfilesFilteredByDevice =  @"com.selander.provisioningprofiles.filteredbydevice";

int get_provisioning_profiles(AMDeviceRef d, NSDictionary *options) {
    
    NSArray *profiles = AMDeviceCopyProvisioningProfiles(d);
    
    BOOL copyDeveloperCertificates = [[options objectForKey:kProvisioningProfilesCopyDeveloperCertificates] boolValue];
    NSString* filterProvisioninProfilesThatOnlyFitDevice = [options objectForKey:kProvisioningProfilesFilteredByDevice];
    for (id a  in profiles) {
        extern int AMDeviceRemoveProvisioningProfile(AMDeviceRef b, NSString* a);
        int b =AMDeviceRemoveProvisioningProfile(d, [MISProfileCopyPayload(a) objectForKey:@"UUID"]);
        printf("%d\n", b);
    }
    
    NSArray *filteredProfiles = [profiles filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        
        if (filterProvisioninProfilesThatOnlyFitDevice) {
            return [[MISProfileCopyPayload(evaluatedObject) objectForKey:@"UUID"] containsString:filterProvisioninProfilesThatOnlyFitDevice];
        }
        
        return (BOOL)[MISProfileCopyPayload(evaluatedObject) objectForKey:@"Name"];
    }]];
    
    if (!filterProvisioninProfilesThatOnlyFitDevice) {
        dsprintf(stdout, "Dumping provisioning profiles\n\n");
    }
    
    
    NSString *appName = AMDeviceCopyDeviceIdentifier(d);
    
    NSString *directory = [NSString stringWithFormat:@"/tmp/%@_certificates", appName];
    
    for (id i in filteredProfiles) {
        NSDictionary *dict = MISProfileCopyPayload(i);
        NSString *teamName = dict[@"TeamName"];
        NSString *appIDName = dict[@"AppIDName"];
        NSString *appID = dict[@"Entitlements"][@"application-identifier"];
//        NSString *apsEnv = dict[@"Entitlements"][@"aps-environment"];
        NSString *uuid = dict[@"UUID"];
        NSString *name = dict[@"Name"];
        NSArray *certs = dict[@"DeveloperCertificates"];
        NSDate *expirationDate = dict[@"ExpirationDate"];
        NSMutableArray *certificateNames = [NSMutableArray new];
        for (int i = 0; i < [certs count]; i++) {
            NSData *data = certs[i];
            CFDataRef dataRef = CFDataCreate(NULL, [data bytes], [data length]);
            SecCertificateRef secref = SecCertificateCreateWithData(nil, dataRef);
            
            
            // Common name
            CFStringRef commonNameRef = NULL;
            SecCertificateCopyCommonName(secref, &commonNameRef);
            NSString *commonName = CFBridgingRelease(commonNameRef);
            
            //          NSString* objectSummary = CFBridgingRelease(SecCertificateCopySubjectSummary(secref));
            
            CFArrayRef keysRef = NULL;
            NSDictionary* certDict =  CFBridgingRelease(SecCertificateCopyValues(secref, keysRef, nil));
            
            NSNumber *validBefore = nil;
            NSNumber *validAfter = nil;
            NSString *serialValue = nil;
            for (NSDictionary *key in certDict) {
                if ([certDict[key][@"label"] isEqualToString:@"Serial Number"]) {
                    serialValue = certDict[key][@"value"];
                    continue;
                } else if ([certDict[key][@"label"] isEqualToString:@"Not Valid Before"]) {
                    validBefore = certDict[key][@"value"];
                    continue;
                } else if ([certDict[key][@"label"] isEqualToString:@"Not Valid After"]) {
                    validAfter = certDict[key][@"value"];
                    continue;
                }
            }
            
            [certificateNames addObject:@{@"Common Name"  : commonName,
                                          @"Serial Number": serialValue ? serialValue : @"NULL",
                                          @"Valid Before" : (validBefore ? [NSDate dateWithTimeIntervalSinceReferenceDate:[validBefore doubleValue]] : @"NULL"),
                                          @"Valid After"  : (validAfter ? [NSDate dateWithTimeIntervalSinceReferenceDate:[validAfter doubleValue]] : @"NULL"),
                                          }];
            
        }
        
//        if (filterProvisioninProfilesThatOnlyFitDevice) {
//            NSArray *provisionedDevices = dict[@"ProvisionedDevices"];
//            if(![provisionedDevices containsObject:deviceIdentifier]) {
//                continue;
//            }
//        }
        
        if (copyDeveloperCertificates) {
            NSFileManager *fileManager= [NSFileManager defaultManager];
            
            if(![fileManager fileExistsAtPath:directory isDirectory:NULL]) {
                [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
            }
            for (NSData *data in dict[@"DeveloperCertificates"]) {
                NSString *certPath = [NSString stringWithFormat:@"%@/%@_%@.cer", directory, appID, uuid];
                [data writeToFile:certPath atomically:YES];
            }
            continue;
        }
        
        
        NSMutableString *outputString = [NSMutableString stringWithFormat:@"\n%s**************************************%s\nApplication-identifier: %s%@%s\nTeamName: %s%@%s\nAppIDName: %s%@%s\nProvisioning Profile: %s%@%s\nExpiration: %s%s%s\nUUID: %s%@%s",
                                         dcolor(dc_yellow), colorEnd(),
                                         dcolor(dc_bold), appID, colorEnd(),
                                         dcolor(dc_bold), teamName, colorEnd(),
                                         dcolor(dc_bold), appIDName, colorEnd(),
                                         dcolor(dc_bold), name, colorEnd(),
                                         dcolor(dc_bold), [expirationDate dsformattedOutput], colorEnd(),
                                         dcolor(dc_bold), uuid, colorEnd()];
        if (filterProvisioninProfilesThatOnlyFitDevice) {
            NSMutableDictionary *outputDict = [NSMutableDictionary dictionaryWithDictionary:dict];
            [outputDict removeObjectForKey:@"DeveloperCertificates"];
            [outputDict setObject:certificateNames forKey:@"DeveloperCertificates"];
            dsprintf(stdout, "Dumping Provisioning Profile info for UUID \"%s%s%s\"...\n%s\n", dcolor(dc_cyan), [filterProvisioninProfilesThatOnlyFitDevice UTF8String], colorEnd(), [outputDict dsformattedOutput]);
        } else {
            dsprintf(stdout, "%s\n", [outputString UTF8String]);
        }
    }
    
    
    if (copyDeveloperCertificates) {
        dsprintf(stdout, "Opening directory containing dev certificates from device...\n");
        [[NSWorkspace sharedWorkspace] openFile:directory];
    }
    
    return 0;
}
