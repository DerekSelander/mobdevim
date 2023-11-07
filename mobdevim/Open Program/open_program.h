//
//  open_program.h
//  mobdevim
//
//  
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"

/// Opens program
#ifdef __cplusplus
extern "C" {
#endif
int open_program(AMDeviceRef d, NSDictionary *options);
#ifdef __cplusplus
}
#endif
