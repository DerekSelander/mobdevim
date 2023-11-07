//
//  NSArray+Output.h
//  mobdevim
//
//  
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Output)
- (const char *)dsformattedOutput;
@end

@interface NSDictionary (Output)
- (const char *)dsformattedOutput;
@end

@interface NSDate (Output)
- (const char *)dsformattedOutput;
@end

@interface NSObject (Output)
@property (nonatomic, strong) NSNumber* dsIndentOffset;
@end


