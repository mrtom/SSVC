//
//  SSVC.m
//  SSVC
//
//  Created by Tom Elliott on 3/3/14.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import "SSVC.h"

static NSString *const kSSVCDateOfLastVersionCheck = @"SSVCDateOfLastVersionCheck";
NSString *const SSVCCallbackURLKey = @"SSVCCallbackURLKey";

@interface SSVC()

@property (nonatomic, strong) NSString *versionKey;
@property (nonatomic, assign) UInt32 versionNumber;

@end

@implementation SSVC


- (id)init
{
  NSString *urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:SSVCCallbackURLKey];
  return [self initWithCallbackURL:[NSURL URLWithString:urlString]];
}

// Designated initialiser
- (id)initWithCallbackURL:(NSURL *)url
{
  if (self = [super init]) {
    _callbackURL = url;
    _dateOfLastVersionCheck = [self __lastVersionCheckDateFromUserDefaults];
  }
  return self;
}

#pragma mark - Public instance methods

- (void)checkVersionWithCompletionHandler:(ssvc_fetch_success_block_t)success
                           failureHandler:(ssvc_fetch_failure_block_t)failure
{
  
}

#pragma mark - Private instance methods

- (NSDate *) __lastVersionCheckDateFromUserDefaults
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSDate *lastCheck = (NSDate *)[userDefaults objectForKey:kSSVCDateOfLastVersionCheck];

  if (!lastCheck) {
    lastCheck = [NSDate distantPast];
  }
  
  return lastCheck;
}

- (void)__pullVersionFromBundle
{
  CFStringRef ver = CFBundleGetValueForInfoDictionaryKey(
                                                         CFBundleGetMainBundle(),
                                                         kCFBundleVersionKey);
  _versionKey = (__bridge NSString *)ver;
  _versionNumber = CFBundleGetVersionNumber(CFBundleGetMainBundle());
}

@end
