//
//  yoink.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "remove_file.h"
#include <time.h>
#include <utime.h>
#include <sys/stat.h>

NSString * const kRemoveFileBundleID = @"com.selander.removefile.bundleid";

NSString * const kRemoveFileRemotePath = @"com.selander.removefile.removefilepath";

/// Max file size found in AFCFileRefRead
//#define MAX_TRANSFER_FILE_SIZE 8191

int remove_file(AMDeviceRef d, NSDictionary *options) {
    NSDictionary *dict;
    int returnError = 0;
    NSString *appBundle = [options objectForKey:kRemoveFileBundleID];
    NSDictionary *opts = @{ @"ApplicationType" : @"Any",
                            @"ReturnAttributes" : @[@"ApplicationDSID",
                                                    @"ApplicationType",
                                                    @"CFBundleDisplayName",
                                                    @"CFBundleExecutable",
                                                    @"CFBundleIdentifier",
                                                    @"CFBundleName",
                                                    @"CFBundleShortVersionString",
                                                    @"CFBundleVersion",
                                                    @"Container",
                                                    @"Entitlements",
                                                    @"EnvironmentVariables",
                                                    @"MinimumOSVersion",
                                                    @"Path",
                                                    @"ProfileValidated",
                                                    @"SBAppTags",
                                                    @"SignerIdentity",
                                                    @"UIDeviceFamily",
                                                    @"UIRequiredDeviceCapabilities"]};
    
    AMDeviceLookupApplications(d, opts, &dict);
    NSString *appPath = [[dict objectForKey:appBundle] objectForKey:@"Path"];
    
    if (!appPath) {
        dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor(dc_yellow), [appBundle UTF8String], colorEnd(), dcolor(dc_bold), colorEnd());
        return ENOENT;
    }
    
    NSString *remotePath = [options objectForKey:kRemoveFileRemotePath];
    if (remotePath) {
        dsprintf(stdout, "Searching for \"%s\" file on for \"%s\"\n", [remotePath UTF8String], [appBundle UTF8String]);
        
    } else {
        dsprintf(stdout, "Listing remote files for \"%s\", use the fullpath for a remote file to delete\n", [appBundle UTF8String]);
    }
    
    
    AMDServiceConnectionRef serviceConnection = nil;
    AMDStartService(d, @"com.apple.mobile.house_arrest", &serviceConnection);
    
    
    NSDictionary *inputDictionary = @{ @"Command" : @"VendContainer", @"Identifier" : appBundle };
    if (AMDServiceConnectionSendMessage(serviceConnection, inputDictionary, kCFPropertyListXMLFormat_v1_0)) {
        return EACCES;
    }
    
    __unused NSString *outputDirectory = [options objectForKey:kOptionArgumentDestinationPath] ? [options objectForKey:kOptionArgumentDestinationPath] : [NSString stringWithFormat:@"/tmp/%@_app", appBundle];
    [[NSFileManager defaultManager] createDirectoryAtPath:outputDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    long socket = AMDServiceConnectionGetSocket(serviceConnection);
    
    id info = nil;
    AMDServiceConnectionReceiveMessage(serviceConnection, &info, nil);
    
    
    NSString *currentDirectory = @"/";
    
    NSMutableSet *unexploredDirectories = [NSMutableSet set];
    NSMutableSet *exploredDirectories = [NSMutableSet set];
    NSMutableSet *exploredFiles = [NSMutableSet set];
    NSMutableSet *unexploredFiles = [NSMutableSet set];
    
    NSMutableDictionary *filePermissions = [NSMutableDictionary dictionary];
    
    [unexploredDirectories addObject:currentDirectory];
    
    AFCConnectionRef connectionRef = AFCConnectionCreate(0, (int)socket, 1, 0, 0);
    if (!connectionRef) {
        dsprintf(stderr, "%sCould not obtain a valid connection. Aborting%s\n", dcolor(dc_yellow), colorEnd());
        return EACCES;
    }
    
    BOOL successfullyReadADirectory = NO;
    while ([unexploredDirectories count] > 0) {
        
        char* remotePath = nil;
        AFCIteratorRef iteratorRef = nil;
        
        AFCDirectoryOpen(connectionRef, [currentDirectory UTF8String], &iteratorRef);
        
        while (AFCDirectoryRead(connectionRef, iteratorRef, &remotePath) == 0 && remotePath) {
            
            successfullyReadADirectory = YES;
            if (strcmp(remotePath, ".") == 0 || strcmp(remotePath, "..") == 0) {
                continue;
            }
            
            AFCIteratorRef fileIterator = NULL;
            NSString *pathReference = [currentDirectory stringByAppendingPathComponent:[NSString stringWithUTF8String:remotePath]];
            AFCFileInfoOpen(connectionRef, [pathReference UTF8String], &fileIterator);
            
            if (!fileIterator) {
                [exploredFiles addObject:pathReference];
                continue;
            }
            
            NSDictionary *filePermissionOptions = [(__bridge NSDictionary *)(fileIterator->fileAttributes) copy];
            NSString *file = [currentDirectory stringByAppendingPathComponent:[NSString stringWithUTF8String:remotePath]];
            
            if ([filePermissionOptions[@"st_ifmt"] isEqualToString:@"S_IFDIR"]) {
                [unexploredDirectories addObject:file];
                [exploredDirectories addObject:file];
            } else {
                [unexploredFiles addObject:file];
                [exploredFiles addObject:file];
            }
            
            NSString *finalizedFile = [outputDirectory stringByAppendingString:file];
            [filePermissions setObject:filePermissionOptions forKey:finalizedFile];
        }
        
        [unexploredDirectories removeObject:currentDirectory];
        NSString *nextDirectory = [unexploredDirectories anyObject];
        currentDirectory = nextDirectory;
        AFCDirectoryClose(connectionRef, iteratorRef);
    }
    
    
    NSMutableDictionary *outputContent = [NSMutableDictionary new];
    for (NSString *file in exploredFiles) {
        NSString *path = [file stringByDeletingLastPathComponent];
        if (![outputContent objectForKey:path]) {
            NSMutableArray *array = [NSMutableArray new];
            [outputContent setObject:array forKey:path];
        }
        
        NSMutableArray *ar = [outputContent objectForKey:path];
        
        NSString *finalizedString = [NSString stringWithFormat:@"\"%@\"", file];
        [ar addObject:finalizedString];
    }
    
    if (remotePath) {
        if (AFCRemovePath(connectionRef, [remotePath UTF8String])) {
            dsprintf(stderr, "couldn't remove file %s", [remotePath UTF8String]);
        } else {
            dsprintf(stdout, "Successfully removed file %s", [remotePath UTF8String]);
        }
        
        return 0;
    }
    dsprintf(stdout, "\n");
    for (NSString *key in outputContent) {
        
        NSArray *ar = [outputContent objectForKey:key];
        
        dsprintf(stdout, "%s%s%s\n", dcolor(dc_yellow),[key UTF8String], colorEnd());
        for (NSString *filename in ar) {
            dsprintf(stdout, "\t%s\n", [filename UTF8String]);
        }
        dsprintf(stdout, "\n");
    }
    
//    NSFileManager *manager = [NSFileManager defaultManager];
//
//    // write the directories first
//    for (NSString *path in exploredDirectories) {
//        NSString *finalizedDirectory = [outputDirectory stringByAppendingPathComponent:path];
//        [manager createDirectoryAtPath:finalizedDirectory withIntermediateDirectories:YES attributes:nil error:nil];
//    }
    
    // write the files
//    NSArray *paths = [exploredFiles allObjects];
//    for (NSString *path in paths) {
//        NSString *finalizedFile = [outputDirectory stringByAppendingPathComponent:path];
//
//
//        AFCFileDescriptorRef ref = NULL;
//        if (AFCFileRefOpen(connectionRef, [path UTF8String], 0x1, &ref) || !ref) {
//            continue;
//        }
//
//        NSError *err = NULL;
//        [[NSFileManager defaultManager] createFileAtPath:finalizedFile contents:nil attributes:nil];
//        NSFileHandle *handle = [NSFileHandle fileHandleForWritingToURL:[NSURL URLWithString:finalizedFile] error:&err];
//        if (err) {
//            dsprintf(stdout, "%s\nExiting...\n", [[err localizedDescription] UTF8String]);
//            return 1;
//        }
//        int fd = [handle fileDescriptor];
//
//        if (fd == -1) {
//            dsprintf(stderr, "%sCan't open \"%s\" to write to, might be an existing file there.\n", dcolor(dc_yellow), [finalizedFile UTF8String], colorEnd());
//            returnError = 1;
//            continue;
//        }
//
//        size_t size = BUFSIZ;
//        void *buffer[BUFSIZ];
//        while (AFCFileRefRead(connectionRef, ref, buffer, &size) == 0 && size != 0 && size != -1) {
//            write(fd, buffer, size);
//        }
//
//        [handle closeFile];
//        AFCFileRefClose(connectionRef, ref);
//    }
//
//    AFCConnectionClose(connectionRef);
//
//    for (NSString *file in filePermissions) {
//        NSDictionary *permissions = filePermissions[file];
//        struct stat filestat;
//        if (stat([file UTF8String], &filestat) != 0) { continue; }
//
//
//
//        for (NSString *permission in permissions) {
//
//            if ([permission isEqualToString:@"st_birthtime"]) {
//                //        filestat.st_birthtimespec = time(<#time_t *#>);
//
//            } else if ([permission isEqualToString:@"st_mtime"]) {
//
//            }
//        }
//    }
//
//    if (successfullyReadADirectory) {
//        dsprintf(stdout, "Opening \"%s\"...\n", [outputDirectory UTF8String]);
//        if (!quiet_mode) {
//            NSString *systemCMDString = [NSString stringWithFormat:@"open -R %@", outputDirectory];
//            system([systemCMDString UTF8String]);
//        }
//    } else {
//        dsprintf(stderr, "%sUnable to open \"%s\", likely due to not having certificates that match on this device%s\n", dcolor(dc_yellow), [appBundle UTF8String], colorEnd());
//        returnError = EACCES;
//    }
    
    return returnError;
}


