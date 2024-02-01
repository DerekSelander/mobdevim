//
//  send_files.m
//  mobdevim
//
//  
//  Copyright © 2020 Selander. All rights reserved.
//

#import "send_files.h"
#import <stdio.h>
@import Security;
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


static void _AFCConnectionCallBack(AFCConnectionRef c, AFConnectionCallbackType callbackType, NSObject* reference) {

    

    printf("callback type %d %p, %p\n", callbackType, AFCConnectionGetSecureContext(c), reference);
    printf("");
}

int get_logs(AMDeviceRef d, NSDictionary *options) {
    
//    NSDictionary *dict = nil;
    NSString *requestedFile = [options objectForKey:kGetLogsAppBundle];
    bool should_delete = [[options objectForKey:kGetLogsDelete] boolValue];
    bool get_all_logs = [requestedFile isEqualToString:@"ALL"];
    if (get_all_logs) {
        should_delete = true;
    }
//    NSDictionary *opts = @{ @"ApplicationType" : @"Any",
//                            @"ReturnAttributes" : @[@"CFBundleExecutable",
//                                                    @"CFBundleIdentifier",
//                                                    @"CFBundleDisplayName"]};
//    
//    NSString *executableName = nil;
//    if ([appBundle ds_isAllDigits] && [appBundle integerValue] < 1) {
//        dsprintf(stderr, "Must use positive integer value\n");
//        return 1;
//    }
//    AMDeviceLookupApplications(d, opts, &dict);
//    
//    if (appBundle && ![appBundle isEqualToString:@"__all"] && ![appBundle integerValue]) {
//        executableName = [[dict objectForKey:appBundle] objectForKey:@"CFBundleExecutable"];
//        if (!executableName) {
//            dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor(dc_yellow), [appBundle UTF8String], colorEnd(), dcolor(dc_bold), colorEnd());
//            return 1;
//        }
//    }
    
    NSString *basePath = [[options objectForKey:kGetLogsFilePath] stringByExpandingTildeInPath];
    if (!basePath) {
        basePath = @"/tmp/ios_crashes";
    }
    
    NSURL *baseURL = [NSURL URLWithString:basePath];
    if (!baseURL) {
        dsprintf(stderr, "Couldn't create access path \"%s\", exiting\n", baseURL);
        return 1;
    }
    NSError *error = nil;
    if (get_all_logs) {
        [[NSFileManager defaultManager] createDirectoryAtURL:baseURL  withIntermediateDirectories:YES attributes:nil error:&error];
    }
    AMDServiceConnectionRef serviceConnection = nil;
    AMDStartService_NOUNLOCK(d, @"com.apple.crashreportcopymobile", &serviceConnection);
    long soc = AMDServiceConnectionGetSocket(serviceConnection);
    if (!soc) {
        dsprintf(stderr, "Couldn't get underlying socket\n");
        return EACCES;
    }
    void* secureContext = AMDServiceConnectionGetSecureIOContext(serviceConnection);
    
    
    // we are doing a bunch of short lived requests so don't close on invalidate
    AFCConnectionRef connectionRef = AFCConnectionCreate(NULL, (int)soc, false /* closeOnIvalidate */, 0, 0);
       if (!connectionRef) {
        dsprintf(stderr, "%sCould not obtain a valid connection. Aborting%s\n", dcolor(dc_yellow), colorEnd());
        return EACCES;
    }
    if (secureContext) {
        AFCConnectionSetSecureContext(connectionRef, secureContext);
    }
    
    NSMutableSet <NSString *>* unexploredDirectories = [NSMutableSet set];
    [unexploredDirectories addObject:@"."];
    
    
    while ([unexploredDirectories count]) {
        AFCIteratorRef iteratorRef = NULL;
        NSString *currentDir = [unexploredDirectories anyObject];
        [unexploredDirectories removeObject:currentDir];
        afc_err e = AFCDirectoryOpen(connectionRef, [currentDir UTF8String], &iteratorRef);
        
        if (e) {
            dprint("got error on AFCDirectoryOpen %s (%d)\n", [AFCCopyErrorString(e) UTF8String], e);
            continue;
        }
        
        

        
        char *remotePath = NULL;
//        BOOL shouldDelete = [[options objectForKey:kGetLogsDelete] boolValue];
//        if (shouldDelete && !global_options.quiet) {
//            dsprintf(stdout, "About to delete all logs, please confirm [Y] ");
//            if (getchar() != 89) {
//                dsprintf(stdout, "\nExiting\n");
//                exit(0);
//            }
//        }
#define GOOD_E_NUFF_BUFF 0x12000000
        
       
        
        char* file_buffer = malloc(GOOD_E_NUFF_BUFF);
        while (AFCDirectoryRead(connectionRef, iteratorRef, &remotePath) == AMD_SUCCESS && remotePath) {
            
            // always does current and prev dir so skip it
            if (remotePath && (!strcmp(remotePath, ".") || !strcmp(remotePath, ".."))) {
                continue;
            }
            
            AFCFileDescriptorRef descriptorRef = NULL;
            NSString *resolvedRemoteFile = [NSString stringWithFormat:@"%@/%s", currentDir, remotePath];
            AFCFileInfoRef fileInfo = NULL;
            afc_err e = AFCFileInfoOpen(connectionRef, [resolvedRemoteFile UTF8String], &fileInfo);
            
            bool isDir = false;
            if (!e && fileInfo) {
                char *value = NULL;
                char *key = NULL;
                while (AFCKeyValueRead(fileInfo, &key, &value) == AMD_SUCCESS) {
                    if (!key) {
                        break;
                    }
                    if (strcmp("S_IFDIR", value) == 0 && strcmp("st_ifmt", key) == 0) {
                        isDir = true;
                        if (strcmp(remotePath, "Retired") != 0) {
                            [unexploredDirectories addObject:[NSString stringWithFormat:@"%@/%s", currentDir, remotePath]];
                            NSError *error = NULL;
//                            NSURL *localCurrentDir = [baseURL URLByAppendingPathComponent:[resolvedRemoteFile stringByStandardizingPath]];
                            
                      
                            if (error) {
                                dprint("%s. exiting...\n", [[error localizedDescription] UTF8String]);
                    //            return 1;
                            }
                        }
                        break;
                    }
                }
                AFCKeyValueClose(fileInfo);
            }
            
            if (e || isDir) {
                continue;
            }
            
            if (!requestedFile)  {
                dprint("%s\n", [resolvedRemoteFile UTF8String]);
                continue;
            }
            
            if (!get_all_logs && strcmp([requestedFile UTF8String], [resolvedRemoteFile UTF8String]) != 0) {
                continue;
            }
            
            e = AFCFileRefOpen(connectionRef, [resolvedRemoteFile UTF8String], 0x1, &descriptorRef);
            if (e) {
                continue;
            }
            
            
            size_t len = GOOD_E_NUFF_BUFF;
            NSString *finalPath = [NSString stringWithFormat:@"%@/%s", currentDir, remotePath];
            NSString *resolvedLocalPath = [[baseURL URLByAppendingPathComponent:[resolvedRemoteFile stringByStandardizingPath]] path];
            FILE*p =  NULL;
            
            if (get_all_logs) {
                p = fopen([resolvedLocalPath UTF8String], "w");
                dprint("\"%s\" -> \"%s\"\n", [finalPath UTF8String
                                             ], [resolvedLocalPath UTF8String]);
            }
            while (AFCFileRefRead(connectionRef, descriptorRef, file_buffer, &len) == AMD_SUCCESS && len) {
                if (get_all_logs) {
                    if (p) {
                        fwrite(file_buffer, len, 1,  p);
                    }
                    
                } else {
                    fwrite(file_buffer, len, 1,  stdout);
                }
                len = GOOD_E_NUFF_BUFF;
            }
            if (p) {
                fclose(p);
            }
            
            AFCFileRefClose(connectionRef, descriptorRef);
            if (should_delete) {
                e = AFCRemovePath(connectionRef, [finalPath UTF8String]);
            }
            if (e) {
                dprint("error removing %s\n", [resolvedLocalPath UTF8String]);
            }
            
            
        }
        AFCDirectoryClose(connectionRef, iteratorRef);
        free((void*)file_buffer);
    }
        
    
    AFCConnectionClose(connectionRef);
    AMDServiceConnectionInvalidate(serviceConnection);
    close((int)soc);
    
    return 0;
}
