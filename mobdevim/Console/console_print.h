//
//  Console.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"

/// The name of the process to explore, no supplying this will snoop all output
extern NSString * const kConsoleProcessName;

/// Prints console output coming from the device
int console_print(AMDeviceRef d, NSDictionary* options);
