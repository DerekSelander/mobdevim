//
//  InternalApi.h
//  FreeTheSandbox
//
//  Created by codecolorist on 2020/2/17.
//  Copyright © 2020 CC. All rights reserved.
//

#ifndef InternalApi_h
#define InternalApi_h



@interface DVTDeveloperPaths : NSObject
+ (void)initializeApplicationDirectoryName:(id)arg1;
@end

@interface DVTPlugInManager : NSObject
- (BOOL)scanForPlugIns:(id *)arg1;
@end


@protocol XRIssueResponder <NSObject>
- (void)handleIssue:(NSError *)arg1 type:(unsigned long long)arg2 from:(id)arg3;
@end

@interface XRPackageConflictErrorAccumulator : NSObject <XRIssueResponder>
- (id)initWithNextResponder:(id)arg1;
@end


@interface XRUniqueIssueAccumulator : NSObject <XRIssueResponder>

@end

@interface DTXMessage : NSObject
@property(copy, nonatomic) id payloadObject;
+ messageWithSelector:(SEL)sel objectArguments: (id)args, ...;
- (NSError*)error;
@end


@interface DTXChannel : NSObject
- (void)receiveMobileAgent:(id)arg1;
- (id)messageReplyTicketForControlMessage:(id)arg1 agent:(id)arg2;
- (void)sendMessageSync:(id)arg1 replyHandler:(void (^)(id, int))handler;
@end

@interface DVTFilePath : NSObject <NSCopying, NSSecureCoding>
@end

@interface DVTPlatform : NSObject <NSCopying>

@property(readonly, copy) NSString *platformVersion;
@property(readonly, copy) NSDictionary *deviceProperties;
@property(readonly) DVTFilePath *iconPath;

@end

@protocol DTXDSProtocol <NSObject>
-(id)makeChannelWithIdentifier:(NSString*)identifier;
-(int)remoteCapabilityVersion:(NSString*)identifier;
-(void)cancel;
-(void)suspend;
@end

@interface XRDevice : NSObject

@property(retain) DTXChannel *deviceInfoService;
-(id<DTXDSProtocol>)connection;
@property(copy) NSImage *downsampledDeviceImage;
@property(retain) DTXChannel *capabilitiesChannel;
@property double timeDifference;
@property(readonly, copy) NSString *activePairedWatchDeviceIdentifier;
@property(readonly, copy) NSString *companionDeviceIdentifier;
@property long long symbolsState;
@property(retain) DVTPlatform *platform;
@property(copy) NSString *modelName;
@property(copy) NSString *modelUTI;
@property(copy) NSString *productType;
@property(copy) NSString *productVersion;
@property(copy) NSString *buildVersion;
@property(copy) NSString *deviceDescription;
@property(copy) NSString *rawDeviceDisplayName;
@property(copy) NSString *deviceDisplayName;
@property(copy) NSString *deviceHostName;
@property(copy) NSString *deviceIdentifier;
@property(readonly) unsigned int deviceNumber;
@property(readonly) int connectionCount;
@property(copy) NSImage *deviceSmallRepresentationIcon;
@end

