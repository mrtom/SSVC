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

@interface SSVCRequestRunner() <NSURLConnectionDataDelegate>

@property (nonatomic, strong, readonly) NSURL *callbackURL;
@property (nonatomic, strong, readonly) id<SSVCResponseParserProtocol>parser;
@property (nonatomic, strong, readonly) SSVCScheduler *scheduler;
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
                    SSVCLatestVersionAvailableSince: [NSDate distantPast]
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
                 success:(ssvc_fetch_success_block_t)success
                 failure:(ssvc_fetch_failure_block_t)failure;
{
  if (self = [super init]) {
    _callbackURL = callback;
    _parser = parser;
    _scheduler = scheduler;
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
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [strongSelf __restartScheduler];
      });
    }
  };
  connection.onError = ^(NSError *error){
    SSVCRequestRunner *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf __updateLastCheckDate:[NSDate date]];
      [strongSelf __performCallbacksWithResponse:nil error:error];
      dispatch_async(dispatch_get_main_queue(), ^{
        [strongSelf __restartScheduler];
      });
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
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSDate *lastCheckDate = [userDefaults objectForKey:SSVCDateOfLastVersionCheck];
  
  [_scheduler startSchedulingFromLastCheckDate:lastCheckDate];
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
    NSNumber *minimumSupportedVersionNumber = json[SSVCMinimumSupportedVersionNumber] ?: @(SSVCNoMinimumSupportedVersionNumber);
    
    NSNumber *updateAvailableSinceTime = [json objectForKey:SSVCLatestVersionAvailableSince];
    NSDate *updateAvailableSinceDate;
    if (updateAvailableSinceTime) {
      updateAvailableSinceDate = [NSDate dateWithTimeIntervalSince1970:[updateAvailableSinceTime integerValue]];
    } else {
      updateAvailableSinceDate = defaultsDict[SSVCLatestVersionAvailableSince];
    }
    
    NSString *latestVersionKey = json[SSVCLatestVersionKey] ?: SSVCNoVersionKey;
    NSNumber *latestVersionNumber = json[SSVCLatestVersionNumber] ?: @(SSVCNoVersionNumber);
    
    // Determine if update is available/required:
    BOOL updateAvailable = [self __calculateIfUpdateAvailableForVersionKey:latestVersionKey versionNumber:latestVersionNumber];
    BOOL updateRequired = [self __calculateIfUpdateRequiredWithMinimumSupportedVersionNumber:minimumSupportedVersionNumber];
    
    response = [[SSVCResponse alloc] initWithUpdateAvailable:updateAvailable
                                                            updateRequired:updateRequired
                                             minimumSupportedVersionNumber:minimumSupportedVersionNumber
                                                      updateAvailableSince:updateAvailableSinceDate
                                                          latestVersionKey:latestVersionKey
                                                       latestVersionNumber:latestVersionNumber];
    
  }
  return response;
}

- (BOOL)__calculateIfUpdateAvailableForVersionKey:(NSString *)versionKey versionNumber:(NSNumber *)versionNumber
{
  BOOL updateAvailable;
  
  if (![versionNumber isEqualToNumber:@(SSVCNoVersionNumber)]) {
    NSNumber *currentVersionNumber = [NSNumber numberWithUnsignedInteger:CFBundleGetVersionNumber(CFBundleGetMainBundle())];
    NSComparisonResult result = [versionNumber compare:currentVersionNumber];
    
    if (result == NSOrderedDescending) {
      updateAvailable = YES;
    } else {
      updateAvailable = NO;
    }
  } else if(![versionKey isEqualToString:SSVCNoVersionKey]) {
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

- (BOOL)__calculateIfUpdateRequiredWithMinimumSupportedVersionNumber:(NSNumber *)minimumSupportedVersionNumber
{
  BOOL updateRequired;
  
  if (![minimumSupportedVersionNumber isEqualToNumber:@(SSVCNoMinimumSupportedVersionNumber)]) {
    NSNumber *currentVersionNumber = [NSNumber numberWithUnsignedInteger:CFBundleGetVersionNumber(CFBundleGetMainBundle())];
    NSComparisonResult result = [minimumSupportedVersionNumber compare:currentVersionNumber];
    
    if (result == NSOrderedDescending) {
      updateRequired = YES;
    } else {
      updateRequired = NO;
    }
  } else {
    NSLog(@"Error: Attempting to check if new version is available without a version number of a version key. Setting to default");
    updateRequired = kSSVCDefaultUpdateRequired;
  }
  
  return updateRequired;
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

@end
