//
//  conditions.h
//  mobdevim
//
//  Created by Derek Selander on 4/15/20.
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"

/// The application ID to remove files from, WILL NOT WORK IF YOU DON'T HAVE THE MATCHING PP/CERTS!
//extern NSString * const kSBSFileBundleID;


/// The path to remove a file on the remote device
//extern NSString * const kSBCommand;

/// Copies the Library, Documents, Caches directories over to the computer
int install_ddi(AMDeviceRef d, NSDictionary *options);
int uninstall_ddi(AMDeviceRef d, NSDictionary *options);
