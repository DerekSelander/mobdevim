//
//  main.m
//  YOYO
//
//  
//  Copyright © 2020 Selander. All rights reserved.
//

@import MachO;
@import Darwin;
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <dlfcn.h>
#import <sys/socket.h>

#import "ExternalDeclarations.h"
#import "helpers.h"
#import "debug_application.h"
#import "console_print.h"
#import "get_provisioning_profiles.h"
#import "list_applications.h"
#import "get_device_info.h"
#import "install_application.h"
#import "yoink.h"
#import "remove_file.h"
#import "send_files.h"
#import "get_logs.h"
#import "delete_application.h"
#import "instruments.h"
#import "sim_location.h"
#import "springboardservices.h"
#import "open_program.h"
#import "notifications.h"
#import "misc/InstrumentsPlugin.h"
#import "install_ddi.h"
#import "process.h"
#import "wifie_connect.h"
#import "backup_device.h"
#import "process/process.h"

static NSOperation *timeoutOperation = nil; // kill proc if nothing happens in 30 sec
static NSString *optionalArgument = nil;
static NSString *requiredArgument = nil;
static int return_error = 0;
struct am_device_service_connection *GDeviceConnection = NULL;
struct am_device_notification *notify_handle = NULL;

static int (*actionFunc)(AMDeviceRef, id) = nil; // the callback func for whatever action
static BOOL disableTimeout = YES;
static NSMutableDictionary *getopt_options;


static amd_err connect_and_handle_device(AMDeviceRef device);

__unused static void subscription_connect_callback(AMDeviceCallBackDevice *callback, void* context) {
    AMDeviceRef d = callback->device;
    
    // Cancel the warning timer that it can't find a device
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [timeoutOperation cancel];
        timeoutOperation = nil;
    });
    
    // AMDeviceNotificationUnsubscribe sends another notification with
    // DeviceConnectionStatusStopped, we'll ignore this and return;
    if (callback->status == DeviceConnectionStatusStopped) {
        return;
    }
    
    if (callback->status != DeviceConnectionStatusConnect) {
        dprint("(status: %d for %s)\n", callback->status, AMDeviceGetName(callback->device));
        return;
    }
    
    if (connect_and_handle_device(d) != AMD_SUCCESS) {
        derror("Error connecting to device\n");
        goto end;
    }
    

    
//    if (actionFunc != &debug_application) {
//        CFRunLoopStop(CFRunLoopGetMain());
//        return;
//    }
    
end:
    ;
//    AMDeviceNotificationUnsubscribe(callback->notification);
//    AMDeviceStopSession(callback->device);
    
}

static amd_err connect_and_handle_device(AMDeviceRef device) {
    
    // Connect
    mach_error_t status = 0;
    HANDLE_ERR_RET(AMDeviceConnect(device));
    
    // Is Paired
    if (!AMDeviceIsPaired(device)) {
        NSDictionary *outDict = nil;
        HANDLE_ERR_RET(AMDevicePairWithCallback(device, ^(AMDeviceRef device, uint64_t options, uint64_t dunno, AMDevicePairAnotherCallback anothercallback) {
            
            printf("test\n");
            
        }, nil, &outDict));
        derror("device needs to be paired\n");
        return 1;
    }
    
    NSString *deviceUDID = AMDeviceCopyValue(device, nil, @"DeviceName", 0);
    // Validate Pairing
    if (AMDeviceValidatePairing(device)) {
        derror("The device \"%s\" might not have been paired yet, Trust this computer on the device\n", [deviceUDID UTF8String]);
        exit(1);
    }
    
    // Start Session
    if ((status = AMDeviceStartSession(device))) {
        if (status != AMDSessionActiveError ) { // we're already active, ignore
            derror("Error: %s %d\n", AMDErrorString(status), status);
            exit(1);
        }
    }
        
    NSString *deviceName = AMDeviceCopyValue(device, nil, @"DeviceName", 0);
    
    if (deviceName) {
        char *interface_type = NULL;
        String4Interface( AMDeviceGetInterfaceType(device), &interface_type);
        dprint("%sConnected to: \"%s\" (%s)%s %s%s%s\n", dcolor(dc_cyan), [deviceName UTF8String], [AMDeviceGetName(device) UTF8String], colorEnd(), dcolor(dc_yellow), interface_type, colorEnd() );
    }
    
    if (actionFunc) {
        return_error = actionFunc(device, getopt_options);
    }
    
    return AMD_SUCCESS;
}


