//
//  SSVCRequestRunner.h
//  SSVC
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SSVC.h"
#import "SSVCResponse.h"
#import "SSVCURLConnection.h"
#import "SSVCSchedulerDelegate.h"

@protocol SSVCResponseParserProtocol;

@class SSVCScheduler;

@interface SSVCRequestRunner : NSObject <SSVCSchedulerDelegate, NSURLConnectionDataDelegate>

/// Designated initialiser
- (id)initWithCallbackURL:(NSURL *)callback
                parser:(id<SSVCResponseParserProtocol>)parser
               scheduler:(SSVCScheduler *)scheduler
           lastCheckDate:(NSDate *)lastCheckDate
                 success:(ssvc_fetch_success_block_t)success
                 failure:(ssvc_fetch_failure_block_t)failure;

- (void)checkVersion;

@end
