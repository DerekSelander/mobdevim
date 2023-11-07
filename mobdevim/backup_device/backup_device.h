//
//  install_application.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"

/// The path to the IPA file
//extern NSString * const kInstallApplicationPath;

/// Install an application over toe the device. Expects a path to an IPA in options
int backup_device(AMDeviceRef d, NSDictionary *options);
