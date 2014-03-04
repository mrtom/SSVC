//
//  SSVC.m
//  SSVC
//
//  Created by Tom Elliott on 3/3/14.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import "SSVC.h"

#import "SSVCResponse.h"
#import "SSVCSchedulerDelegate.h"
#import "SSVCURLConnection.h"

NSString *const SSVCCallbackURLKey = @"SSVCCallbackURLKey";
NSString *const SSVCDateOfLastVersionCheck = @"SSVCDateOfLastVersionCheck";
NSString *const SSVCUpdateAvailable = @"SSVCUpdateAvailable";
NSString *const SSVCUpdateRequired = @"SSVCUpdateRequired";
NSString *const SSVCLatestVersionKey = @"SSVCLatestVersionKey";
NSString *const SSVCLatestVersionNumber = @"SSVCLatestVersionNumber";

NSString *const SSVCClientProtocolVersion = @"SSVCClientProtocolVersion";
NSUInteger const SSVCClientProtocolVersionNumber = 1;

static NSString *const kSSVCResponseFromLastVersionCheck = @"SSVCResponseFromLastVersionCheck";

@interface SSVC() <NSURLConnectionDataDelegate, SSVCSchedulerDelegate>

@property (nonatomic, strong, readonly) SSVCScheduler *scheduler;
@property (nonatomic, assign, readonly) ssvc_fetch_success_block_t success;
@property (nonatomic, assign, readonly) ssvc_fetch_failure_block_t failure;

@property (nonatomic, strong, readonly) NSString *versionKey;
@property (nonatomic, assign, readonly) NSNumber *versionNumber;

@end

@implementation SSVC

- (id)init{
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"Must use initWithCompletionHandler: failureHandler: instead"
                               userInfo:nil];
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
         forCallbackURL:(NSString *)url
  withCompletionHandler:(ssvc_fetch_success_block_t)success
         failureHandler:(ssvc_fetch_failure_block_t)failure;
{
  if (self = [super init]) {
    // Setup state
    _dateOfLastVersionCheck = [self __lastVersionCheckDateFromUserDefaults];
    [self __versionFromBundle];
    
    _scheduler = scheduler;
    _scheduler.delegate = self;
    
    _success = success;
    _failure = failure;
    
    NSRange questionMarkRange = [url rangeOfString:@"?" options:NSBackwardsSearch];
    NSString *seperator = questionMarkRange.location == NSNotFound ? @"?" : @"&";
    
    
    _callbackURL = [NSString stringWithFormat:@"%@%@%@=%@&%@=%@&%@=%@",
                                 url, seperator,
                                 SSVCLatestVersionKey, _versionKey,
                                 SSVCLatestVersionNumber, _versionNumber,
                    SSVCClientProtocolVersion, @(SSVCClientProtocolVersionNumber)];
    
    // Run scheduler
    [_scheduler startSchedulingWithLastVersionDateCheck:[self __lastVersionCheckDateFromUserDefaults]];
  }
  return self;
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

#pragma mark - Public instance methods

- (void)checkVersion
{
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:_callbackURL]];
  
  SSVCURLConnection *urlConnection = [[SSVCURLConnection alloc] initWithRequest:urlRequest
                                                                       delegate:self];
  
  __weak SSVCURLConnection *weakConnection = urlConnection;
  __weak SSVC *weakSelf = self;
  urlConnection.onComplete = ^{
    NSDate *now = [NSDate date];
    NSError *error;
    NSData *responseData = weakConnection.data;
    
    [weakSelf __updateLastCheckDate:now];
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData
                                                         options:kNilOptions
                                                           error:&error];
    
    SSVCResponse *response = [[SSVCResponse alloc] initWithUpdateAvailable:[json[SSVCUpdateAvailable] boolValue]
                                                            updateRequired:[json[SSVCUpdateRequired] boolValue]
                                                          latestVersionKey:json[SSVCLatestVersionKey]
                                                       latestVersionNumber:json[SSVCLatestVersionNumber]];
    
    // Set time of last check in NSUserDefaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:now forKey:SSVCDateOfLastVersionCheck];
    NSData *archivedResponse = [NSKeyedArchiver archivedDataWithRootObject:response];
    [userDefaults setObject:archivedResponse forKey:kSSVCResponseFromLastVersionCheck];
    
    if (error) {
      if (self.failure) {
        dispatch_async(dispatch_get_main_queue(), ^{
          self.failure(error);
        });
      }
    } else {
      if (weakSelf.success) {
        dispatch_async(dispatch_get_main_queue(), ^{
          weakSelf.success(response);
        });
      }
    }
    
    [_scheduler startSchedulingWithLastVersionDateCheck:[self __lastVersionCheckDateFromUserDefaults]];
  };
  urlConnection.onError = ^(NSError *error){
    [weakSelf __updateLastCheckDate:[NSDate date]];
    if (weakSelf.failure) {
      dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.failure(error);
      });
    }
    
    [_scheduler startSchedulingWithLastVersionDateCheck:[self __lastVersionCheckDateFromUserDefaults]];
  };
  
  [urlConnection start];
}

- (SSVCResponse *)lastResponse
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  return (SSVCResponse *)[userDefaults objectForKey:kSSVCResponseFromLastVersionCheck];
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

- (void)__updateLastCheckDate:(NSDate *)lastCheckDate
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:lastCheckDate forKey:SSVCDateOfLastVersionCheck];
}

- (void)__versionFromBundle
{
  CFStringRef ver = CFBundleGetValueForInfoDictionaryKey(
                                                         CFBundleGetMainBundle(),
                                                         kCFBundleVersionKey);
  _versionKey = (__bridge NSString *)ver;
  _versionNumber = [NSNumber numberWithUnsignedInteger:CFBundleGetVersionNumber(CFBundleGetMainBundle())];
}

#pragma mark - NSURLConnectionDataDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  ((SSVCURLConnection *)connection).data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [((SSVCURLConnection *)connection).data  appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
  return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
  dispatch_async(q, ^{
    ((SSVCURLConnection *)connection).onComplete();
  });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  ((SSVCURLConnection *)connection).onError(error);
}

#pragma mark - SSVCSchedulerDelegate methods

- (void)periodElapsedForScheduler:(SSVCScheduler *)scheduler
{
  [self checkVersion];
}


@end
