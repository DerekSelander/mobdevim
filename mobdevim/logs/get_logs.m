//
//  send_files.m
//  mobdevim
//
//  
//  Copyright © 2020 Selander. All rights reserved.
//

#import "send_files.h"
#import <stdio.h>

NSString * const kGetLogsFilePath = @"com.selander.get_logs.sendfilepath";

NSString * const kGetLogsAppBundle = @"com.selander.get_logs.appbundle";

NSString * const kGetLogsDelete = @"com.selander.get_logs.delete";

@implementation NSString (STUFF)

- (BOOL)ds_isAllDigits {
    NSCharacterSet* nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange r = [self rangeOfCharacterFromSet: nonNumbers];
    return r.location == NSNotFound && self.length > 0;
}

@end

int get_logs(AMDeviceRef d, NSDictionary *options) {
    
    NSDictionary *dict = nil;
    NSString *appBundle = [options objectForKey:kGetLogsAppBundle];
    NSDictionary *opts = @{ @"ApplicationType" : @"Any",
                            @"ReturnAttributes" : @[@"CFBundleExecutable",
                                                    @"CFBundleIdentifier",
                                                    @"CFBundleDisplayName"]};
    
    NSString *executableName = nil;
    if ([appBundle ds_isAllDigits] && [appBundle integerValue] < 1) {
        dsprintf(stderr, "Must use positive integer value\n");
        return 1;
    }
    AMDeviceLookupApplications(d, opts, &dict);
    
    if (appBundle && ![appBundle isEqualToString:@"__all"] && ![appBundle integerValue]) {
        executableName = [[dict objectForKey:appBundle] objectForKey:@"CFBundleExecutable"];
        if (!executableName) {
            dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor(dc_yellow), [appBundle UTF8String], colorEnd(), dcolor(dc_bold), colorEnd());
            return 1;
        }
    }
    
    NSString *basePath = [[options objectForKey:kGetLogsFilePath] stringByExpandingTildeInPath];
    if (!basePath) {
        basePath = @"/tmp/";
    }
    
    NSURL *baseURL = [NSURL URLWithString:basePath];
    if (!baseURL) {
        dsprintf(stderr, "Couldn't create access path \"%s\", exiting\n", baseURL);
        return 1;
    }
    
    baseURL = [baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"crashes_%@", appBundle]];
    if (!baseURL) {
        dsprintf(stderr, "Couldn't create access path \"%s\", exiting\n", baseURL);
        return 1;
    }
    
    AMDServiceConnectionRef serviceConnection = nil;
    AMDStartService(d, @"com.apple.crashreportmover", &serviceConnection);
    
    void *info = nil;
    if (AMDServiceConnectionReceive(serviceConnection, &info, 5) <= 4) {
        return EACCES;
    }
    if (strcmp("ping", (char *)&info) != 0) {
        dsprintf(stderr, "Didn't get the \"ping\" goahead from com.apple.crashreportmover, got \"%s\" instead, exiting\n", (char *)&info);
        return EACCES;
    }
    AMDServiceConnectionInvalidate(serviceConnection);
    serviceConnection = nil;
    
    // if we got the ping, we're all good, start querying crash logs
    AMDStartService(d, @"com.apple.crashreportcopymobile", &serviceConnection);
    long socket = AMDServiceConnectionGetSocket(serviceConnection);
    //    id context = AMDServiceConnectionGetSecureIOContext(serviceConnection);
    //    if (context) {
    //        // TODO Implement this if it's ever valid
    //        assert(0);
    //    }
    
    AFCConnectionRef connectionRef = AFCConnectionCreate(0, (int)socket, 1, 0, 0);
    if (!connectionRef) {
        dsprintf(stderr, "%sCould not obtain a valid connection. Aborting%s\n", dcolor(dc_yellow), colorEnd());
        return EACCES;
    }
    
    AFCIteratorRef iteratorRef = NULL;
    NSMutableSet *unexploredDirectories = [NSMutableSet set];
    [unexploredDirectories addObject:@"."];
    
    AFCDirectoryOpen(connectionRef, [[unexploredDirectories anyObject] UTF8String], &iteratorRef);
    NSError *err = NULL;
    [[NSFileManager defaultManager] createDirectoryAtPath:[baseURL path] withIntermediateDirectories:YES attributes:nil error:&err];
    
    if (err) {
        dsprintf(stdout, "%s. exiting...\n", [[err localizedDescription] UTF8String]);
        return 1;
    }
    
    err = nil;
    char *remotePath = NULL;
    NSMutableDictionary *outputDict = [NSMutableDictionary dictionary];//used for no appBund
    NSMutableArray *mostRecentSent = [NSMutableArray array];
    size_t maxRecentSize = [appBundle integerValue];
    
    BOOL shouldDelete = [[options objectForKey:kGetLogsDelete] boolValue];
    if (shouldDelete && !global_options.quiet) {
        dsprintf(stdout, "About to delete all logs, please confirm [Y] ");
        if (getchar() != 89) {
            dsprintf(stdout, "\nExiting\n");
            exit(0);
        }
    }
    
    while (AFCDirectoryRead(connectionRef, iteratorRef, &remotePath) == 0 && remotePath) {
        
        AFCFileDescriptorRef descriptorRef = NULL;
        if (AFCFileRefOpen(connectionRef, remotePath, 0x1, &descriptorRef) || !descriptorRef) {
            continue;
        }
        
        AFCIteratorRef iteratorRef = NULL;
        if (AFCFileInfoOpen(connectionRef, remotePath, &iteratorRef) && !iteratorRef) {
            dsprintf(stderr, "Couldn't open \"%s\"", remotePath);
            continue;
        }
        
        
        
        NSDictionary* fileAttributes = (__bridge NSDictionary *)(iteratorRef->fileAttributes);
        
        
        
        
        // is a directory? ignore
        if ([[fileAttributes objectForKey:@"st_ifmt"] isEqualToString:@"S_IFDIR"]) {
            if (strcmp(remotePath, ".") != 0 && strcmp(remotePath, "..") != 0) {
                [unexploredDirectories addObject:[NSString stringWithUTF8String:remotePath]];
            }
            continue;
        }
        
        /* Not ready yet....
        if (shouldDelete) {
            int val = AFCRemovePath(connectionRef, remotePath);
            printf("%d %s\n", val, remotePath);
            continue;
        } */

        // If numbers are used as an argument
        if (maxRecentSize) {
            if ([mostRecentSent count] < maxRecentSize) {
                [mostRecentSent addObject:@{@"mod" : @([fileAttributes[@"st_mtime"] integerValue]), @"path" : [NSString stringWithUTF8String:remotePath] }];
            }
            NSDictionary *candidate = nil;
            for (NSDictionary *dict in mostRecentSent) {
                if ([dict[@"mod"] integerValue] < [fileAttributes[@"st_mtime"] integerValue]) {
                    candidate = dict;
                    break;
                }
            }
            
            if (candidate) {
                [mostRecentSent removeObject:candidate];
                [mostRecentSent addObject:@{@"mod" : @([fileAttributes[@"st_mtime"] integerValue]), @"path" : [NSString stringWithUTF8String:remotePath] }];
            }
            
        }
        
        if (!appBundle) {
            NSString *procName = [[[[NSString stringWithUTF8String:remotePath] lastPathComponent] componentsSeparatedByString:@"-20"] firstObject];
            if (![outputDict objectForKey:procName]) {
                [outputDict setObject:@0 forKey:procName];
            }
            [outputDict setObject:@([[outputDict objectForKey:procName] integerValue] + 1) forKey:procName];
            AFCFileRefClose(connectionRef, descriptorRef);
            continue;
        }
        
        NSURL *finalizedURL = [baseURL URLByAppendingPathComponent:[NSString stringWithUTF8String:remotePath]];
        
        size_t size = [[fileAttributes objectForKey:@"st_size"] longLongValue];
        if (size) {
            size = BUFSIZ;
        }
        
        if (![appBundle integerValue]) {
            
            char *buffer = calloc(size, 1);
            BOOL hasSearchedBundleID = NO;
            NSFileHandle *handle = nil;
            int fd = -1;
            while (AFCFileRefRead(connectionRef, descriptorRef, (void **)buffer, &size) == 0 && size != 0 && size != -1) {
                if (!hasSearchedBundleID) {
                    if(![appBundle isEqualToString:@"__all"] && !strstr(buffer, [appBundle UTF8String])) {
                        break;
                    }
                    hasSearchedBundleID = YES;
                    [[NSFileManager defaultManager] createFileAtPath:[finalizedURL path] contents:nil attributes:nil];
                    handle = [NSFileHandle fileHandleForWritingToURL:finalizedURL error:&err];
                    
                    if (err) {
                        dsprintf(stdout, "%s, exiting...\n", [[err localizedDescription] UTF8String]);
                        return 1;
                    }
                    
                    fd = [handle fileDescriptor];
                    if (fd == -1) {
                        dsprintf(stderr, "%sCan't open \"%s\" to write to, might be an existing file there.\n", [finalizedURL path]);
                        continue;
                    }
                }
                
                write(fd, buffer, size);
            }
            
            [handle closeFile];
            free(buffer);
        }
        AFCFileRefClose(connectionRef, descriptorRef);
    }
    
    if ([appBundle integerValue]) {
        
        [mostRecentSent sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1[@"mod"] longValue] < [obj1[@"mod"] longValue]) {
                return NSOrderedAscending;
            }
            return NSOrderedDescending;
        }];
        
        if ([mostRecentSent count] < [appBundle integerValue]) {
            return 0;
        }
        NSDictionary *dict = [mostRecentSent objectAtIndex:[appBundle integerValue] - 1];
        AFCFileDescriptorRef descriptorRef = NULL;
        if (AFCFileRefOpen(connectionRef, [dict[@"path"] UTF8String], 0x1, &descriptorRef) || !descriptorRef) {
            return 1;
        }
        
        AFCIteratorRef iteratorRef = NULL;
        if (AFCFileInfoOpen(connectionRef,  [dict[@"path"] UTF8String], &iteratorRef) && !iteratorRef) {
            dsprintf(stderr, "Couldn't open \"%s\"", remotePath);
            return 1;
        }
        
        size_t size = 1024;
        char buffer[1024];
        dsprintf(stdout, "****************************************\n%s\n****************************************\n", [dict[@"path"] UTF8String]);
        while (AFCFileRefRead(connectionRef, descriptorRef, (void **)buffer, &size) == 0 && size != 0 && size != -1) {
            dsprintf(stdout, "%s", buffer);
            memset(buffer, '\0', size);
        }
    }
    
    AFCConnectionClose(connectionRef);
    
    if (appBundle && ![appBundle integerValue]) {
        dsprintf(stdout, "Opening \"%s\"...\n", [[baseURL path] UTF8String]);
        if (!global_options.quiet) {
            NSString *systemCMDString = [NSString stringWithFormat:@"open -R %@", [baseURL path]];
            system([systemCMDString UTF8String]);
        }
    }  else {
        for (NSString *key in outputDict) {
            dsprintf(stdout, "%s issues: %d\n", [key UTF8String], [[outputDict objectForKey:key] integerValue]);
        }
    }
    
    return 0;
}
