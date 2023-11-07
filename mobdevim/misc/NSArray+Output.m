//
//  NSArray+Output.m
//  mobdevim
//
//
//  Copyright © 2020 Selander. All rights reserved.
//

#import "NSArray+Output.h"
#import "helpers.h"
@import ObjectiveC.runtime;

@implementation NSObject (Output)

@dynamic dsIndentOffset;

- (void)setDsIndentOffset:(NSNumber*)object {
    objc_setAssociatedObject(self, @selector(dsIndentOffset), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber*)dsIndentOffset {
    return objc_getAssociatedObject(self, @selector(dsIndentOffset));
}

- (const char *)dsformattedOutput {
    return [[self description] UTF8String];
}
@end


@implementation NSNumber (Output)
- (const char *)dsformattedOutput {
    BOOL plistOutput = (getenv("DSPLIST") != NULL);
    
    NSNumber *currentOffset = [self dsIndentOffset];
    if (!currentOffset) {
        currentOffset = @1;
    }
    
    if (plistOutput) {
        
        Class boolClass = [[NSNumber numberWithBool:YES] class];
        
        if([self isKindOfClass:boolClass]) {
            return [[NSString stringWithFormat:@"%*s<%s/>\n", ([currentOffset intValue]-1) * 4 , "",  [self boolValue] ? "true": "false"] UTF8String];
        } else {
            return [[NSString stringWithFormat:@"%*s<string>%@</string>\n", ([currentOffset intValue]-1) * 4 , "",  self] UTF8String];
        }
    }
    
    return [[NSString stringWithFormat:@"%*s%@\n", ([currentOffset intValue]-1) * 4 , "", self] UTF8String];
}
@end

@implementation NSString (Output)
- (const char *)dsformattedOutput {
    BOOL plistOutput = (getenv("DSPLIST") != NULL);
    
    NSNumber *currentOffset = [self dsIndentOffset];
    if (!currentOffset) {
        currentOffset = @1;
    }
    
    if (plistOutput) {
        return [[NSString stringWithFormat:@"%*s<string>%@</string>\n", ([currentOffset intValue]-1) * 4 , "",  self] UTF8String];
    }
    
    return [[NSString stringWithFormat:@"%*s%@\n", ([currentOffset intValue]-1) * 4 , "", self] UTF8String];
}
    

@end

@implementation NSArray (Output)

- (const char *)dsformattedOutput {
    NSMutableString *outputString = [NSMutableString string];
    BOOL plistOutput = (getenv("DSPLIST") != NULL);
    NSNumber *currentOffset = [self dsIndentOffset];
    if (!currentOffset) {
        currentOffset = @1;
    }
    if ([currentOffset intValue] == 1 && plistOutput) {
        [outputString appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n"];
    }
    
    
    if ([self count] == 0) {
        if (plistOutput) {
            [outputString appendString:@"<array></array>\n"];
        } else {
            [outputString appendFormat:@"%s[ ]%s", dcolor(dc_bold), colorEnd()];
        }
        return [outputString UTF8String];
    }
    
    if (plistOutput) {
        [outputString appendFormat:@"%*s<array>\n", ([currentOffset intValue]-1) * 4 , ""];
    } else {
        [outputString appendFormat:@"%*s%s[%s\n",  ([currentOffset intValue]-1) * 4 , "", dcolor(dc_bold), colorEnd()];
    }
    for (id itemObject in self) {
        [itemObject setDsIndentOffset:@([currentOffset intValue] + 1)];
        [outputString appendFormat:@"%s", [itemObject dsformattedOutput]];
    }
    
    
    if (plistOutput) {
        [outputString appendFormat:@"%*s</array>\n", ([currentOffset intValue]-1) * 4 , ""];
    } else {
        [outputString appendFormat:@"%*s%s]%s", ([currentOffset intValue]-1) * 4 , "",  dcolor(dc_bold), colorEnd()];
    }
    
    if ([currentOffset intValue] == 1 && plistOutput) {
        [outputString appendString:@"</plist>\n"];
    }
    
    
    return [outputString UTF8String];
    
}

@end

@implementation NSDictionary (Output)

- (const char *)dsformattedOutput {
    NSMutableString *outputString = [NSMutableString string];
    BOOL plistOutput = (getenv("DSPLIST") != NULL);

    NSNumber *currentOffset = [self dsIndentOffset];
    if (!currentOffset) {
        currentOffset = @1;
    }
    
    if ([currentOffset intValue] == 1 && plistOutput) {
        [outputString appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n"];
    }
    
    if (plistOutput) {
        [outputString appendFormat:@"%*s<dict>\n", ([currentOffset intValue] -1) * 4 , ""];
    } else {
        [outputString appendFormat:@"%*s%s{%s\n",  ([currentOffset intValue] -1) * 4 , "", dcolor(dc_bold), colorEnd()];
    }
    for (id key in self) {
        id itemObject = [self objectForKey:key];
        [itemObject setDsIndentOffset:@([currentOffset integerValue] + 1)];

        if (plistOutput) {
            [outputString appendFormat:@"%*s<key>%@</key>\n%s", [currentOffset intValue] * 4 , "",  key, [itemObject dsformattedOutput]];
        } else if ([itemObject isKindOfClass:[NSDictionary class]] || [itemObject isKindOfClass:[NSArray class]])  {
            [outputString appendFormat:@"%*s%s%@%s:\n%s\n", [currentOffset intValue] * 4 , "", dcolor(dc_cyan), key, colorEnd(), [itemObject dsformattedOutput]];
        } else {
            [outputString appendFormat:@"%*s%s%@%s: %@\n", [currentOffset intValue] * 4 , "", dcolor(dc_cyan), key, colorEnd(), itemObject];
        }
    }
    if (plistOutput) {
        [outputString appendFormat:@"%*s</dict>\n", ([currentOffset intValue] -1)  * 4 , ""];
    } else {
        [outputString appendFormat:@"%*s%s}%s\n", ([currentOffset intValue] -1)  * 4 , "",   dcolor(dc_bold), colorEnd()];
    }
    
    if ([currentOffset intValue] == 1 && plistOutput) {
        [outputString appendString:@"</plist>\n"];
    }
    
    return [outputString UTF8String];
}

@end


@implementation NSDate (Output)

- (const char *)dsformattedOutput {
    NSMutableString *outputString = [NSMutableString string];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMMM d, yyyy h:mm a"];
    [outputString appendFormat:@"%@", [formatter stringFromDate:self] ];
    return [outputString UTF8String];
}

@end
