//
//  DebugServer.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "debug_application.h"
#import "helpers.h"
#import <dlfcn.h>
@import Cocoa;
@import Darwin;
@import AppKit;
@import MachO;

#define DUMMY_TARGET_BLOB @"/tmp/SBTargetDummy/dsblob"
#define LLDB_SCRIPT_PATH @"/tmp/mobdevim_setupscript"

NSString * const kDebugApplicationIdentifier = @"com.selander.debug.bundleidentifier";
NSString * const kDebugQuickLaunch = @"com.selander.debug.quicklaunch";
NSString * const kProcessEnvVars = @"com.selander.debug.envvar";;

NSString* extractDummyTarget(NSString *name) {
    NSFileManager* manager = [NSFileManager defaultManager];
    NSString *dummyPath = [[DUMMY_TARGET_BLOB stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
    if ([manager fileExistsAtPath:dummyPath]) {
        return dummyPath;
    }
    
    NSError *err = nil;
    NSString* targetFolder = @"/tmp/SBTargetDummy/";
    BOOL isDirectory = NO;
    if ([manager fileExistsAtPath:targetFolder isDirectory:&isDirectory]) {
        if (!isDirectory) {
            ErrorMessageThenDie("%s should be a directory", [targetFolder UTF8String]);
        }
    } else {
        [manager createDirectoryAtPath:targetFolder withIntermediateDirectories:YES
                            attributes:nil error:&err];
        if (err) {
            ErrorMessageThenDie("%s\n", [[err localizedDescription] UTF8String]);
        }
    }
    
    
    if (![manager fileExistsAtPath:DUMMY_TARGET_BLOB isDirectory:&isDirectory] && isDirectory) {
        unsigned long size = 0;
        uint8_t *dataStart = getsectiondata(&_mh_execute_header, "__TEXT", "__SBDummyTarget", &size);
        if (!dataStart) {
            ErrorMessageThenDie("Can't find embedded DummyTarget, exiting\n");
        }
        NSData *data = [NSData dataWithBytes:dataStart length:size];
        [data writeToFile:DUMMY_TARGET_BLOB atomically:YES];
    }
    NSArray *arguments = @[@"-q", DUMMY_TARGET_BLOB, @"-d", targetFolder];
    
    NSTask *unzipTask = [[NSTask alloc] init];
    [unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [unzipTask setCurrentDirectoryPath:targetFolder];
    [unzipTask setArguments:arguments];
    [unzipTask launch];
    dsprintf(stdout, "Extracting dummy target...  ");
    [unzipTask waitUntilExit]; //remove this to start the task concurrently
    err = nil;
    [manager moveItemAtPath:@"/tmp/SBTargetDummy/WOMP.app" toPath:dummyPath error:&err];
    if (err) {
        ErrorMessageThenDie("%s\n", [[err localizedDescription] UTF8String]);
    }
    dsprintf(stdout, "Extracted!\n");
    
    return dummyPath;
}

void generateSetupScript(const char *localExecutablePath, const char * remoteExecutablePath, const char *launchCommand, int port) {
    NSString *setupScript =
@"platform select remote-ios\n\
target create \"%s\"\n\
script lldb.target.module[0].SetPlatformFileSpec(lldb.SBFileSpec(\"%s\"))\n\
process connect connect://127.0.0.1:%d\n";
    
    if (launchCommand) {
setupScript = [setupScript stringByAppendingFormat:@"\
script lldb.debugger.SetAsync(True)\n\
%s\n\
process detach", launchCommand];
    }
    NSError *error = nil;
    if (!localExecutablePath) {
        dsprintf(stderr, "Attaching by bundleIdentifier not implemented yet, please use bundle path\n");
        exit(1);
    }
    NSString *script = [NSString stringWithFormat:setupScript, localExecutablePath, remoteExecutablePath, port];
    
    [script writeToFile:LLDB_SCRIPT_PATH atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        ErrorMessageThenDie("Couldn't write script to file: %s", [[error localizedDescription] UTF8String]);
    }
}

static NSString *appPath;

/********************************************************************************
 Source start https://github.com/phonegap/ios-deploy GPL v3 license
********************************************************************************/
static int lldbfd = 0;
static CFSocketRef server_socket;
static CFSocketRef lldb_socket;
static CFSocketRef fdvendor;
static int port = 0;

void lldb_callback(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dsprintf(stdout, "Connected!\n");
    });
    
    NSData *objcData = (__bridge NSData*)data;
    NSString *str = [[NSString alloc] initWithData:objcData encoding:NSUTF8StringEncoding];
    dsdebug("%s: %s\n", __FUNCTION__, [str UTF8String]);
    if (CFDataGetLength (data) == 0) {
        // close the socket on which we've got end-of-file, the lldb_socket.
        CFSocketInvalidate(s);
        CFRelease(s);
        dsprintf(stdout, "Connection terminated\n");
        CFRunLoopStop(CFRunLoopGetMain());
        return;
    }
    write(lldbfd, CFDataGetBytePtr (data), CFDataGetLength (data));
}

int kill_ptree(pid_t root, int signum);
void
server_callback (CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info)
{
    ssize_t res;
    NSData *objcData = (__bridge NSData*)data;
    NSString *str = [[NSString alloc] initWithData:objcData encoding:NSUTF8StringEncoding];
    dsdebug("%s: %s\n", __FUNCTION__, [str UTF8String]);
    if (CFDataGetLength (data) == 0) {
        // close the socket on which we've got end-of-file, the server_socket.
        CFSocketInvalidate(s);
        CFRelease(s);

        return;
    }
    res = write (CFSocketGetNative (lldb_socket), CFDataGetBytePtr (data), CFDataGetLength (data));
}

static const char* generateLaunchString(NSDictionary *options) {
    if (!options[kDebugQuickLaunch]) {
        return NULL;;
    }
    NSArray *envVars = options[kProcessEnvVars];
    
    NSMutableString *str = [NSMutableString stringWithString:@"process launch -X true "];
    for (NSString *env in envVars) {
        [str appendFormat:@" -v %@", env];
    }
    [str appendString:@" -- "];
    return str.UTF8String;
}

void fdvendor_callback(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info) {
    CFSocketNativeHandle socket = (CFSocketNativeHandle)(*((CFSocketNativeHandle *)data));

    dsprintf(stdout, "Connecting to debugserver...");
    assert (callbackType == kCFSocketAcceptCallBack);

    lldb_socket  = CFSocketCreateWithNative(NULL, socket, kCFSocketDataCallBack, &lldb_callback, NULL);
    int flag = 1;
    int res = setsockopt(socket, IPPROTO_TCP, TCP_NODELAY, (char *) &flag, sizeof(flag));
    assert(res == 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), CFSocketCreateRunLoopSource(NULL, lldb_socket, 0), kCFRunLoopCommonModes);
    
    CFSocketInvalidate(s);
    CFRelease(s);
}

