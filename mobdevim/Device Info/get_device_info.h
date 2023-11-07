//
//  get_device_info.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"

/// Get basic device info, i.e. phone number (if iPhone), bonjour address etc...
int get_device_info(AMDeviceRef d, NSDictionary *options);

