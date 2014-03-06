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
NSString *const SSVCCallbackURLKey = @"SSVCCallbackURL";
NSString *const SSVCDateOfLastVersionCheck = @"SSVCDateOfLastVersionCheck";
NSString *const SSVCUpdateAvailable = @"SSVCUpdateAvailable";
NSString *const SSVCUpdateRequired = @"SSVCUpdateRequired";
NSString *const SSVCUpdateAvailableSince = @"SSVCUpdateAvailableSince";
NSString *const SSVCLatestVersionKey = @"SSVCLatestVersionKey";
NSString *const SSVCLatestVersionNumber = @"SSVCLatestVersionNumber";

NSString *const SSVCResponseFromLastVersionCheck = @"SSVCResponseFromLastVersionCheck";

BOOL const kSSVCDefaultUpdateAvailable = NO;
BOOL const kSSVCDefaultUpdateRequired = NO;
NSString *const kSSVCDefaultLatestVersionKey = @"0.0.0";

NSString *const SSVCClientProtocolVersion = @"SSVCClientProtocolVersion";
NSUInteger const SSVCClientProtocolVersionNumber = 1;

@interface SSVC() <NSURLConnectionDataDelegate, SSVCSchedulerDelegate>

@property (nonatomic, copy, readonly) SSVCScheduler *scheduler;
@property (nonatomic, copy, readonly) ssvc_fetch_success_block_t success;
@property (nonatomic, copy, readonly) ssvc_fetch_failure_block_t failure;

@property (nonatomic, copy, readonly) NSString *versionKey;
@property (nonatomic, copy, readonly) NSNumber *versionNumber;

@end

@implementation SSVC

#pragma mark - Defaults

+ (NSDictionary *)defaultObjectsDict
{
  static NSDictionary *defaultDict = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultDict = @{
                    SSVCUpdateAvailableSince: [NSDate distantPast],
                    SSVCLatestVersionNumber: @0
                    };
  });
  return defaultDict;
}

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
    [_scheduler startSchedulingFromLastCheckDate:[self __lastVersionCheckDateFromUserDefaults]];
  }
  return self;
}

#pragma mark - Public instance methods

- (void)checkVersion
{
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:_callbackURL]];
  
  SSVCURLConnection *urlConnection = [[SSVCURLConnection alloc] initWithRequest:urlRequest
                                                                       delegate:self];
  
  __weak SSVC *weakSelf = self;
  urlConnection.onComplete = ^(SSVCURLConnection *connection){
    SSVC *strongSelf = weakSelf;
    if (strongSelf) {
      NSDate *now = [NSDate date];
      NSError *error;
      NSData *responseData = connection.data;
      
      [strongSelf __updateLastCheckDate:now];
      SSVCResponse *response = [strongSelf __buildResponseFromJSONData:responseData error:&error];
      [strongSelf __performCallbacksWithResponse:response error:error];
      [strongSelf __restartScheduler];
    }
  };
  urlConnection.onError = ^(NSError *error){
    SSVC *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf __updateLastCheckDate:[NSDate date]];
      [strongSelf __performCallbacksWithResponse:nil error:error];
      [strongSelf __restartScheduler];
    }
  };
  
  [urlConnection start];
}

- (SSVCResponse *)lastResponse
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  return (SSVCResponse *)[userDefaults objectForKey:SSVCResponseFromLastVersionCheck];
}

#pragma mark - Private instance methods

- (void)__performCallbacksWithResponse:(SSVCResponse *)response error:(NSError *)error
{
  if (error) {
    if (_failure) {
      _failure(error);
    }
  } else {
    if (self.success) {
      [self __archiveResponse:response];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        self.success(response);
      });
    }
  }
}

- (void)__restartScheduler
{
  [_scheduler startSchedulingFromLastCheckDate:[self __lastVersionCheckDateFromUserDefaults]];
}

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

- (void)__archiveResponse:(SSVCResponse *)response
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSData *archivedResponse = [NSKeyedArchiver archivedDataWithRootObject:response];
  [userDefaults setObject:archivedResponse forKey:SSVCResponseFromLastVersionCheck];
}

- (SSVCResponse *)__buildResponseFromJSONData:(NSData *)responseData error:(NSError **)error
{
  NSDictionary *defaultsDict = [SSVC defaultObjectsDict];
  NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData
                                                       options:kNilOptions
                                                         error:error];
  
  BOOL updateAvailable = [json objectForKey:SSVCUpdateAvailable] ? [[json objectForKey:SSVCUpdateAvailable] boolValue] : kSSVCDefaultUpdateAvailable;
  BOOL updateRequired = [json objectForKey:SSVCUpdateRequired] ? [[json objectForKey:SSVCUpdateRequired] boolValue] : kSSVCDefaultUpdateRequired;
  
  NSNumber *updateAvailableSinceTime = [json objectForKey:SSVCUpdateAvailableSince];
  NSDate *updateAvailableSinceDate;
  if (updateAvailableSinceTime) {
    updateAvailableSinceDate = [NSDate dateWithTimeIntervalSince1970:[updateAvailableSinceTime unsignedIntegerValue]];
  } else {
    updateAvailableSinceDate = defaultsDict[SSVCUpdateAvailableSince];
  }
  
  NSString *latestVersionKey = json[SSVCLatestVersionKey] ?: kSSVCDefaultLatestVersionKey;
  NSNumber *latestVersionNumber = json[SSVCLatestVersionNumber] ?: defaultsDict[SSVCLatestVersionNumber];
  
  SSVCResponse *response = [[SSVCResponse alloc] initWithUpdateAvailable:updateAvailable
                                                          updateRequired:updateRequired
                                                    updateAvailableSince:updateAvailableSinceDate
                                                        latestVersionKey:latestVersionKey
                                                     latestVersionNumber:latestVersionNumber];
  
  return response;
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
    SSVCURLConnection *c = (SSVCURLConnection *)connection;
    c.onComplete(c);
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
