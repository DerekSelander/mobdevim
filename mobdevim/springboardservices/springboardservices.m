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
NSString * const kProcessKillPID = @"com.selander.process.kill";
NSString * const kSBCommand = @"com.selander.springboard_services.command";

/// Max file size found in AFCFileRefRead
//#define MAX_TRANSFER_FILE_SIZE 8191

int springboard_services(AMDeviceRef d, NSDictionary *options) {
    
    NSString *deviceUDID = AMDeviceGetName(d);
    NSString *savePath = [NSString stringWithFormat:@"%s%@_sbicons.backup", getenv("TMPDIR"), deviceUDID];

    
    int returnError = 0;
    AMDServiceConnectionRef serviceConnection = nil;
    AMDStartService(d, @"com.apple.springboardservices", &serviceConnection);

    
    
    // gets the max counts for what springboard will allow
    if (AMDServiceConnectionSendMessage(serviceConnection,  @{ @"command" : @"getHomeScreenIconMetrics" }, kCFPropertyListXMLFormat_v1_0)) {
        return EACCES;
    }
    NSDictionary *metricDict = nil;
    if (AMDServiceConnectionReceiveMessage(serviceConnection, &metricDict, nil)) {
        return  EACCES;
    }
    NSInteger maxSpringboardPages = [metricDict[@"homeScreenIconMaxPages"] integerValue];
    NSInteger maxFolderPages = [metricDict[@"homeScreenIconFolderMaxPages"] integerValue];
    NSInteger homeScreenIconRows = [metricDict[@"homeScreenIconRows"] integerValue];
    NSInteger homeScreenIconColumns = [metricDict[@"homeScreenIconColumns"] integerValue];
    
    
    // Get the icons and put them in an NSArray called iconsInfo
    if (AMDServiceConnectionSendMessage(serviceConnection,  @{ @"command" : @"getIconState", @"formatVersion" : @2 }, kCFPropertyListXMLFormat_v1_0)) {
        return EACCES;
    }
    NSArray *iconsInfo = nil;
    if (AMDServiceConnectionReceiveMessage(serviceConnection, &iconsInfo, nil)) {
        return EACCES;
    }
    
    NSString *optionsCommand = options[kSBCommand];

    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath]) {
        if ([optionsCommand isEqualToString:@"restore"]) {
            NSData *data = [NSData dataWithContentsOfFile:savePath];
            NSArray *newIcons = [NSPropertyListSerialization propertyListWithData:data options:0 format:0 error:nil];
            dsprintf(stdout, "Attempting to restore icons from \"%s\"\n", [savePath UTF8String]);
            if (AMDServiceConnectionSendMessage(serviceConnection, @{@"command" : @"setIconState", @"iconState" : [newIcons copy]}, kCFPropertyListXMLFormat_v1_0)) {
                return EACCES;
            }
            
            return returnError;
        }
        dsprintf(stdout, "Overwrite backup file? [Y/n] ");
        char c = getchar();
        if (c == 'Y') {
            dsprintf(stdout, "Writing backup to \"%s\"\n", [savePath UTF8String]);
            [[NSPropertyListSerialization dataWithPropertyList:iconsInfo format:NSPropertyListXMLFormat_v1_0 options:0 error:nil]  writeToFile:savePath atomically:YES];
        }
    } else {
        dsprintf(stdout, "Writing backup to \"%s\"\n", [savePath UTF8String]);
        [[NSPropertyListSerialization dataWithPropertyList:iconsInfo format:NSPropertyListXMLFormat_v1_0 options:0 error:nil]  writeToFile:savePath atomically:YES];
    }
    
    if (!optionsCommand) {
        NSError *err = nil;
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:iconsInfo format:NSPropertyListXMLFormat_v1_0 options:0 error:&err];
        if (err) {
            dsprintf(stderr, "%s\n", [[err localizedDescription] UTF8String]);
        }
        NSString *iconPlistPath = [NSString stringWithFormat:@"/tmp/%@_sbicons.plist", deviceUDID];
        dsprintf(stdout, "%Writing Springboard icons to \"%s\"\n", [iconPlistPath UTF8String]);
        [data writeToFile:iconPlistPath atomically:YES];
         [[NSWorkspace sharedWorkspace] openFile:iconPlistPath];
        return returnError;
    }
    
    
    // Check if kSBCommand gives a valid path
    if ([[NSFileManager defaultManager] fileExistsAtPath:optionsCommand]) {
        dsprintf(stdout, "Attempting to write Springboard icons from \"%s\"\n", [optionsCommand UTF8String]);
        NSData *data = [NSData dataWithContentsOfFile:optionsCommand];
        if (!data) {
            dsprintf(stderr, "Invalid property list from \"%s\"s\n", optionsCommand);
            return returnError;
        }
        NSError *err = nil;
        id newIcons = [NSPropertyListSerialization propertyListWithData:data options:0 format:0 error:&err];
        if (err) {
            dsprintf(stderr, "%s\n", [[err localizedDescription] UTF8String]);
            return returnError;
        }
        if (AMDServiceConnectionSendMessage(serviceConnection, @{@"command" : @"setIconState", @"iconState" : [newIcons copy]}, kCFPropertyListXMLFormat_v1_0)) {
            return EACCES;
        }
        return returnError;
    }
    
    
    if (![optionsCommand isEqualToString:@"asshole"]) {
        return returnError;
    }
    
    dsprintf(stdout, "Arranging apps in \"asshole\" mode\n");
    NSMutableArray *flatIcons = [NSMutableArray arrayWithCapacity:400];
    for (int pageIndex = 0; pageIndex < [iconsInfo count]; pageIndex++) {
        
        NSArray *page = iconsInfo[pageIndex];
        for (int j = 0; j < [page count]; j++) {
            NSDictionary *appDict = [page objectAtIndex:j];
            // if we have this key, then its an app
            if (appDict[@"displayIdentifier"]) {
                [flatIcons addObject:appDict];
                continue;
            }
            
            // Drill into the folders....
            NSArray *folderArray = appDict[@"iconLists"];
            if (folderArray) {
                for (int folderPageIndex = 0; folderPageIndex < [folderArray count]; folderPageIndex++) {
                    NSArray *folderPage = folderArray[folderPageIndex];
                    [flatIcons addObjectsFromArray:folderPage];
                }
            }
        }
    }

    // Shuffle the icons
    NSInteger c = [flatIcons count];
