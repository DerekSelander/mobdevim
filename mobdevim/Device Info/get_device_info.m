//
//  get_device_info.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "get_device_info.h"

int get_device_info(AMDeviceRef d, NSDictionary *options) {
  
  NSString *udid = AMDeviceGetName(d);
  NSString *deviceName = AMDeviceCopyValue(d, nil, @"DeviceName", 0);
  NSString *activationState = AMDeviceCopyValue(d, nil, @"ActivationState", 0);
  NSString *phoneNumber = AMDeviceCopyValue(d, nil, @"PhoneNumber", 0);
  NSString *regionInfo = AMDeviceCopyValue(d, nil, @"RegionInfo", 0);
  
//  NSNumber *passwordProtected = AMDeviceCopyValue(d, nil, @"PasswordProtected", 0);
  NSNumber *battery = AMDeviceCopyValue(d, @"com.apple.mobile.battery",
                                        @"BatteryCurrentCapacity", 0);
  NSString *classType = AMDeviceCopyValue(d, nil, @"DeviceClass", 0);
  NSString *productVersion = AMDeviceCopyValue(d, nil, @"ProductVersion", 0);
  
  NSNumber *diskAmountAvailable = AMDeviceCopyValue(d, @"com.apple.disk_usage",
                                                    @"AmountDataAvailable", 0);
  NSNumber *totalDataCapacity = AMDeviceCopyValue(d, @"com.apple.disk_usage",
                                                  @"TotalDataCapacity", 0);
  double  diskSpace =  100.0 * ((double)[diskAmountAvailable doubleValue] / (long)[totalDataCapacity doubleValue]);
  NSString *serialNumber = AMDeviceCopyValue(d, nil, @"SerialNumber", 0);
  NSString *hardwareModel = AMDeviceCopyValue(d, nil, @"HardwareModel", 0);
  
  NSString *productType = AMDeviceCopyValue(d, nil, @"ProductType", 0);
  
  NSString *bonjour = AMDeviceCopyValue(d, @"com.apple.mobile.wireless_lockdown",
                                        @"BonjourFullServiceName", 0);
  NSString *wifiAddress = AMDeviceCopyValue(d, nil, @"WiFiAddress", 0);
  NSString *bluetoothAddress = AMDeviceCopyValue(d, nil, @"BluetoothAddress", 0);
  
  NSString *developerStatus = AMDeviceCopyValue(d, @"com.apple.xcode.developerdomain", @"DeveloperStatus", 0);
  
  char *s = dcolor(dc_gray);
  char *e = colorEnd();
  dsprintf(stdout, "\n%sname%s\t%s\n"
           "%sUDID%s\t%s\n"
           "%sProduct Type%s\t%s\n\n"
           "%sState%s\t%s\n"
           "%sType%s\t%s\n"
           "%sVersion%s\t%s\n"
           "%sNumber%s\t%s\n"
           "%sRegion%s\t%s\n"
           "%sBattery%s\t%s%%\n\n"
           
           "%sDskSpce%s\t%d%%\n"
           "%sSerial%s\t%s\n"
           "%sHardwr%s\t%s\n"
           "%sdevstat%s\t%s\n\n"
           
           "%sBonjour%s\t%s\n"
           "%sWiFi%s\t%s\n"
           "%sBL Addr%s\t%s\n",
           s, e, [deviceName UTF8String],
           s, e, [udid UTF8String],
           s, e, [productType UTF8String],
           s, e, [activationState UTF8String],
           s, e, [classType UTF8String],
           s, e, [productVersion UTF8String],
           s, e, phoneNumber ? [phoneNumber UTF8String] : "Not Available",
           s, e, [regionInfo UTF8String],
           s, e, [[battery stringValue] UTF8String],
           
           s, e, (int)diskSpace,
           s, e, [serialNumber UTF8String],
           s, e, [hardwareModel UTF8String],
           s, e, [developerStatus UTF8String],
           
           s, e, [bonjour UTF8String],
           s, e, [wifiAddress UTF8String],
           s, e, [bluetoothAddress UTF8String]
           );
  return 0;
}
