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

// Names for keys
NSString *const SSVCCallbackURLKey = @"SSVCCallbackURLKey";
NSString *const SSVCDateOfLastVersionCheck = @"SSVCDateOfLastVersionCheck";
NSString *const SSVCUpdateAvailable = @"SSVCUpdateAvailable";
NSString *const SSVCUpdateRequired = @"SSVCUpdateRequired";
NSString *const SSVCUpdateAvailableSince = @"SSVCUpdateAvailableSince";
NSString *const SSVCLatestVersionKey = @"SSVCLatestVersionKey";
NSString *const SSVCLatestVersionNumber = @"SSVCLatestVersionNumber";

BOOL const kSSVCDefaultUpdateAvailable = NO;
BOOL const kSSVCDefaultUpdateRequired = NO;
NSDate *kSSVCDefaultUpdateAvailableSinceDate = nil;
NSString *const kSSVCDefaultLatestVersionKey = @"0.0";
NSNumber *kSSVCDefaultLatestVersionNumber = nil;

NSString *const SSVCClientProtocolVersion = @"SSVCClientProtocolVersion";
NSUInteger const SSVCClientProtocolVersionNumber = 1;

static NSString *const kSSVCResponseFromLastVersionCheck = @"SSVCResponseFromLastVersionCheck";

@interface SSVC() <NSURLConnectionDataDelegate, SSVCSchedulerDelegate>

@property (nonatomic, copy, readonly) SSVCScheduler *scheduler;
@property (nonatomic, copy, readonly) ssvc_fetch_success_block_t success;
@property (nonatomic, copy, readonly) ssvc_fetch_failure_block_t failure;

@property (nonatomic, copy, readonly) NSString *versionKey;
@property (nonatomic, copy, readonly) NSNumber *versionNumber;

@end

@implementation SSVC

+ (void)initialize
{
  if (!kSSVCDefaultUpdateAvailableSinceDate) kSSVCDefaultUpdateAvailableSinceDate = [NSDate distantPast];
  if (!kSSVCDefaultLatestVersionNumber) kSSVCDefaultLatestVersionNumber = @0;
}

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
    SSVC *strongSelf = weakSelf;
    if (strongSelf) {
      NSDate *now = [NSDate date];
      NSError *error;
      NSData *responseData = weakConnection.data;
      
      [strongSelf __updateLastCheckDate:now];
      
      NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData
                                                           options:kNilOptions
                                                             error:&error];
      
      BOOL updateAvailable = [json objectForKey:SSVCUpdateAvailable] ? [[json objectForKey:SSVCUpdateAvailable] boolValue] : kSSVCDefaultUpdateAvailable;
      BOOL updateRequired = [json objectForKey:SSVCUpdateRequired] ? [[json objectForKey:SSVCUpdateRequired] boolValue] : kSSVCDefaultUpdateRequired;
      
      NSNumber *updateAvailableSinceTime = [json objectForKey:SSVCUpdateAvailableSince];
      NSDate *updateAvailableSinceDate;
      if (updateAvailableSinceTime) {
        updateAvailableSinceDate = [NSDate dateWithTimeIntervalSince1970:[updateAvailableSinceTime unsignedIntegerValue]];
      } else {
        updateAvailableSinceDate = [NSDate distantPast];
      }
      
      NSString *latestVersionKey = json[SSVCLatestVersionKey] ?: @"";
      NSNumber *latestVersionNumber = json[SSVCLatestVersionNumber] ?: @0;
      
      SSVCResponse *response = [[SSVCResponse alloc] initWithUpdateAvailable:updateAvailable
                                                              updateRequired:updateRequired
                                                        updateAvailableSince:updateAvailableSinceDate
                                                            latestVersionKey:latestVersionKey
                                                         latestVersionNumber:latestVersionNumber];
      
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
        if (strongSelf.success) {
          dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.success(response);
          });
        }
      }
      
      [_scheduler startSchedulingWithLastVersionDateCheck:[self __lastVersionCheckDateFromUserDefaults]];      
    }
  };
  urlConnection.onError = ^(NSError *error){
    SSVC *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf __updateLastCheckDate:[NSDate date]];
      if (strongSelf.failure) {
        dispatch_async(dispatch_get_main_queue(), ^{
          strongSelf.failure(error);
        });
      }
      
      [_scheduler startSchedulingWithLastVersionDateCheck:[self __lastVersionCheckDateFromUserDefaults]];
    }
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
  CFTypeRef ver = CFBundleGetValueForInfoDictionaryKey(
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
