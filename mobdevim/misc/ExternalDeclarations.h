//
//  ExternalDeclarations.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

/*
 Thank you @queersorceress for this: https://github.com/samdmarshall/SDMMobileDevice/blob/master/SDM_MD_Tests/MobileDevice.h, wish I knew about this file before I started exploring the
   AFC.* AMD.* family of functions
 
 
 Copyright (c) 2013-2015, Samantha Marshall
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 3. Neither the name of Samantha Marshall nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef ExternalDeclarations_h
#define ExternalDeclarations_h


#ifdef __cplusplus
extern "C" {
#endif


typedef struct _AMDevice {
  void *unknown0[4];
  CFStringRef deviceID;
  int32_t connection_type;
  int32_t unknown44;
  void *lockdown_conn;
  CFStringRef session;
  pthread_mutex_t mutex_lock;
  CFStringRef service_name;
  int32_t interface_index;
  int8_t device_active;
  unsigned char unknown7[3];
  int64_t unknown8;
  CFDataRef unknownData;
  CFDataRef network_address;
}  __attribute__((__packed__)) AMDevice;



#pragma mark - typedef
typedef  AMDevice *AMDeviceRef;
typedef  NSObject* AMDeviceObjc;
typedef struct _AMDServiceConnection AMDServiceConnection;
typedef AMDServiceConnection *AMDServiceConnectionRef;
typedef struct _AFCConnection  *AFCConnectionRef;

typedef enum : int {
    DeviceConnectionStatusError = 0,
  DeviceConnectionStatusConnect = 1,
  DeviceConnectionStatusDisconnected = 2,
  DeviceConnectionStatusStopped = 3,
    DeviceConnectionPairRequest = 4
} DeviceConnectionStatus;


typedef struct am_device_service_connection *DeviceNotificationRef;

typedef struct AMDeviceCallBackDevice {
    AMDeviceRef device;
    DeviceConnectionStatus status;
    DeviceNotificationRef notification;
//    int dunno1;
//    void *ref;
    uintptr_t dunno[2];
    
    CFDictionaryRef connectionDeets;
} AMDeviceCallBackDevice;

typedef struct _AFCIterator {
  char boring[0x10];
  CFDictionaryRef fileAttributes;
} AFCIterator;
typedef AFCIterator *AFCIteratorRef;

typedef struct _AFCFileInfo *AFCFileInfoRef;

typedef struct _AFCFileDescriptor {
  char boring[0x24];
  char *path;
} AFCFileDescriptor;
typedef AFCFileDescriptor *AFCFileDescriptorRef;

// USB vs WIFI
typedef enum : NSUInteger {
    InterfaceTypeYOLODontCare = 0,
    InterfaceTypeUSB = 1,
    InterfaceTypeWIFI = 2,
} InterfaceType;

    
typedef uint32_t amd_err;
#define AMD_SUCCESS 0

//*****************************************************************************/
#pragma mark - AMS.* Functions, backup
//*****************************************************************************/

    typedef int32_t ams_err;
typedef void (*AMSBackupProgressCallback) (NSString * identifier, int percent, void *context);
 ams_err AMSInitialize(NSString * backupPath);
 ams_err AMSBackupWithOptions(NSString* identifier, NSString * deviceUUID, NSDictionary *info, NSDictionary *options, AMSBackupProgressCallback callback, void *context);
 ams_err AMSCleanup(void);
//*****************************************************************************/
#pragma mark - AFC.* Functions, File Coordinator logic (I/O)
//*****************************************************************************/

// file i/o functions (thank you Samantha Marshall for these)
    amd_err AFCFileRefOpen(AFCConnectionRef, const char *path, uint64_t mode,AFCFileDescriptorRef*);
    amd_err AFCFileRefClose(AFCConnectionRef, AFCFileDescriptorRef);
    amd_err AFCFileRefSeek(AFCConnectionRef,  AFCFileDescriptorRef, int64_t offset, uint64_t mode);
    amd_err AFCFileRefTell(AFCConnectionRef, AFCFileDescriptorRef, uint64_t *offset);
