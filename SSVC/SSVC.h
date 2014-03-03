//
//  SSVC.h
//  SSVC
//
//  Created by Tom Elliott on 3/3/14.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SSVCResponse.h"

typedef void (^ssvc_fetch_success_block_t)(SSVCResponse *response);
typedef void (^ssvc_fetch_failure_block_t)(NSError * error);

extern NSString *const SSVCCallbackURLKey;

@interface SSVC : NSObject

@property (nonatomic, strong, readonly) NSURL *callbackURL;
@property (nonatomic, strong, readonly) NSDate *dateOfLastVersionCheck;

// Initialise with the callback URL specified in your main -Info.plist, under key SSVCCallbackURLKey
- (id)init;

// Initialise with your own callback URL
- (id)initWithCallbackURL:(NSURL *)url;

// Fetch latest version info from the server
- (void)checkVersionWithCompletionHandler:(ssvc_fetch_success_block_t)success
                           failureHandler:(ssvc_fetch_failure_block_t)failure;

@end