@interface XRRemoteDevice : XRDevice
@property(retain) DTXChannel *companionControlChannel;
@property(retain) DTXChannel *applicationChannel;
@property(retain) DTXChannel *notificationsChannel;
@property(retain) DTXChannel *posixProcessControlChannel;
@property(retain) DTXChannel *defaultProcessControlChannel;
@property(retain) DTXChannel *xpcLauncherService;
@property(retain) DTXChannel *launchDaemonService;
@property(retain) DTXChannel *wirelessControlChannel;
@property(copy, nonatomic) NSString *wirelessServiceName;
- (id)queryCompanionForActiveWatchDeviceIdentifier;
- (id)activePairedWatchDeviceIdentifier;
- (void)willUnpairFromCompanion:(id)arg1;
- (void)didPairWithCompanion:(id)arg1;
- (instancetype)initWithDevice:(AMDeviceRef)device;
- (void)handleNewRawDeviceDisplayName;
- (void)simulateMemoryWarning:(id)arg1;
- (id)targetControlDataElementsForProcess:(id)arg1;
- (id)launchControlDataElementsForProcess:(id)arg1;
- (void)outputReceived:(id)arg1 fromProcess:(int)arg2 atTime:(unsigned long long)arg3;
- (void)thermalLevelNotification:(id)arg1;
- (void)memoryLevelNotification:(id)arg1;
- (void)applicationStateNotification:(id)arg1;
- (unsigned long long)_traceRelativeTimestampForNotification:(id)arg1 inTrace:(id)arg2;
- (void)setMemoryConstraint:(int)arg1;
- (int)memoryConstraint;
- (id)availableNetworkInterfaces;
- (id)displayNameForNetworkInterface:(id)arg1;
- (BOOL)supportsDeviceIO;
- (BOOL)daemonsSupported;
- (BOOL)legacyDaemonsSupported;
@property(readonly, copy) NSString *cpuArchitecture;
- (id)cpuDescription;
- (id)deviceArchitecture;
- (int)speedOfCpus;
- (int)numberOfPhysicalCpus;
- (int)numberOfCpus;
- (BOOL)resumeProcess:(id)arg1;
- (BOOL)suspendProcess:(id)arg1;
- (void)terminateProcess:(id)arg1;
- (int)launchProcess:(id)arg1 suspended:(BOOL)arg2 error:(id *)arg3;
- (void)pidDiedCallback:(id)arg1;
- (void)removeObserver:(id)arg1 forPid:(int)arg2;
- (void)addObserver:(id)arg1 forPid:(int)arg2;
- (BOOL)allowsChoosingExecutable;
- (void)dyldNotificationReceived:(id)arg1;
- (struct _CSTypeRef)createKernelSymbolicator;
- (BOOL)supportsKernelBacktracing;
- (struct _CSTypeRef)createSymbolicatorForPid:(int)arg1;
- (BOOL)executableIsRestricted:(id)arg1 launchOptions:(id)arg2;
- (BOOL)isRunningPid:(int)arg1;
- (id)execnameForPid:(int)arg1;
- (id)userForUID:(id)arg1;
- (NSImage *)iconForAppPath:(id)arg1 executableName:(id)arg2;
- (NSArray*)runningProcesses;
- (id)defaultAppIcon;
- (id)marketizedPlatformName;
- (id)platformName;
- (BOOL)updateInstalledExecutables;
- (id)fileSystem;
- (id)processControlServiceForPid:(int)arg1;
- (void)checkForSymbols;
- (void)xcodeWasTerminated:(unsigned int)arg1;
- (void)xcodeWasLaunched:(unsigned int)arg1;
- (void)symbolsDownloadedAtPath:(id)arg1;
- (id)externalSDKPath;
- (id)internalSDKPath;
- (id)baseSymbolsPath;
- (void)teardownConnection;
- (int)processControlServiceVersion;
- (id)makeConnection;
- (void)prepareConnection:(id)arg1;
- (id)_faultConnection;
- (id)initWithTemplateData:(id)arg1;
- (id)templateData;
- (BOOL)supportsProcessControlEventDictionaries;
- (void)preflightDevice;
- (void)dealloc;
- (id)initWithIdentifier:(id)arg1;

@end

 @interface XRMobileDevice : XRRemoteDevice
- (instancetype)initWithDevice:(id)device;
@end