/********************************************************************************
 Source end https://github.com/phonegap/ios-deploy GPL v3 license
********************************************************************************/

static pid_t childPID = 0;
void Kill_The_Spare__AVADA_KEDAVRA(void) {
    if (childPID) {
        dsdebug("Killing the child PID %d\n", childPID);
        kill(childPID, SIGKILL);
    }
}

int debug_application(AMDeviceRef d, NSDictionary* options) {

    NSDictionary *dict = nil;
    AMDeviceLookupApplications(d, @{@"ReturnAttributes": @[@"ProfileValidated", @"CFBundleIdentifier", @"Path"], @"ShowLaunchProhibitedApps" : @YES}, &dict);
    NSString *applicationIdentifier =  options[kDebugApplicationIdentifier];
    
    BOOL isDir = NO;
    NSString * localApplicationPath = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:applicationIdentifier
                                             isDirectory:&isDir] && isDir) {
        NSBundle *bundle = [NSBundle bundleWithPath:applicationIdentifier];
        NSString *correctedBundleIdentifier = [bundle bundleIdentifier];
        if (correctedBundleIdentifier) {
            localApplicationPath = applicationIdentifier;
            applicationIdentifier = correctedBundleIdentifier;
        }
        
    }
    
    if (!applicationIdentifier) {
        ErrorMessageThenDie("Invalid application identifier\n");
    }
    NSDictionary *appDict = dict[applicationIdentifier];
    if (!appDict) {
        ErrorMessageThenDie("Invalid application identifier \"%s\", use mobdevim -l to see application identifiers\n", [applicationIdentifier UTF8String]);
    }
    appPath = appDict[@"Path"];
    if (!appPath) {
        ErrorMessageThenDie("Couldn't find app path for \"%s\"\n", [applicationIdentifier UTF8String]);
    }
    
    // At this point, we have a valid path for the app, let's continue
    AMDServiceConnectionRef connection = NULL;
    NSDictionary *params = @{@"CloseOnInvalidate" : @YES, @"InvalidateOnDetach" : @YES};
    AMDeviceSecureStartService(d, @"com.apple.debugserver", params, &connection);
    if (!connection) {
        ErrorMessageThenDie("Unable to create a debugserver connection\n");
    }
    lldbfd = (int)AMDServiceConnectionGetSocket(connection);
    if (lldbfd == -1) {
        ErrorMessageThenDie("Invalid socket\n");
    }
    
