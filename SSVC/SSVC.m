//
//  SSVC.m
//  SSVC
//
//  Created by Tom Elliott on 3/3/14.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import "SSVC.h"

#import "SSVCJSONParser.h"
#import "SSVCResponse.h"
#import "SSVCRequestRunner.h"
#import "SSVCSchedulerDelegate.h"
#import "SSVCURLConnection.h"
#import "SSVCURLGenerator.h"

// Names for keys
NSString *const SSVCCallbackURLKey = @"SSVCCallbackURL";
NSString *const SSVCDateOfLastVersionCheck = @"SSVCDateOfLastVersionCheck";
NSString *const SSVCUpdateAvailable = @"SSVCUpdateAvailable";
NSString *const SSVCUpdateRequired = @"SSVCUpdateRequired";
NSString *const SSVCUpdateAvailableSince = @"SSVCUpdateAvailableSince";
NSString *const SSVCLatestVersionKey = @"SSVCLatestVersionKey";
NSString *const SSVCLatestVersionNumber = @"SSVCLatestVersionNumber";

NSString *const SSVCResponseFromLastVersionCheck = @"SSVCResponseFromLastVersionCheck";

@interface SSVC()

@property (nonatomic, copy, readonly) SSVCScheduler *scheduler;
@property (nonatomic, copy, readonly) ssvc_fetch_success_block_t success;
@property (nonatomic, copy, readonly) ssvc_fetch_failure_block_t failure;

@property (nonatomic, copy, readonly) NSString *versionKey;
@property (nonatomic, copy, readonly) NSNumber *versionNumber;

@end

@implementation SSVC

#pragma mark - Initialisation

- (id)init
{
  return [self initWithCompletionHandler:nil failureHandler:nil];
}

- (id)initWithCompletionHandler:(ssvc_fetch_success_block_t)success
                 failureHandler:(ssvc_fetch_failure_block_t)failure;
{
  NSString *urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:SSVCCallbackURLKey];
  SSVCScheduler *scheduler = [[SSVCScheduler alloc] init];
  return [self initWithScheduler:scheduler
                  forCallbackURL:urlString
           withCompletionHandler:success
                  failureHandler:failure];
}

- (id)initWithScheduler:(SSVCScheduler *)scheduler
  withCompletionHandler:(ssvc_fetch_success_block_t)success
         failureHandler:(ssvc_fetch_failure_block_t)failure
{
  NSString *urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:SSVCCallbackURLKey];
  return [self initWithScheduler:scheduler
                  forCallbackURL:urlString
           withCompletionHandler:success
                  failureHandler:failure];
}

// Designated initialiser
- (id)initWithScheduler:(SSVCScheduler *)scheduler
         forCallbackURL:(NSString *)url
  withCompletionHandler:(ssvc_fetch_success_block_t)success
         failureHandler:(ssvc_fetch_failure_block_t)failure;
{
  if (self = [super init]) {
    // Setup state
    _dateOfLastVersionCheck = [self __lastVersionCheckDateFromUserDefaults];
    [self __versionFromBundle];
    
    _scheduler = scheduler;
    _success = success;
    _failure = failure;
    
    SSVCURLGenerator *urlGenerator = [[SSVCURLGenerator alloc] initWithBaseURL:url
                                                                    versionKey:_versionKey
                                                                 versionNumber:_versionNumber];
    _callbackURL = [urlGenerator url];
    
    // Run scheduler
    [_scheduler startSchedulingFromLastCheckDate:[self __lastVersionCheckDateFromUserDefaults]];
  }
  return self;
}

#pragma mark - Public instance methods

- (void)checkVersion
{
  SSVCRequestRunner *runner = [[SSVCRequestRunner alloc]
                               initWithCallbackURL:_callbackURL
                               parser:[[SSVCJSONParser alloc] init]
                               scheduler:_scheduler
                               lastCheckDate:[self __lastVersionCheckDateFromUserDefaults]
                               success:_success
                               failure:_failure];
  _scheduler.delegate = runner;
  
  [runner checkVersion];
}

- (SSVCResponse *)lastResponse
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  return (SSVCResponse *)[userDefaults objectForKey:SSVCResponseFromLastVersionCheck];
}

#pragma mark - Private instance methods

- (NSDate *)__lastVersionCheckDateFromUserDefaults
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSDate *lastCheck = (NSDate *)[userDefaults objectForKey:SSVCDateOfLastVersionCheck];
  
  if (!lastCheck) {
    lastCheck = [NSDate distantPast];
  }
  
  return lastCheck;
}

- (void)__versionFromBundle
{
  CFTypeRef ver = CFBundleGetValueForInfoDictionaryKey(
                                                         CFBundleGetMainBundle(),
                                                         kCFBundleVersionKey);
  _versionKey = (__bridge NSString *)ver;
  _versionNumber = [NSNumber numberWithUnsignedInteger:CFBundleGetVersionNumber(CFBundleGetMainBundle())];
}



@end
