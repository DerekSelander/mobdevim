//
//  conditions.h
//  mobdevim
//
//  Created by Derek Selander on 4/15/20.
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

#import "helpers.h"
#import "ExternalDeclarations.h"
/// The application ID to remove files from, WILL NOT WORK IF YOU DON'T HAVE THE MATCHING PP/CERTS!
//extern NSString * const kSBSFileBundleID;


/// The path to remove a file on the remote device
//extern NSString * const kSBCommand;


/// The path to remove a file on the remote device
extern NSString * const kProcessKillPID;
int kill_process(AMDeviceRef d, NSDictionary *options) ;
/// Copies the Library, Documents, Caches directories over to the computer
int running_processes(AMDeviceRef d, NSDictionary *options);

#ifdef __cplusplus
}
#endif