@interface PFTProcess : NSObject <NSCopying>
{
    NSString *_userProvidedArgs;
    NSDictionary *_userProvidedEnvironment;
    NSMutableDictionary *_mutatedEnvironment;
    NSMutableArray *_stopActions;
    NSString *_executablePath;
    NSString *_processName;
    NSString *_displayName;
    NSString *_bundleIdentifier;
    XRRemoteDevice *_device;
    int _pid;
    BOOL _watchingForTermination;
    BOOL _didLaunchProcess;
    int _specifiedType;
    BOOL _subtaskPaused;
    BOOL _restricted;
    NSDate *_startDate;
    PFTProcess *_hostProcess;
    NSDictionary *_properties;
    NSMutableDictionary *_launchControlProperties;
    NSImage *_atomicProcessImage;
}

+ (int)targetTypeForProcess:(id)arg1;
+ (id)processFromData:(id)arg1 device:(id)arg2;
+ (id)unspecifiedProcess;
+ (void)initialize;
@property(retain) NSImage *atomicProcessImage;
@property(readonly) NSMutableDictionary *launchControlProperties;
@property(copy) NSDictionary *properties;
@property(copy, nonatomic) PFTProcess *hostProcess;
@property BOOL restricted;
@property(retain, nonatomic) NSDate *startDate;
@property(readonly) __weak XRRemoteDevice *device;
@property(readonly) int processIdentifier;
@property(readonly) NSString *executablePath;
@property(copy) NSString *argumentsString;
- (id)functionSymbolNames;
@property(readonly, copy) NSString *description;
@property int type;
@property(nonatomic, getter=isPaused) BOOL paused;
@property(copy) id image;
- (void)stop;
- (void)addStopAction:(id)arg1;
- (void)notifyOnTermination;
@property(readonly, getter=isRunning) BOOL running;
- (BOOL)runSuspended:(BOOL)arg1 error:(id *)arg2;
- (void)processDeathDetectedForPid:(int)arg1;
- (void)resetInitialEnvironmentAndArgs;
- (void)addEnvironmentVariable:(id)arg1 value:(id)arg2;
@property(readonly) NSArray *arguments;
@property(copy) NSDictionary *environment;
@property(readonly, nonatomic) int processDomain;
@property(readonly, nonatomic) NSArray *canonicalHostProcesses;
@property(readonly, nonatomic) NSDictionary *extensionInfo;
@property(readonly) NSString *bundleIdentifier; // @synthesize bundleIdentifier=_bundleIdentifier;
@property(copy, nonatomic) NSString *displayName;
@property(readonly) NSString *processName;
- (id)templateData;
- (id)copyWithZone:(struct _NSZone *)arg1;
- (BOOL)isEqual:(id)arg1;
- (int)_targetType;
- (void)_setPid:(int)arg1 asOwner:(BOOL)arg2;
@property(readonly) BOOL _isProcessOwner;
- (id)initWithDevice:(id)arg1 path:(NSString*)arg2 bundleIdentifier:(NSString *)arg3 arguments:(NSString*)arg4 environment:(NSDictionary *)arg5 launchOptions:(id)arg6;

@end

@interface XRDeviceDiscovery : NSObject

+ (void)xcodeTerminated:(unsigned int)arg1;
+ (void)xcodeLaunched:(unsigned int)arg1;
+ (id)devicesMatching:(id)arg1;
+ (id)deviceForIdentifier:(id)arg1;
+ (id)allKnownDevices;
+ (NSArray <XRRemoteDevice*>*)availableDevices;
+ (void)unregisterForDeviceNotifications:(unsigned int)arg1;
+ (void)forgetDevice:(id)arg1;
+ (void)deviceStateChanged:(id)arg1;
+ (void)deviceConnected:(id)arg1;
+ (void)initialize;
+ (id)deviceDiscoveryImplementations;
+ (void)registerDeviceObserver:(id)arg1;

- (void)stopListeningForDevices;
- (void)startListeningForDevices;
- (id)deviceList;
- (id)deviceManagementItems;
- (id)deviceManagementName;
- (id)imageForDeviceType:(id)arg1 deviceColorString:(id)arg2 deviceEnclosureColorString:(id)arg3;
- (id)imageForDeviceType:(id)arg1;

@end

#endif /* InternalApi_h */