size_t AFCFileRefRead(AFCConnectionRef,AFCFileDescriptorRef,void **buf,size_t *len);
    amd_err AFCFileRefSetFileSize(AFCConnectionRef,AFCFileDescriptorRef, uint64_t offset);
    amd_err AFCFileRefWrite(AFCConnectionRef,AFCFileDescriptorRef ref, const void *buf, uint32_t len);

    amd_err AFCDirectoryOpen(AFCConnectionRef, const char *, AFCIteratorRef*);
    amd_err AFCDirectoryRead(AFCConnectionRef, AFCIteratorRef, void *);
    amd_err AFCDirectoryClose(AFCConnectionRef, AFCIteratorRef);
    amd_err AFCDirectoryCreate(AFCConnectionRef, const char *);
    amd_err AFCRemovePath(AFCConnectionRef, const char *);

    amd_err AFCFileInfoOpen(AFCConnectionRef, const char *, AFCIteratorRef*);
    amd_err AFCKeyValueRead(AFCIteratorRef,  char **key,  char **val);
    amd_err AFCKeyValueClose(AFCIteratorRef);

//*****************************************************************************/
#pragma mark - AMDevice.* Functions, Main interaction w device
//*****************************************************************************/


    amd_err AMDeviceNotificationSubscribe(void (*)(AMDeviceCallBackDevice, int), int, int, int, void *);
    typedef void (*AMDeviceNotificationCallback)(AMDeviceCallBackDevice*, void* dunno);
    typedef void (*AMDevicePairAnotherCallback)(NSString * dunno, AMDeviceRef device);
    typedef void (^AMDevicePairRequestCallback)(AMDeviceRef, uint64_t options, uint64_t dunno,  AMDevicePairAnotherCallback anothercallback);
    amd_err AMDeviceNotificationSubscribeWithOptions(AMDeviceNotificationCallback, int, InterfaceType, void*, void *, NSDictionary *);
    amd_err AMDeviceConnect(AMDeviceRef);
    amd_err AMDeviceDisconnect(AMDeviceRef);
    amd_err AMDeviceIsPaired(AMDeviceRef);
    DEPRECATED_MSG_ATTRIBUTE("Dont use, looks like they are using AMDevicePairWithCallback now")
    amd_err AMDevicePair(AMDeviceRef);
    
    amd_err AMDevicePairWithCallback(AMDeviceRef device, AMDevicePairRequestCallback callback, NSDictionary* option, NSDictionary **outDict);
    
    amd_err AMDeviceUnpair(AMDeviceRef device);

InterfaceType AMDeviceGetInterfaceType(AMDeviceRef);
char* InterfaceTypeString(InterfaceType type);
    amd_err AMDeviceValidatePairing(AMDeviceRef);
    amd_err AMDeviceStartSession(AMDeviceRef);
    amd_err AMDeviceStopSession(AMDeviceRef);
    amd_err AMDeviceNotificationUnsubscribe(DeviceNotificationRef);
id AMDServiceConnectionGetSecureIOContext(AMDServiceConnectionRef);
    amd_err AMDeviceSecureTransferPath(int, AMDeviceRef, NSURL*, NSDictionary *, void *, int);
    amd_err AMDeviceSecureInstallApplication(int, AMDeviceRef, NSURL*, NSDictionary*, void *, int);
    amd_err AMDeviceSecureUninstallApplication(AMDServiceConnectionRef connection, void * dunno, NSString *bundleIdentifier, NSDictionary *params, void (*installCallback)(NSDictionary*, void *));
    amd_err AMDeviceSecureInstallApplicationBundle(AMDeviceRef, NSURL *path, NSDictionary *params, void (*installCallback)(NSDictionary*, void *));
    
    DEPRECATED_MSG_ATTRIBUTE("Dont use, looks like they are using AMDeviceCreateHouseArrestService now")
    amd_err AMDeviceStartHouseArrestService(AMDeviceRef, NSString *ident, NSDictionary *options, int *, void *);
    amd_err AMDeviceCreateHouseArrestService(AMDeviceRef device, NSString * ident, NSDictionary* options, AFCConnectionRef *connection);
    amd_err AMDeviceLookupApplications(AMDeviceRef, id, NSDictionary **);
    amd_err AMDeviceSecureStartService(AMDeviceRef, NSString *, NSDictionary *, void *);
    
    DEPRECATED_MSG_ATTRIBUTE("Use AMDeviceSecureStartService instead")
    amd_err AMDeviceStartServiceWithOptions(AMDeviceRef, NSString *, NSDictionary *, int *socket);
    amd_err AMDeviceSecureArchiveApplication(AMDServiceConnectionRef, AMDeviceRef, NSString *, NSDictionary *, void * /* */, id);
    amd_err AMDeviceGetTypeID(AMDeviceRef);


 NSArray* AMDCreateDeviceList(void);

