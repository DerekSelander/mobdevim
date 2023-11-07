//
//  Console.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "console_print.h"
//#import <stdio.h>
#import <sys/socket.h>

#define SIZE 2000
NSString *const kConsoleProcessName = @"com.selander.console.processname";

int console_print(AMDeviceRef d, NSDictionary* options) {
    
    AMDServiceConnectionRef connection = NULL;
    handle_err(AMDeviceSecureStartService(d, @"com.apple.syslog_relay",
                               @{@"UnlockEscrowBag" : @YES},
                               &connection));
    handle_err(AMDeviceStopSession(d));
    
    const char *processName = [[options objectForKey:kConsoleProcessName] UTF8String];
    int proc_len = 0;
    if (processName) {
        proc_len = (int)strlen(processName);
    }
    
    char buffer[SIZE];
//    memset(buffer, '\0', SIZE);
    
    int amountRead = 0;
    setbuf(stdout, NULL);
    bool shouldSkip = false;
    while (1) {
        
        memset(buffer, '\0', SIZE);
        amountRead = (int)AMDServiceConnectionReceive(connection, buffer, SIZE - 1 ); // Get those "P-\x01" bytes then end, easiest way to fix
        if (amountRead <= 0) {
            break;
        }
        
        if (buffer[0] == '\x00') {
            char *tmp = strchr(&buffer[1], '[');
            pid_t pidnumber = tmp ?  atoi(tmp + 1) : -1;
            
            tmp = strchr(&buffer[1], '>');
            const char* msg = tmp ? tmp + 3 : "?";
            
            const char* msgtype = "???";
            const char* msgtypeend = "???";
            tmp = strchr(&buffer[1], '<');
            if (tmp) {
                msgtype = tmp + 1;
                tmp = strchr(tmp, '>');
                if (tmp) {
                    msgtypeend = tmp;
                }
            }
            
            tmp = strrchr( tmp ? tmp : &buffer[1], '(');
#if 0
Oct 23 10:57:18 Dereks-iPhone symptomsd(SymptomNetworkUsage)[148] <Error>: Flow 322462 Unexpected attribution change, was procname <private> pid 74 epid 74 uuid <private> euuid <private>  now <private> 457 457 <private> <private>
#endif
            const char* pidName = "?";
            const char* pidNamEend = "?";
            const char* dateStr = "?";
            const char* deviceStr = "?";
            
            tmp = strchr(&buffer[1], ' ');
            if (tmp) {
                dateStr = &buffer[1];
                tmp = strchr(tmp + 1, ' ');
                if (tmp) {
                    tmp = strchr(tmp + 1, ' ');
                    if (tmp) {                     // Dereks-iPhone devicestr
                        deviceStr = tmp + 1;
                        tmp = strchr(tmp + 1, ' '); // date end, assign deviceStr
                        if (tmp) {
                            pidName = tmp + 1;
                            if (processName) {
                                if (strncmp(pidName, processName, proc_len) != 0) {
                                    shouldSkip = true;
                                    continue;
                                }
                                shouldSkip = false;
                            }
                            
                            tmp = strchr(tmp + 1, '['); // subsystem start
                            if (tmp) {
                                pidNamEend = tmp;
                            }
                        }
                    }
                }
            }
            
            const char *strColor = "";
            if (strncmp("Notice", msgtype, 6) == 0) {
                msgtype = "+";
                strColor = dcolor(dc_gray);
            } else {
                msgtype = "-";
                strColor = dcolor(dc_red);
            }
            
            if (deviceStr) {
                fprintf(stdout,  "%s%s%s %s%.*s%s %s%6d%s %s%.*s:%s\t%s%s%s", strColor,  msgtype, colorEnd(), dcolor(dc_gray),  (int)(deviceStr - &buffer[1]) - 1 , &buffer[1], colorEnd(), dcolor(dc_magenta), pidnumber, colorEnd(), dcolor(dc_yellow), (int)(pidNamEend - pidName), pidName, colorEnd(), dcolor(dc_cyan),  msg, colorEnd());
            } else {
                fprintf(stdout,  "%s%.*s%s", dcolor(dc_gray), amountRead - 1, &buffer[1], colorEnd());
            }
            
        } else {
            // only messages here
            if (!shouldSkip) {
                fprintf(stdout, "---   %s%.*s%s", dcolor(dc_cyan), amountRead , &buffer[0], colorEnd());
            }
        }
        
//        memset(buffer, '\0', SIZE);
    }

    return 0;
}
