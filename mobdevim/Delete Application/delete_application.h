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
extern NSString * const kDeleteApplicationIdentifier;

/// Delete an application. Expects a path to an IPA in options
int delete_application(AMDeviceRef d, NSDictionary *options);