// device/file information functions
//afc_error_t AFCDeviceInfoOpen(afc_connection conn, afc_dictionary *info);

    amd_err AMDeviceSecureRemoveApplicationArchive(AMDServiceConnectionRef, AMDeviceRef, NSString *, void *, void *, void *);
    
NSString *AMDeviceGetName(AMDeviceRef);
    
//*****************************************************************************/
#pragma mark - AMDService.* connects to a lockdownd service
//*****************************************************************************/

    /*
     ObserveNotification
         "com.apple.mobile.lockdown.activation_state";
         "com.apple.mobile.lockdown.developer_status_changed"
         "com.apple.springboard.deviceWillShutDown"
     
     */
    amd_err AMDServiceConnectionSendMessage(AMDServiceConnectionRef serviceConnection, NSDictionary* message, CFPropertyListFormat format);

    amd_err AMDServiceConnectionSend(AMDServiceConnectionRef, void *content, size_t length);
    NSArray* AMDCreateDeviceList(void);

    int AMDServiceConnectionGetSocket(AMDServiceConnectionRef);
    long AMDServiceConnectionReceive(AMDServiceConnectionRef, void *, long);
    amd_err AMDServiceConnectionReceiveMessage(AMDServiceConnectionRef serviceConnection, CFPropertyListRef, CFPropertyListFormat*);
    void AMDServiceConnectionInvalidate(AMDServiceConnectionRef);
    
//#define HANDLE_ERR(X)  HANDLE_ERR__((X), ({}))
#define DEBUG_SHIT()
#define HANDLE_ERR(X) { kern_return_t ___kr = (X); if (___kr) {fprintf(stderr, "err: %s\n\t%s:%d %s (%x)\n\n", __FILE__, __PRETTY_FUNCTION__, __LINE__, AMDErrorString(___kr), ___kr); DEBUG_SHIT(); exit(6);} }
#define HANDLE_ERR_RET(X) { amd_err ___kr = (X); if (___kr) {fprintf(stderr, "err: %s:%d\n\t%s %s (%x)\n\n", __FILE__,__LINE__, __PRETTY_FUNCTION__, AMDErrorString(___kr), ___kr); DEBUG_SHIT(); return ___kr;} }
    
//*****************************************************************************/
#pragma mark - AFC Apple File Conduit file transfer stuff
//*****************************************************************************/

    
mach_error_t AFCConnectionOpen(AMDServiceConnectionRef, int, AFCConnectionRef * /*AFCConnection */);

mach_error_t AFCConnectionClose(AFCConnectionRef);

id _AMDeviceCopyInstalledAppInfo(AMDeviceRef, char *);
id AMDeviceCopyValue(AMDeviceRef, void *, NSString *, unsigned long int /* device id */);
id AMDeviceSetValue(AMDeviceRef,  NSString *, NSString *, id newValue); /* device id */
NSString *AMDeviceCopyDeviceIdentifier(AMDeviceRef);
void *AMDeviceCopyDeviceLocation(AMDeviceRef);
NSDictionary* MISProfileCopyPayload(id);
NSArray *AMDeviceCopyProvisioningProfiles(AMDeviceRef);


mach_error_t AMDeviceMountImage(AMDeviceRef device, NSString* imagePath, NSDictionary *options, void (*callback)(NSDictionary *status, id deviceToken), id context);
mach_error_t AMDeviceUnmountImage(AMDeviceRef device, NSString *imagePath);

