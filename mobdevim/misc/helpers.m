//
//  
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "helpers.h"


//*****************************************************************************/
#pragma mark - Externals
//*****************************************************************************/

const char *version_string = "0.0.1";
const char *program_name = "mobdevim";

const char *usage = "mobdevim [-v] [-l|-l appIdent][-i path_to_app_dir] [-p|-p UUID_PROVSIONPROFILE] [-c] [-C] [-s bundleIdent path] [-f]";




const char* dcolor(dc_colors color) {
  static BOOL useColor = NO;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (getenv("DSCOLOR")) {
      useColor = YES;
    }
  });
  if (!useColor) {
    return "";
  }
    switch (color) {
        case dc_cyan:
            return "\e[36m";
        case dc_yellow:
            return "\e[33m";
        case dc_magenta:
            return "\e[95m";
        case dc_red:
            return "\e[91m";
        case dc_blue:
            return "\e[34m";
        case dc_gray:
            return "\e[90m";
        case dc_bold:
            return "\e[1m";
            break;
        default:
            assert(0);
            break;
    }
    return "";
}

char *colorEnd(void) {
  static BOOL useColor = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (getenv("DSCOLOR")) {
      useColor = YES;
    }
  });
  if (useColor) {
    return "\e[0m";
  }
  
  return "";
}

void dprint(const char *format, ...) {
    va_list args;
    va_start( args, format );
    vfprintf(stdout, format, args );
    va_end( args );
}

void dsprintf(FILE * f, const char *format, ...) {
  if (global_options.quiet) {
    return;
  }
  va_list args;
  va_start( args, format );
  vfprintf(f, format, args );
  va_end( args );
}

void dsdebug(const char *format, ...) {
    if (global_options.quiet) { return; }
    static dispatch_once_t onceToken;
    static BOOL debugFlag = 0;
    dispatch_once(&onceToken, ^{
        if (getenv("DSDEBUG")) {
            debugFlag = YES;
        } else {
            debugFlag = NO;
        }
    });
    
    if (debugFlag) {
        va_list args;
        va_start( args, format);
        vfprintf(stdout, format, args );
        va_end( args );
    }
    
}

void String4Interface(InterfaceType interface, char **out_str) {
    InterfaceType type = interface;//global_options.deviceSelection.type;
    
    switch (type) {
        case InterfaceTypeYOLODontCare:
            *out_str = "Any";
            break;
        case InterfaceTypeUSB:
            *out_str = "USB";
            break;
        case InterfaceTypeWIFI:
            *out_str = "WIFI";
            break;
        default:
            *out_str = NULL;
            break;
    }

}

void ErrorMessageThenDie(const char *message, ...) {
    if (!global_options.quiet) {
        va_list args;
        va_start(args, message);
        vfprintf(stderr, message, args);
        va_end( args );
    }
    exit(1);
}


