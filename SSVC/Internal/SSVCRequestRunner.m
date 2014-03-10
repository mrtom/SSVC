//
//  SSVCRequestRunner.m
//  SSVC
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import "SSVCRequestRunner.h"

#import "SSVC.h"
#import "SSVCResponse.h"
#import "SSVCResponseParserProtocol.h"

BOOL const kSSVCDefaultUpdateAvailable = NO;
BOOL const kSSVCDefaultUpdateRequired = NO;
NSString *const kSSVCDefaultLatestVersionKey = @"0.0.0";

@interface SSVCRequestRunner() <NSURLConnectionDataDelegate>

@property (nonatomic, strong, readonly) NSURL *callbackURL;
@property (nonatomic, strong, readonly) id<SSVCResponseParserProtocol>parser;
@property (nonatomic, strong, readonly) SSVCScheduler *scheduler;
@property (nonatomic, strong, readonly) NSDate *lastCheckDate;
@property (nonatomic, copy, readonly) ssvc_fetch_success_block_t success;
@property (nonatomic, copy, readonly) ssvc_fetch_failure_block_t failure;

@end

@implementation SSVCRequestRunner

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

- (id)init{
  @throw  [NSException exceptionWithName:NSInternalInconsistencyException
                                  reason:@"Must use initWithURLRequest:... instead"
                                userInfo:nil];
}

// Designated initialiser
- (id)initWithCallbackURL:(NSURL *)callback
                parser:(id<SSVCResponseParserProtocol>)parser
               scheduler:(SSVCScheduler *)scheduler
           lastCheckDate:(NSDate *)lastCheckDate
                 success:(ssvc_fetch_success_block_t)success
                 failure:(ssvc_fetch_failure_block_t)failure;
{
  if (self = [super init]) {
    _callbackURL = callback;
    _parser = parser;
    _scheduler = scheduler;
    _lastCheckDate = lastCheckDate;
    _success = [success copy];
    _failure = [failure copy];
  }
  return self;
}

#pragma mark - Public instance methods

- (void)checkVersion
{
  SSVCURLConnection *connection = [self __newConnection];
  
  __weak SSVCRequestRunner *weakSelf = self;
  connection.onComplete = ^(SSVCURLConnection *connection){
    SSVCRequestRunner *strongSelf = weakSelf;
    if (strongSelf) {
      NSDate *now = [NSDate date];
      NSError *error = nil;
      NSData *responseData = connection.data;
      
      [strongSelf __updateLastCheckDate:now];
      SSVCResponse *response = [strongSelf __buildResponseFromJSONData:responseData error:&error];
      [strongSelf __performCallbacksWithResponse:response error:error];
      [strongSelf __restartScheduler];
    }
  };
  connection.onError = ^(NSError *error){
    SSVCRequestRunner *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf __updateLastCheckDate:[NSDate date]];
      [strongSelf __performCallbacksWithResponse:nil error:error];
      [strongSelf __restartScheduler];
    }
  };
  
  [connection start];
}

#pragma mark - Private instance methods

- (SSVCURLConnection *)__newConnection
{
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:_callbackURL];
  SSVCURLConnection *urlConnection = [[SSVCURLConnection alloc] initWithRequest:urlRequest
                                                                       delegate:self];
  
  return urlConnection;
}

- (void)__performCallbacksWithResponse:(SSVCResponse *)response error:(NSError *)error
{
  if (!response) {
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
  [_scheduler startSchedulingFromLastCheckDate:_lastCheckDate];
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

- (SSVCResponse *)__buildResponseFromJSONData:(NSData *)responseData error:(NSError * __autoreleasing *)error
{
  SSVCResponse *response = nil;
  
  NSDictionary *defaultsDict = [SSVCRequestRunner defaultObjectsDict];
  NSDictionary *json = [_parser parseResponseFromData:responseData
                                                error:error];
  
  if (json) {
    NSNumber *updateAvailableSinceTime = [json objectForKey:SSVCUpdateAvailableSince];
    NSDate *updateAvailableSinceDate;
    if (updateAvailableSinceTime) {
      updateAvailableSinceDate = [NSDate dateWithTimeIntervalSince1970:[updateAvailableSinceTime integerValue]];
    } else {
      updateAvailableSinceDate = defaultsDict[SSVCUpdateAvailableSince];
    }
    
    NSString *latestVersionKey = json[SSVCLatestVersionKey] ?: kSSVCDefaultLatestVersionKey;
    NSNumber *latestVersionNumber = json[SSVCLatestVersionNumber] ?: defaultsDict[SSVCLatestVersionNumber];
    
    // Determine if update is available:
    BOOL updateAvailable = [self __calculateIfUpdateAvailableForVersionKey:latestVersionKey versionNumber:latestVersionNumber];
    BOOL updateRequired = kSSVCDefaultUpdateRequired; // FIXME: TODO
    
    response = [[SSVCResponse alloc] initWithUpdateAvailable:updateAvailable
                                                            updateRequired:updateRequired
                                                      updateAvailableSince:updateAvailableSinceDate
                                                          latestVersionKey:latestVersionKey
                                                       latestVersionNumber:latestVersionNumber];
    
  }
  return response;
}

- (BOOL)__calculateIfUpdateAvailableForVersionKey:(NSString *)versionKey versionNumber:(NSNumber *)versionNumber
{
  NSDictionary *defaultsDict = [SSVCRequestRunner defaultObjectsDict];
  BOOL updateAvailable;
  
  if (![versionNumber isEqual:defaultsDict[SSVCLatestVersionNumber]]) {
    NSNumber *currentVersionNumber = [NSNumber numberWithUnsignedInteger:CFBundleGetVersionNumber(CFBundleGetMainBundle())];
    NSComparisonResult result = [versionNumber compare:currentVersionNumber];
    
    if (result == NSOrderedDescending) {
      updateAvailable = YES;
    } else {
      updateAvailable = NO;
    }
  } else if(![versionKey isEqualToString:kSSVCDefaultLatestVersionKey]) {
    CFTypeRef ver = CFBundleGetValueForInfoDictionaryKey(
                                                         CFBundleGetMainBundle(),
                                                         kCFBundleVersionKey);
    NSString *currentVersionKey = (__bridge NSString *)ver;
    NSComparisonResult result = [versionKey compare:currentVersionKey];
    
    if (result == NSOrderedDescending) {
      updateAvailable = YES;
    } else {
      updateAvailable = NO;
    }
  } else {
    NSLog(@"Error: Attempting to check if new version is available without a version number of a version key. Setting to default");
    updateAvailable = kSSVCDefaultUpdateAvailable;
  }
  
  return updateAvailable;
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
    if (c.onComplete) {
      c.onComplete(c);
      c.onComplete = nil;
    }
  });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  SSVCURLConnection *c = (SSVCURLConnection *)connection;
  if (c.onError) {
    c.onError(error);
    c.onError = nil;
  }
}

#pragma mark - SSVCSchedulerDelegate methods

- (void)periodElapsedForScheduler:(SSVCScheduler *)scheduler
{
  [self checkVersion];
}

@end
