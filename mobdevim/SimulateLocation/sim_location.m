//
//  sim_location.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "sim_location.h"

NSString *const kSimLocationLat = @"com.selander.simlocation.lat";
NSString *const kSimLocationLon = @"com.selander.simlocation.lon";


static int write_string(AMDServiceConnectionRef ref, const char* str) {
  
  int length = (int)strlen(str);
  mach_error_t err = 0;
  int swapped_length = htonl(length);
  
  int result = AMDServiceConnectionSend(ref, &swapped_length, 4);
  if (result) {
    err = AMDServiceConnectionSend(ref, (void*)str, length);
  }
  return err;
}

#define SERVICE_START 0x0000000
#define SERVICE_STOP 0x1000000

int sim_location(AMDeviceRef d, NSDictionary *options) {
  NSString *lat = [options objectForKey:kSimLocationLat];
  NSString *lon = [options objectForKey:kSimLocationLon];
  
  int service = SERVICE_START;
  if ([lon integerValue] == 0 || [lat integerValue] == 0) {
    service = SERVICE_STOP;
  }
  
  AMDServiceConnectionRef serviceConnection = nil;
  AMDStartService(d, @"com.apple.dt.simulatelocation", &serviceConnection);

  
  int result = AMDServiceConnectionSend(serviceConnection, &service, 4);
  if (result && service == SERVICE_STOP) {
    dsprintf(stdout, "Successfully suspended location simulation\n");
    return 0;
  }
  
  if (!write_string(serviceConnection, [lat UTF8String])) {
    dsprintf(stderr, "Error writing to the location service\n");
    return 1;
  }
  
  if (!write_string(serviceConnection, [lon UTF8String])) {
    dsprintf(stderr, "Error writing to the location service\n");
    return 1;
  }

  AMDeviceDisconnect(d);
  dsprintf(stdout, "Successfully simulated location at: %s, %s\n", [lat UTF8String], [lon UTF8String]); 
  return 0;
}
