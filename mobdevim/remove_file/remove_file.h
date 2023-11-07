//
//  remove_file.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"

/// The application ID to remove files from, WILL NOT WORK IF YOU DON'T HAVE THE MATCHING PP/CERTS!
extern NSString * const kRemoveFileBundleID;


/// The path to remove a file on the remote device
extern NSString * const kRemoveFileRemotePath;

/// Copies the Library, Documents, Caches directories over to the computer
int remove_file(AMDeviceRef d, NSDictionary *options);