/********************************************************************************
 Source end https://github.com/phonegap/ios-deploy GPL v3 license
 ********************************************************************************/
    
    server_socket = CFSocketCreateWithNative (NULL, lldbfd, kCFSocketDataCallBack, &server_callback, NULL);
    CFRunLoopAddSource(CFRunLoopGetMain(), CFSocketCreateRunLoopSource(NULL, server_socket, 0), kCFRunLoopCommonModes);
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    
    fdvendor = CFSocketCreate(NULL, PF_INET, 0, 0, kCFSocketAcceptCallBack, &fdvendor_callback, NULL);
    
    if (port) {
        int yes = 1;
        setsockopt(CFSocketGetNative(fdvendor), SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
    }
    
    CFDataRef address_data = CFDataCreate(NULL, (const UInt8 *)&addr, sizeof(addr));
    
    CFSocketSetAddress(fdvendor, address_data);
    CFRelease(address_data);
    socklen_t addrlen = sizeof(addr);
    int res = getsockname(CFSocketGetNative(fdvendor),(struct sockaddr *)&addr,&addrlen);
    assert(res == 0);
    port = ntohs(addr.sin_port);
    
    if (port == 0) {
      return 0;
//        ErrorMessageThenDie("Unable to bind port, exiting\n");
    }
    CFRunLoopSourceRef runLoopSourceRef = CFSocketCreateRunLoopSource(NULL, fdvendor, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSourceRef, kCFRunLoopCommonModes);
    
/********************************************************************************
 Source end https://github.com/phonegap/ios-deploy GPL v3 license
********************************************************************************/
    
    // The connection has yet to be established, but everything is good, generate the setup script
    if (!localApplicationPath) {
        localApplicationPath = extractDummyTarget([appPath lastPathComponent]);
    }
    

        
    generateSetupScript([localApplicationPath UTF8String], [appPath UTF8String], generateLaunchString(options), port);
    
    
    pid_t pid;
    if ((pid = fork()) == 0) {
        childPID = getpid();
        char *const params[] = {"lldb", "-s", "/tmp/mobdevim_setupscript", NULL};
        execv("/usr/bin/lldb", params);
    } else if ((childPID = pid) > 0) {
        atexit(Kill_The_Spare__AVADA_KEDAVRA);
        signal(SIGINT, Kill_The_Spare__AVADA_KEDAVRA);
    } else {
        ErrorMessageThenDie("Couldn't fork(), exiting...\n");
    }

    return 0;
}