//*****************************************************************************/
#pragma mark - MAIN

// If one USB, choose that, otherwise
static BOOL checkIfMultipleDevicesAndQueryIfNeeded(DeviceSelection *selection) {
    NSArray * devices = AMDCreateDeviceList();
    for (int i = 0; i < devices.count; i++) {
        AMDeviceRef device = (__bridge AMDeviceRef)([devices objectAtIndex:i]);
        AMDeviceConnect(device);
        NSString *deviceUDID = AMDeviceGetName(device);
        InterfaceType type = AMDeviceGetInterfaceType(device);
//        if (type == InterfaceTypeUSB) {
//
//        }
        
        
//        if (selection) {
//            selection->type = AMDeviceGetInterfaceType(device);
//        }
        // If we have a selection, match UUID first, followed by interface type
        if (selection) {
            
            if ([deviceUDID containsString:global_options.expectedPartialUDID]) {
                // udid && type
                if (selection->type == type) {
                    selection->device = device;
                    return YES;
                } else {    // udid only
                    selection->device = device;
                    return YES;
                }
                
            } else {
                // type only
                if (selection->type == type) {
                    selection->device = device;
                    return YES;
                }
            }
            continue;
        }
        // Don't print out the devices if a UDID was specified

        char *typeStr  = InterfaceTypeString(AMDeviceGetInterfaceType(device));
        printf("[%2d] %s (\"%s\") %s\n", i + 1, [AMDeviceGetName(device) UTF8String], [deviceUDID UTF8String], typeStr);
        AMDeviceDisconnect(device);
        
    }
    return YES;
    

    //    }
}


__attribute__((destructor))
void exit_handler(void) {
    AMDeviceRef device = global_options.deviceSelection.device;
    
    if (device && AMDeviceIsPaired(device)) {
        AMDeviceDisconnect(device);
        AMDeviceStopSession(device);
    }
    
//    if (GDeviceConnection) {
//        AMDeviceNotificationUnsubscribe(GDeviceConnection);
//        GDeviceConnection = NULL;
//    }
}

__attribute__((constructor))
static void init(void) {
    atexit(exit_handler);
}

#define OPTIONAL_ARGUMENT_IS_PRESENT \
    ((optarg == NULL && optind < argc && argv[optind][0] != '-') \
     ? (bool) (optarg = (char*)argv[optind++]) \
     : (optarg != NULL))

//*****************************************************************************/