AFCConnectionRef AFCConnectionCreate(int unknown, int socket, int unknown2, int unknown3, void *context);


/// Queries information about the device see below for examples
extern id AMDeviceCopyValueWithError(AMDeviceRef ref, NSString * domain, NSString * value, NSError **err);

/// Wirelessly connect to devices
extern amd_err AMDeviceSetWirelessBuddyFlags(AMDeviceRef d, long flags);
extern amd_err AMDeviceGetWirelessBuddyFlags(AMDeviceRef d, long* flags);

extern char* AMDErrorString(long);

long AMDeviceCreateWakeupToken(AMDeviceRef d, NSDictionary *, NSDictionary**, NSError**);
long AMDeviceWakeupUsingToken(NSDictionary *, AMDeviceRef d);



// opaque structures
struct am_device;
struct am_device_notification;
struct am_device_service_connection;

extern struct am_device_service_connection *GDeviceConnection;
extern void* connection_callback;
AMDServiceConnectionRef connect_to_instruments_server(AMDeviceRef d);

#define AMDSessionActiveError 0xe800001d
#ifdef __cplusplus
}
#endif
/* AMDeviceCopyValueWithError (domain, values) examples
 ChipID / 32734
 DeviceName / Bobs’s iPhone
 UniqueChipID  / 1410439760381222
 InternationalMobileEquipmentIdentity / 289162076560126
 ActivationState / Activated
 DeviceClass / iPhone
 WiFiAddress / cc:08:8d:c7:04:6d
 BuildVersion /  15B150
 BluetoothAddress / cc:08:8d:c7:0d:b2
 HardwareModel / D10AP
 ProductVersion / 11.1.1
 SerialNumber / NNPSFCHNHG7A
 DeviceColor / 1
 DeviceEnclosureColor / 5
 CPUArchitecture / arm64
 com.apple.disk_usage, TotalDataCapacity / 252579303424
 ApNonce / <63af9d29 2a44cdac 00766d66 84a2c244 3740d4d4 bd494ec8 dd3d9ad0 9e2b5668>
 HasSEP / 1
 SEPNonce /  <00766d66 00766d66 00766d66 a21b8ab2 2576648c>
 Image4CryptoHashMethod / sha2-384
 Image4Supported / 1
 CertificateSecurityMode / 1
 EffectiveSecurityModeAp / 1
 EffectiveProductionStatusAp / 1
 FirmwarePreflightInfo / 2017-11-28 02:10:43.983085-0700 mobdevim[12621:1854164] {
 CertID = 2315222105;
 ChipID = 9781473;
 ChipSerialNo = <fee5c8c3>;
 FusingStatus = 3;
 SKeyStatus = 0;
 VendorID = 3;
 }
 
 BasebandGoldCertId / 2315222105
 
 BasebandKeyHashInformation /     AKeyStatus = 2;
 SKeyStatus = 0;
 PhoneNumber / (555) 632-1424
 RegionInfo / LL/A
 SIMStatus / kCTSIMSupportSIMStatusReady
 }
 
 com.apple.mobile.wireless_lockdown, BonjourFullServiceName / cc:08:8d:c7:04:6d@fe80::ce08:8dff:fec7:46d._apple-mobdev2._tcp.local.

 com.apple.mobile.wireless_lockdown, SupportsWifiSyncing / (null)
 
 com.apple.mobile.wireless_lockdown, WirelessBuddyID / (null)
 
 DevicePublicKey / bigcert
 DeviceCertificate / bigcert
 
 TelephonyCapability / 1
 BasebandStatus / BBInfoAvailable
 
 com.apple.disk_usage, AmountDataAvailable / 184877105152
 
 com.apple.mobile.internal, DevToolsAvailable / Standard
 
 PasswordProtected / 1
 
 ProductionSOC / 1
 
 com.apple.mobile.ldwatch, WatchCompanionCapability / 1
 
 SupportedDeviceFamilies ( 1 )
 
 com.apple.mobile.battery, BatteryCurrentCapacity / 100
 */

#endif /* ExternalDeclarations_h */