//    for (int i = 0 ; i< c; i++) {
//        printf("%s\n", [[flatIcons[i][@"bundleIdentifier"] description] UTF8String]);
//    }
    for (NSUInteger i = 0; i < c - 1; ++i) {
        NSInteger remainingCount = c - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [flatIcons exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
    
    
    
    NSMutableArray *newIcons = [NSMutableArray arrayWithCapacity:maxSpringboardPages];
    // blank array for the dock, don't want any in there
    [newIcons addObject:@[]];
    int currentPageIndex = (int)maxSpringboardPages - 1;
    
    NSUInteger count = [flatIcons count];
    for (int i = 0; i < count; i++) {
        NSDictionary *icon = flatIcons[i];
        
        // Max out each springboard page first with an initial folder
        if ([newIcons count] < maxSpringboardPages) {
//            NSString *randomName = [flatIcons[arc4random_uniform((uint32_t)count)] objectForKey:@"displayName"];
            NSMutableArray *iconPages = [NSMutableArray arrayWithObject:icon];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"displayName" : @"U mad, bro?", @"iconLists" : [NSMutableArray arrayWithObject:iconPages], @"listType" : @"folder"}];
            NSMutableArray *iconLists = [NSMutableArray arrayWithObject:dict];
            
            [newIcons addObject:iconLists];
            continue;
        }
        
        // If there's a folder for each SB page, max out the latest folder's pages
        do {
            
            NSMutableArray *page = newIcons[currentPageIndex];
            if ([page count] >= homeScreenIconRows * homeScreenIconColumns) {
                currentPageIndex--;
                continue;
            }
            
            if (currentPageIndex < 0) {
                dsprintf(stderr, "Couldn't make room for all the icons\n");
                return EACCES;
            }
            
            NSMutableDictionary* foldersDict = [page lastObject];

            NSMutableArray *folderPage = foldersDict[@"iconLists"];
            
            if ([folderPage count] < maxFolderPages) {
                [folderPage addObject:[NSMutableArray arrayWithObject:icon]];
                break;
            } else {
                currentPageIndex--;
                continue;
//                NSMutableArray *iconPages = [NSMutableArray arrayWithObject:icon];
//                [folderPage addObject:iconPages];
                break;
            }
            
        } while (1);
    }
 
    
    if (AMDServiceConnectionSendMessage(serviceConnection, @{@"command" : @"setIconState", @"iconState" : [newIcons copy]}, kCFPropertyListXMLFormat_v1_0)) {
        return EACCES;
    }
    
    id info = nil;
    while(!AMDServiceConnectionReceive(serviceConnection, &info, 8)) { }
    
    
    AMDServiceConnectionInvalidate(serviceConnection);
    return returnError;
}