int main(int argc, const char * argv[]) {
    
    int option = -1;
    char *addr;
    
    if (argc == 1) {
        print_manpage();
        exit(EXIT_SUCCESS);
    }
    
    getopt_options = [NSMutableDictionary new];
    const struct option options[] = {
//        {"no-arg", no_argument, 0, 'n'},
        {"list", optional_argument, 0,  0},
        {"console", optional_argument, 0,  0},
//        {"req-arg", required_argument, 0, 'r'},
        {NULL, 0, 0, 0}
    };
    
    while ((option = getopt_long(argc, (char **)argv, "QbNn:o:w::WA:k:UV:D:d::Rr:fF::qS::s:zd:u:hv::g::l::I:i:Cc::pP::y::L:M", options, NULL)) != -1) {
        switch (option) {
            case 'R': // Use color
                setenv("DSCOLOR", "1", 1);
                break;
            case 'Q': // quiet
                global_options.quiet = YES;
                break;
            case 'A': // Arguments, open_program
                global_options.programArguments = [NSString stringWithUTF8String:optarg];
                break;
            case 'o': // open application
                assert_opt_arg();
                actionFunc = &open_program;
                if (optarg) {
                    global_options.programBundleID = [NSString stringWithUTF8String:optarg];
                }
                break;
            case 'w': {
                actionFunc = &wifi_connect;
                disableTimeout = NO;
                if (OPTIONAL_ARGUMENT_IS_PRESENT) {
                    NSString *str = [NSString stringWithUTF8String:optarg];
                    if ([str containsString:@"uuid"]) {
                        dsprintf(stdout, "macOS host UUID: %s\n", GetHostUUID().UTF8String);
                        exit(0);
                    } else if (strcmp(optarg, "off") == 0) {
                        [getopt_options setObject:@YES forKey:kWifiConnectUUIDDisable];
                    } else {
                        [getopt_options setObject:str forKey:kWifiConnectUUID];
                    }
                }
                break;
            }        
            case 'W': // Prefer Use WIFI
                global_options.deviceSelection.type = InterfaceTypeWIFI;
                break;
            case 'U': // Prefer Use USB
                global_options.deviceSelection.type = InterfaceTypeUSB;
                break;
            case 'k': {
                NSString *str = [NSString stringWithUTF8String:optarg];
                actionFunc = kill_process;
                
                [getopt_options setObject:str forKey:kProcessKillPID];
                break;
            }
            case 'V':
                
                // fallthrough
            case 'v': { // version if by itself, environment variables if other args
                if (argc == 2 && strlen(argv[1]) == 2) {
                    printf("%s v%s\n", program_name, version_string);
                    exit(EXIT_SUCCESS);
                }
                
                assert_opt_arg();
                NSMutableArray *arr = nil;
                if (getopt_options[kProcessEnvVars]) {
                    arr = getopt_options[kProcessEnvVars];
                } else {
                    arr = [NSMutableArray array];
                }
                if (OPTIONAL_ARGUMENT_IS_PRESENT) {
                    [arr addObject:[NSString stringWithUTF8String:optarg]];
                    [getopt_options setObject:arr forKey:kProcessEnvVars];
                }
                break;
            }
            case 'b':
                actionFunc = &backup_device;
                
                break;
            case 'r':
                assert_opt_arg();
                actionFunc = &remove_file;
                if (OPTIONAL_ARGUMENT_IS_PRESENT) {
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kRemoveFileBundleID];
                }
                
                if (argc > optind) {
                    [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kRemoveFileRemotePath];
                }
                break;
            case 'n': // push notifications
                global_options.programBundleID = [NSString stringWithUTF8String:optarg];
                actionFunc = notification_proxy;
                if (argc > optind) {
                    global_options.pushNotificationPayloadPath = [NSString stringWithUTF8String:argv[optind]];
                }
                break;
            case 'p':
                actionFunc = &running_processes;
                break;

            case 'g':
                assert_opt_arg();
                actionFunc = &get_logs;
                
                if (OPTIONAL_ARGUMENT_IS_PRESENT) {
                    if (strcmp("__delete", optarg) == 0) {
                        [getopt_options setObject:@YES forKey:kGetLogsDelete];
                    } else {
                        [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kGetLogsAppBundle];
                    }
                }
                if (argc > optind) {
                    [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kGetLogsFilePath];
                }
                break;
            case 'f':
                actionFunc = &get_device_info;
                break;
            case 'F':
                disableTimeout = NO;
                global_options.choose_specific_device = YES;
                if (OPTIONAL_ARGUMENT_IS_PRESENT) {
                    global_options.expectedPartialUDID = [NSString stringWithUTF8String:optarg];
                    checkIfMultipleDevicesAndQueryIfNeeded(&global_options.deviceSelection);
                } else {
                    checkIfMultipleDevicesAndQueryIfNeeded(NULL);
                    exit(0);
                }
                break;
            case 'l':
                actionFunc = &list_applications;
                if (OPTIONAL_ARGUMENT_IS_PRESENT) {
                    addr = strdup(optarg);
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kListApplicationsName];
                    if (argc > optind) {
                        [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kListApplicationsKey];
                    }
                }
                break;
            case 'u':
                assert_opt_arg();
                actionFunc = &delete_application;
                if (OPTIONAL_ARGUMENT_IS_PRESENT) {
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kDeleteApplicationIdentifier];
                }
                break;
            case 's':
                assert_opt_arg();
                if(argc != 4) {
                    dsprintf(stderr, "Err: mobdevim -s BundleIdentifier /path/to/directories\n");
                    exit(1);
                }
                actionFunc = &send_files;
                [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kSendFilePath];
                [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kSendAppBundle];
                break;
            case 'S':
                if (OPTIONAL_ARGUMENT_IS_PRESENT) {
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kSBCommand];
                }
                actionFunc = &springboard_services;
                break;
            case 'i':
                assert_opt_arg();
                disableTimeout = NO;
                actionFunc = &install_application;
                addr = strdup(optarg);
                [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kInstallApplicationPath];
                requiredArgument = [NSString stringWithUTF8String:addr];
                break;
            case 'I': {
                assert_opt_arg();
                global_options.ddiSignatureInstallPath = [NSString stringWithUTF8String:optarg];
                global_options.ddiInstallPath = [NSString stringWithUTF8String:argv[optind ]];
                actionFunc = &install_ddi;
                break;
            }
            case 'M':
                actionFunc = &uninstall_ddi;
                break;
            case 'L':
                assert_opt_arg();
                disableTimeout = NO;
                actionFunc = &sim_location;
                [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kSimLocationLat];
                [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kSimLocationLon];
                optind++;
                break;
            case 'h':
                print_manpage();
                exit(EXIT_SUCCESS);
                break;
            case 'D':
                [getopt_options setObject:@YES forKey:kDebugQuickLaunch];
                // drops through to debug
            case 'd':
                assert_opt_arg();
                disableTimeout = NO;
                [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kDebugApplicationIdentifier];
                actionFunc = debug_application;
                break;
            case 'c': {
                
                assert_opt_arg();
                disableTimeout = NO;
                actionFunc = console_print;
                if (OPTIONAL_ARGUMENT_IS_PRESENT) {
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kConsoleProcessName];
                }
                break;
            }
            case 'C':
                actionFunc = &get_provisioning_profiles;
                [getopt_options setObject:@YES forKey:kProvisioningProfilesCopyDeveloperCertificates];
                break;
            case 'P':
                assert_opt_arg();
                actionFunc = &get_provisioning_profiles;
                if (optarg) {
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kProvisioningProfilesFilteredByDevice];
                }
                break;
            case 'y':
                assert_opt_arg();
                actionFunc = &yoink_app;
                if (optarg) {
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kYoinkBundleIDContents];
                }
                break;
            case ':': // cases for optional non argument
                switch (optopt) {
                    case 'g':
                        actionFunc = &get_logs;
                        break;
                    case 'S':
                        actionFunc = &springboard_services;
                        break;
                    case 'n':
                        actionFunc = &notification_proxy;
                        break;
                    case 'P':
                        actionFunc = &get_provisioning_profiles;
                        break;
                    case 'l':
                        actionFunc = &list_applications;
                        break;
                    case 'd':
                        disableTimeout = NO;
                        actionFunc = &debug_application;
                        break;
                    case 'w':
                        disableTimeout = NO;
                        actionFunc = &wifi_connect;
                        break;
                    case 'y':
                        dsprintf(stderr, "%sList a BundleIdentifier to yoink it's contents%s\n\n", dcolor(dc_yellow), colorEnd());
                        actionFunc = &list_applications;
                        break;
                    case 'L':
                        assert_opt_arg();
                        disableTimeout = NO;
                        actionFunc = &sim_location;
                        break;
                    case 'F':
                        disableTimeout = NO;
                        checkIfMultipleDevicesAndQueryIfNeeded(NULL);
                        break;
                    case 'v': {
                        if (argc == 2 && strlen(argv[1]) == 2) {
                            printf("%s v%s\n", program_name, version_string);
                            exit(EXIT_SUCCESS);
                        }
                        
                        assert_opt_arg();
                        NSMutableArray *arr = nil;
                        if (getopt_options[kProcessEnvVars]) {
                            arr = getopt_options[kProcessEnvVars];
                        } else {
                            arr = [NSMutableArray array];
                        }
                        break;
                    }
                    case '?':
                        break;
                    default:
                        dsprintf(stderr, "option -%c is missing a required argument\n", optopt);
                        return EXIT_FAILURE;
                }
                break;
            default:
                dsprintf(stderr, "%s\n", usage);
                exit(EXIT_FAILURE);
                break;
        }
        
        
    MEH_IM_DONE:
        
        
        
