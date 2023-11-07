//
//  send_files.h
//  mobdevim
//
//  
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"


/// The path to send up the files
extern NSString * const kSendFilePath;


/// The path to send up the files
extern NSString * const kSendAppBundle;

int send_files(AMDeviceRef d, NSDictionary *options);
