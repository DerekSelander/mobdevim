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


/// Lat
extern NSString *const kSimLocationLat;

/// Lon
extern NSString *const kSimLocationLon;

/// Sim Location, expects a lat / lon
int sim_location(AMDeviceRef d, NSDictionary *options);
