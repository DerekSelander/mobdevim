//
//  send_files.m
//  mobdevim
//
//  
//  Copyright © 2020 Selander. All rights reserved.
//

#import "send_files.h"
#import <sys/stat.h>

NSString * const kSendFilePath = @"com.selander.sendfilepath";

NSString * const kSendAppBundle = @"com.selander.appbundle";

int send_files(AMDeviceRef d, NSDictionary *options) {
  
  NSString *writingFromDirectory = [options objectForKey:kSendFilePath];
  if ([writingFromDirectory hasSuffix:@"xcappdata"]) {
    writingFromDirectory = [writingFromDirectory stringByAppendingPathComponent:@"AppData"];
  }
  
  NSURL *localFileURL = [[[NSURL fileURLWithPath:writingFromDirectory] URLByStandardizingPath] URLByResolvingSymlinksInPath];
  if (!localFileURL) {
    dsprintf(stderr, "Couldn't find directory \"%s\"\nExiting", [[localFileURL description] UTF8String]);
    return EACCES;
  }
  
  NSFileManager* manager = [NSFileManager defaultManager];
  
  NSDirectoryEnumerator *dirEnumerator = [manager enumeratorAtURL:localFileURL includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
    
    
    if (error) {
      dsprintf(stderr, "Couldn't enumerate directory\n%s", [[error localizedDescription] UTF8String]);
      exit(EACCES);
    }
    
    return YES;
  }];
  
  // At this point, we are good on the local OS X, search for appID now
  
  NSDictionary *dict;
  NSString *appBundle = [options objectForKey:kSendAppBundle];
  NSDictionary *opts = @{ @"ApplicationType" : @"Any",
                          @"ReturnAttributes" : @[@"ApplicationDSID",
                                                  //                                                    @"ApplicationType",
                                                  //                                                    @"CFBundleDisplayName",
                                                  //                                                    @"CFBundleExecutable",
                                                  @"CFBundleIdentifier",
                                                  //                                                    @"CFBundleName",
                                                  //                                                    @"CFBundleShortVersionString",
                                                  //                                                    @"CFBundleVersion",
                                                  //                                                    @"Container",
                                                  //                                                    @"Entitlements",
                                                  //                                                    @"EnvironmentVariables",
                                                  //                                                    @"MinimumOSVersion",
                                                  @"Path",
                                                  //                                                    @"ProfileValidated",
                                                  //                                                    @"SBAppTags",
                                                  //                                                    @"SignerIdentity",
                                                  //                                                    @"UIDeviceFamily",
                                                  //                                                    @"UIRequiredDeviceCapabilities"
                                                  ]};
  
  AMDeviceLookupApplications(d, opts, &dict);
  NSString *appPath = [[dict objectForKey:appBundle] objectForKey:@"Path"];
  
  if (!appPath) {
    dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor(dc_yellow), [appBundle UTF8String], colorEnd(), dcolor(dc_bold), colorEnd());
    return 1;
  }
  
  AMDServiceConnectionRef serviceConnection = nil;
  NSDictionary *inputDict = @{@"CloseOnInvalidate" : @NO, @"UnlockEscrowBag": @YES};
  AMDeviceSecureStartService(d, @"com.apple.mobile.house_arrest", inputDict, &serviceConnection);
  if (!serviceConnection) {
    return EACCES;
  }
  
  NSDictionary *inputDictionary = @{ @"Command" : @"VendContainer", @"Identifier" : appBundle };
  if (AMDServiceConnectionSendMessage(serviceConnection, inputDictionary, kCFPropertyListXMLFormat_v1_0)) {
    return EACCES;
  }
  
  long socket = AMDServiceConnectionGetSocket(serviceConnection);
  id info = nil;
  AMDServiceConnectionReceiveMessage(serviceConnection, &info, nil);
  
  AFCConnectionRef connectionRef = AFCConnectionCreate(0, (int)socket, 1, 0, 0);
  if (!connectionRef) {
    dsprintf(stderr, "%sCould not obtain a valid connection. Aborting%s\n", dcolor(dc_yellow), colorEnd());
    return EACCES;
  }
  
  

  NSString *baseResolvedPath = nil;
  for (NSURL *fileURL in dirEnumerator) {
    
    // TODO symlinked issues, quick hack for now...
    if (!baseResolvedPath) {
      baseResolvedPath = [[fileURL path] stringByDeletingLastPathComponent];
    }
    NSString *basePath = [NSString stringWithUTF8String:[fileURL fileSystemRepresentation]];
    NSRange range = [basePath rangeOfString:baseResolvedPath];
    
    range.location = range.length;
    range.length = [basePath length] - range.location;
    assert(range.length != 0);
    
    NSString *remotePath = [basePath substringWithRange:range];
    
    
    BOOL isDirectory = NO;
    NSString *remoteDirectory = nil;
    NSString *fileName = [fileURL lastPathComponent];
    
    [manager fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];
    if ([fileName isEqualToString:@".DS_Store"]) {
      continue;
    }
    
    if (isDirectory) {
      remoteDirectory = remotePath;
    } else {
      remoteDirectory = [remotePath stringByDeletingLastPathComponent];
    }
    
    AFCFileDescriptorRef fileDescriptor = NULL;
    AFCIteratorRef iteratorRef = NULL;
    AFCDirectoryOpen(connectionRef, [remotePath fileSystemRepresentation], &iteratorRef);
    
    // directory might not exist on the remote side, create it
    if (isDirectory && !iteratorRef) {
      if (AFCDirectoryCreate(connectionRef, [remotePath fileSystemRepresentation])) {
        dsprintf(stderr, "Couldn't create directory: %s on the remote side\n", [remotePath fileSystemRepresentation]);
      }
      AFCDirectoryClose(connectionRef, iteratorRef);
      iteratorRef = NULL;
      
    }
    
    else if (!isDirectory) {
      AFCFileRefOpen(connectionRef, [remotePath fileSystemRepresentation], 0x3, &fileDescriptor);
      if (!fileDescriptor) {
        dsprintf(stderr, "Couldn't open file \"%s\" on the device side\n", [remotePath fileSystemRepresentation]);
        continue;
      }
      
      NSData *data = [NSData dataWithContentsOfURL:fileURL];
      if (!data) {
        dsprintf(stderr, "Invalid directory to write from: %s\n", [fileURL fileSystemRepresentation]);
        return EACCES;
      }
      
      
      mach_error_t err = AFCFileRefWrite(connectionRef, fileDescriptor, [data bytes], (uint32_t)[data length]);
      if (err) {
        dsprintf(stderr, "Error writing to \"%s\", %d\n", [remotePath fileSystemRepresentation], err);
      }
      
      AFCFileRefClose(connectionRef, fileDescriptor);
    }
  }
  
  return 0;
}