void print_manpage(void) {
    dprint("\nName\n  %s -- (mobiledevice-improved) Interact with an iOS device (compiled %s, %s)\n\n"
    "  The mobdevim utlity interacts with your plugged in iOS device over USB using Apple's\n"
    "  private framework, MobileDevice.\n\n"
    "  The options are as follows:\n"
           , program_name, __DATE__, __TIME__);
    
    
    dprint("\t-F\t# List all available connections, or connect to a specific device\n\n");
    dprint("\t\tmobdevim -F       # List all known devices\n");
    dprint("\t\tmobdevim -F 00234 # Connect to first device that has a UDID containing 00234\n");
    dprint("\t\tmobdevim -F\\?     # Check for devices\n\n");
    
    dprint("\t\tmobdevim -U       # Prefer connection over USB\n\n");
    
    dprint("\t\tmobdevim -W       # Prefer connection over WIFI\n\n");
    
    dprint("\t-f\t# Get device info to a connected device (defaults to first USB connection)\n\n");
    
    dprint("\t-g\t# Get device logs/issues (TODO Broken in 16.5)\n\n"
            "\t\tmobdevim -g com.example.name # Get issues for com.example.name app\n"
            "\t\tmobdevim -g 3                # Get the 3rd most recent issue\n"
            "\t\tmobdevim -g __all            # Get all the logs\n\n");
    
    dprint("\t-l\t# List app information\n\n"
        "\t\tmobdevim -l                     # List all apps\n"
        "\t\tmobdevim -l com.example.test    # Get detailed info about app, com.example.test\n"
        "\t\tmobdevim -l com.example.test Entitlements # List \"Entitlements\" key from com.example.test\n\n");
    
    dprint("\t-r\t# Remove file\n\n"
           "\t\tmobdevim -r /fullpath/to/file # removes file (sandbox permitting)\n\n");
    
    dprint("\t-y\t# Yoink sandbox content\n\n"
           "\t\tmobdevim -y com.example.test   # Yoink contacts from app\n\n");
    
    dprint("\t-s\t# Send content to device (use content from yoink command)\n\n"
           "\t\tmobdevim -s com.example.test /tmp/com.example.test # Send contents in /tmp/com.example.test to app\n\n");
    
    dprint("\t-i\t# Install application (expects path to bundle)\n\n");
    dprint("\t-I\t# Install/mount a DDI (via Xcode subdir or repos like https://github.com/mspvirajpatel/Xcode_Developer_Disk_Images\n\n"
           "\t\tmobdevim -I /path/to/ddi.signature /path/to/ddi.dmg # Install DDI\n\n");
    dprint("\t-M\t# unMount a DDI (via Xcode subdir or repos like https://github.com/mspvirajpatel/Xcode_Developer_Disk_Images\n\n"
           "\t\tmobdevim -M # Unmount an alreaady mounted dev DDI\n\n");
    
    dprint("\t-u\t# Uninstall application, expects bundleIdentifier\n\n"
           "\t\tmobdevim -u com.example.test # Uninstall app\n\n");
    
    dprint("\t-w\t# Connect device to WiFi mode\n\n"
            "\t\tmobdevim -w              # Connect device to wifi for this computer\n"
            "\t\tmobdevim -w uuid_here    # Connect device to wifi for UUID\n"
            "\t\tmobdevim -w off          # Disable device wifi\n"
            "\t\tmobdevim -w uuid         # Display the computer's host uuid\n\n");
    
    dprint("\t-S\t# Arrange SpringBoard icons\n\n"
          "\t\tmobdevim -S                # Get current SpringBoard icon layout\n"
          "\t\tmobdevim -S /path/to/plist # Set SpringBoard icon layout from plist file\n"
          "\t\tmobdevim -S asshole        # Set SpringBoard icon layout to asshole mode\n"
          "\t\tmobdevim -S restore        # Restore SpringBoard icon layout (if backup was created)\n\n");
    
    dprint("\t-L\t# Simulate location (requires DDI)\n\n"
        "\t\tmobdevim -L 0 0                # Remove location simulation\n"
        "\t\tmobdevim -L 40.7128 -73.935242 # Simulate phone in New York\n\n");
    
    dprint("\t-c\t# Dump out the console information. Use ctrl-c to terminate\n\n");
    dprint("\t-C\t# Get developer certificates on device\n\n");
    dprint("\t-p\t# Display running processes on the device (requiers DDI)\n\n");
    
    dprint("\t-k\t# Kill a process (requiers DDI)\n\n");
    dprint("\t\tTODO");
    dprint("\t-b\t# Backup device\n\n");
        
    
    dprint("\t-P\t# Display developer provisioning profile info\n\n"
           "\t\tmobdevim -P # List all installed provisioning profiles\n"
           "\t\tmobdevim -P b68410a1-d825-4b7c-8e5d-0f76a9bde6b9 # Get detailed provisioning UUID info\n\n");
    
    dprint("\t-o\t# Open application (requires DDI)\n\n"
          "\t\tmobdevim -o com.reverse.domain # open app\n"
          "\t\tmobdevim -o com.reverse.domain -A \"Some args here\" -V AnEnv=EnValue -V A=B # open app with launch args and env vars\n\n");
    
    
    dprint("\t-R\t# Use color\n\n"
           "\t-Q\t# Quiet mode, ideal for limiting output or checking if a value exists based upon return status\n\n");
    
    dprint("Environment variables:\
           \tDSCOLOR - Use color (same as -R)\n\n\
           \tDSDEBUG - verbose debugging\n\n\
           \tDSPLIST - Display output in plist form (mobdevim -l com.test.example)\n\n\
           \tOS_ACTIVITY_DT_MODE - Combine w/ DSDEBUG to enable MobileDevice logging\n");
}

__attribute__((visibility("hidden")))
void assert_opt_arg(void) {
    return;
//  if (!optarg) {
////    print_manpage();
////    exit(5);
//  }
}

NSString *GetHostUUID(void) {
    CFUUIDBytes hostuuid;
    const struct timespec tmspec = { 0 };
    gethostuuid(&hostuuid.byte0, &tmspec);
    CFUUIDRef ref = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, hostuuid);
    return  CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, ref));
}

BOOL isWIFIConnected(AMDeviceRef d, NSString *uuid) {
    NSNumber *isWifiDebugged = AMDeviceCopyValue(d, @"com.apple.mobile.wireless_lockdown", @"EnableWifiDebugging", 0);
    id wirelessHosts = AMDeviceCopyValue(d, @"com.apple.xcode.developerdomain", @"WirelessHosts", 0);
    if (![isWifiDebugged boolValue]) {
        return NO;
    }
    
    if ([wirelessHosts containsObject:uuid]) {
        return YES;
    }
        
    return NO;
}

/// Options used for getopt_long
option_params global_options = {};

NSString * const kOptionArgumentDestinationPath = @"com.selander.destination";


char* InterfaceTypeString(InterfaceType type) {
    switch (type) {
        case InterfaceTypeYOLODontCare:
            return "Unknown";
        case InterfaceTypeUSB:
            return "USB";
        case InterfaceTypeWIFI:
            return "WIFI";
        default:
            break;
    }
}

