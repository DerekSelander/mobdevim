//
//  get_provisioning_profiles.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"

/// If this key is found in the options, the developer certs are copied to device
extern NSString * const kProvisioningProfilesCopyDeveloperCertificates;

/// Get detailed information based upon a provisioning proviles UUID
extern NSString * const kProvisioningProfilesFilteredByDevice;

/// Get the provisioning info or the certificates stored on the device
int get_provisioning_profiles(AMDeviceRef d, NSDictionary *options);
