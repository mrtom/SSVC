//
//  SSVC.h
//  SSVC
//
//  Created by Tom Elliott on 3/3/14.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SSVCScheduler.h"

@class SSVCResponse;

typedef void (^ssvc_fetch_success_block_t)(SSVCResponse *response);
typedef void (^ssvc_fetch_failure_block_t)(NSError *error);

extern NSString *const SSVCCallbackURLKey;
extern NSString *const SSVCDateOfLastVersionCheck;
extern NSString *const SSVCUpdateAvailable;
extern NSString *const SSVCUpdateRequired;
extern NSString *const SSVCMinimumSupportedVersionNumber;
extern NSString *const SSVCLatestVersionKey;
extern NSString *const SSVCLatestVersionNumber;
extern NSString *const SSVCLatestVersionAvailableSince;

extern NSString *const SSVCResponseFromLastVersionCheck;

@interface SSVC : NSObject

@property (nonatomic, strong, readonly) NSURL *callbackURL;
@property (nonatomic, strong, readonly) NSDate *dateOfLastVersionCheck;

/// Initialise without any scheduler or callback blocks
/// You will have to manually call checkVersion: and manually check the response saved to User Defaults
///
/// You probably want to use one of the other init methods with callbacks!
- (id)init;

/// Initialise with the callback URL specified in your main -Info.plist, under key SSVCCallbackURLKey
- (id)initWithCompletionHandler:(ssvc_fetch_success_block_t)success
                 failureHandler:(ssvc_fetch_failure_block_t)failure;

/// Initialise with your own callback URL
/// Designated initialiser
- (id)initWithScheduler:(SSVCScheduler *)scheduler
         forCallbackURL:(NSString *)url
  withCompletionHandler:(ssvc_fetch_success_block_t)success
         failureHandler:(ssvc_fetch_failure_block_t)failure;

- (id)initWithScheduler:(SSVCScheduler *)scheduler
  withCompletionHandler:(ssvc_fetch_success_block_t)success
         failureHandler:(ssvc_fetch_failure_block_t)failure;


// Fetch latest version info from the server, now
- (void)checkVersion;

// Returns the last response from the server, or nil if no response has been fetched
- (SSVCResponse *)lastResponse;

@end
