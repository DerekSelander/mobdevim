//
//  colors.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSArray+Output.h"
#import "ExternalDeclarations.h"

#ifdef __cplusplus
extern "C" {
#endif

/// Version String
extern const char *version_string;

/// Program Name
extern const char *program_name;

/// Usage of program
extern const char *usage;


/**
 Uses color of the DSCOLOR env var is set or -r option is used
 Possible options are:
 
 cyan
 yellow
 magenta
 red
 blue
 gray
 bold
 
 You must use the *colorEnd* function to stop using that color
 */
typedef enum {
    dc_cyan = 0,
    dc_yellow,
    dc_magenta,
    dc_red,
    dc_blue,
    dc_gray,
    dc_bold,
    dc_none,
} dc_colors;
const char* dcolor(dc_colors color);

/// Ends the color option if the DSCOLOR env var is set
char *colorEnd(void);

/// My printf
void dsprintf(FILE * f, const char *format, ...);
    
#define  derror(STR_, ...) \
{\
    if (!global_options.quiet) {\
        if (global_options.verbose) {\
            fprintf(stderr, "err: [%s:%d] " STR_,  __FILE__, __LINE__, ##__VA_ARGS__);\
        } else {\
            fprintf(stderr,  STR_, ##__VA_ARGS__);\
        } \
    }\
}
    
#define AMDStartService(_D, _S, _C) {\
    NSDictionary *_inputDict = @{@"InvalidateOnDetach": @YES, @"CloseOnInvalidate" : @YES, @"UnlockEscrowBag": @YES};\
    amd_err err__  = (AMDeviceSecureStartService(_D, _S, _inputDict, _C));\
    if (!(_C)) {\
        derror("error: \"%s\" invalid connection to %s\n", AMDErrorString(err__), [_S UTF8String]);\
        return 1;\
    }\
}

#define handle_err(_D) { amd_err err__ = ((_D)); if (err__) {derror("%s:%d err: \"%s\" (%d)", __FILE__, __LINE__, AMDErrorString(err__), err__); return err__; }} 
void dprint(const char *format, ...);

/// Enabled by DSDEBUG env var
void dsdebug(const char *format, ...);

/// Message then die
void ErrorMessageThenDie(const char *message, ...);

/// Self explanatory, right?... right?
void print_manpage(void);

/// Makes sure the optarg is valid, exit(1) if false
void assert_opt_arg(void);


///
extern NSString * const kOptionArgumentDestinationPath;

typedef struct {
    AMDeviceRef device;
    InterfaceType type;
} DeviceSelection;

typedef struct {
    /// open_program, expects bundleID like com.apple.mobileslideshow
    NSString *programBundleID;
    
    /// open_program, list of args i.e. "-NSBLahblah YES -UIFOOFOO NO"
    NSString *programArguments;
    
    /// springboardservices, i.e. restore, asshole
    NSString *springboardCommand;
    
    /// For -n, the payload path is specified after the bundle ID
    NSString *pushNotificationPayloadPath;
    
    NSString *ddiInstallPath;
    NSString *ddiSignatureInstallPath;
    
    /// Supress output
    BOOL quiet;

    /// Used for hunting for a particular device and connection
    DeviceSelection deviceSelection;
    
    NSString *expectedPartialUDID;
    
    BOOL choose_specific_device;
    int verbose;
} option_params;

extern option_params global_options;

void String4Interface(InterfaceType interface, char **out_str);
BOOL isWIFIConnected(AMDeviceRef d, NSString *uuid);

NSString *GetHostUUID(void);


#ifdef __cplusplus
}
#endif
