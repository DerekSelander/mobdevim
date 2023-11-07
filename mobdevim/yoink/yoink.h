//
//  yoink.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"

/// The application ID to yoink from, WILL NOT WORK IF YOU DON'T HAVE THE MATCHING PP/CERTS!
extern NSString * const kYoinkBundleIDContents;

/// Copies the Library, Documents, Caches directories over to the computer
int yoink_app(AMDeviceRef d, NSDictionary *options);
