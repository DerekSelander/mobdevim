//
//  list_applications.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"

/// List detailed information about a specific application bundle
extern NSString *const kListApplicationsName;

/// Only dump the info for the key, expects kListApplicationsName
extern NSString *const kListApplicationsKey;

/// List applications
int list_applications(AMDeviceRef d, NSDictionary *options);
