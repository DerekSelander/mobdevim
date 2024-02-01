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
    NSString *appBundle = [options objectForKey:kGetLogsAppBundle];
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
        basePath = @"/tmp/";
    }
    
    NSURL *baseURL = [NSURL URLWithString:basePath];
    if (!baseURL) {
        dsprintf(stderr, "Couldn't create access path \"%s\", exiting\n", baseURL);
        return 1;
    }
    
    baseURL = [baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"crashes_%@", AMDeviceGetName(d)]];
//    if (!baseURL) {
//        dsprintf(stderr, "Couldn't create access path \"%s\", exiting\n", baseURL);
//        return 1;
//    }
    
    AMDServiceConnectionRef serviceConnection = nil;
    AMDStartService_NOUNLOCK(d, @"com.apple.crashreportcopymobile", &serviceConnection);
    
    // if we got the ping, we're all good, start querying crash logs
//    AMDStartService(d, @"com.apple.crashreportmover", &serviceConnection);
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
        
        
        NSError *error = NULL;
        NSURL *localCurrentDir = [baseURL URLByAppendingPathComponent:[currentDir stringByStandardizingPath]];
        
        [[NSFileManager defaultManager] createDirectoryAtURL:localCurrentDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            dprint("%s. exiting...\n", [[error localizedDescription] UTF8String]);
//            return 1;
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
#define GOOD_E_NUFF_BUFF 0x4000000
        
        
        char* file_buffer = malloc(GOOD_E_NUFF_BUFF);
        while (AFCDirectoryRead(connectionRef, iteratorRef, &remotePath) == AMD_SUCCESS && remotePath) {
            
            if (remotePath && (!strcmp(remotePath, ".") || !strcmp(remotePath, ".."))) {
                continue;
            }
            
            
            
            AFCFileDescriptorRef descriptorRef = NULL;
            NSString *resolvedRemoteFile = [NSString stringWithFormat:@"%@/%s", currentDir, remotePath];
            dprint("%s", [resolvedRemoteFile UTF8String]);
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
                        dprint("/\n");
                        [unexploredDirectories addObject:[NSString stringWithFormat:@"%@/%s", currentDir, remotePath]];
                        break;
                    }
                }
                AFCKeyValueClose(fileInfo);
            }
            
            if (e || isDir) {
                continue;
            }
            
            e = AFCFileRefOpen(connectionRef, [resolvedRemoteFile UTF8String], 0x1, &descriptorRef);
            if (e) {
                continue;
            }
            
            
            size_t len = GOOD_E_NUFF_BUFF;
            NSString *finalPath = [NSString stringWithFormat:@"%@/%s", currentDir, remotePath];
            FILE*p =  fopen([finalPath UTF8String], "w");
            while (AFCFileRefRead(connectionRef, descriptorRef, file_buffer, &len) == AMD_SUCCESS && len) {
                fwrite(file_buffer, len, 1,  p);
            }
            fclose(p);
            
            AFCFileRefClose(connectionRef, descriptorRef);
            
            
            
        }
        AFCDirectoryClose(connectionRef, iteratorRef);
        free((void*)file_buffer);
    }
        
    
    AFCConnectionClose(connectionRef);
    AMDServiceConnectionInvalidate(serviceConnection);
    close((int)soc);
    
    return 0;
}