//        if (!isatty(fileno(stdout))) {
//            unsetenv("DSCOLOR");
//        }
        
        ;
        //        checkIfMultipleDevicesAndQueryIfNeeded(&deviceSelection);
        
//        @{@"MatchUDID" :@"}
        
        
        
        
    }
//    return return_error;
    
    // If we have a specific device, look for it, else monitor with NotificationSubscribe
    if (global_options.choose_specific_device) {
        if (global_options.deviceSelection.device) {
            connect_and_handle_device(global_options.deviceSelection.device);
        } else {
            char *type_str = NULL;
            String4Interface(global_options.deviceSelection.type, &type_str);
            dsprintf(stderr, "Couldn't find device query: (%s)-%s\n", global_options.expectedPartialUDID.UTF8String, type_str);
            exit(1);
        }
    } else {
        
        NSArray <AMDeviceObjc>*devices = AMDCreateDeviceList();
        if (devices.count == 0) {
            derror("Cannot find any connected devices!\n");
            exit(5);
        }
        
        AMDeviceRef preferred = nil;
        for (AMDeviceObjc d in devices) {
            if (AMDeviceGetInterfaceType((__bridge AMDeviceRef)(d))== InterfaceTypeUSB) {
                preferred = (__bridge AMDeviceRef)(d);
                break;
            }
        }
        if (preferred == nil) {
            preferred = (__bridge AMDeviceRef)(devices[0]);
        }
        
        amd_err e;
        if ((e = connect_and_handle_device(preferred) != AMD_SUCCESS)) {
            HANDLE_ERR(e);
        }
        
//        AMDeviceNotificationSubscribeWithOptions(subscription_connect_callback, 0, global_options.deviceSelection.type, NULL /* arg passed into callback */, &GDeviceConnection, nil);
//
//        /* @{@"NotificationOptionSearchForPairedDevices" : @(UseUSBToConnect), @"NotificationOptionSearchForWiFiPairableDevices" : @(UseWifiToConnect) }*/
//
//        timeoutOperation = [NSBlockOperation blockOperationWithBlock:^{
//            dsprintf(stderr, "Your device might not be connected. You've got about 25 seconds to connect your device before the timeout gets fired or you can start fresh with a ctrl-c. Choose wisely... dun dun\n");
//        }];
//
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [[NSOperationQueue mainQueue] addOperation:timeoutOperation];
//        });
//
//        if (disableTimeout) {
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//
//                if (GDeviceConnection) {
//                    AMDeviceNotificationUnsubscribe(GDeviceConnection);
//                    GDeviceConnection = NULL;
////                    AMDeviceDisconnect(GDeviceConnection);
//                }
//                derror("Script timed out, exiting now.\n");
//                exit(EXIT_FAILURE);
//
//            });
//        }
//        // we expect to get an exit call before this event happens
////        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 20, false);
//        CFRunLoopRun();
        
    }
}


/*
 /System/Library/PrivateFrameworks/CommerceKit.framework/Versions/A/CommerceKit
 po [[CKAccountStore sharedAccountStore] primaryAccount]
 <ISStoreAccount: 0x6080000d8f70>: dereks@somoioiu.com (127741183) isSignedIn=1 managedStudent=0
 */
