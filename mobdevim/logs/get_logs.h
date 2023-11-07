//
//  send_files.h
//  mobdevim
//
//  
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"


/// The path to send up the files
extern NSString * const kGetLogsFilePath;


/// The path to send up the files
extern NSString * const kGetLogsAppBundle;

/// Should delete all crash logs
extern NSString * const kGetLogsDelete;

/// gets the device logs -g list all, -g bundleIdentifier all crashes for app,
/// -g bundleIdentifier path all crashes written to path
int get_logs(AMDeviceRef d, NSDictionary *options);
