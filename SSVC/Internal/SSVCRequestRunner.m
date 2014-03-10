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
    _success = success;
    _failure = failure;
  }
  return self;
}

#pragma mark - Public instance methods

- (void)checkVersion
{
  SSVCURLConnection *connection = [self newConnection];
  
  __weak SSVCRequestRunner *weakSelf = self;
  connection.onComplete = ^(SSVCURLConnection *connection){
    SSVCRequestRunner *strongSelf = weakSelf;
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

- (SSVCURLConnection *)newConnection
{
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:_callbackURL];
  SSVCURLConnection *urlConnection = [[SSVCURLConnection alloc] initWithRequest:urlRequest
                                                                       delegate:self];
  
  return urlConnection;
}

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

- (SSVCResponse *)__buildResponseFromJSONData:(NSData *)responseData error:(NSError **)error
{
  NSDictionary *defaultsDict = [SSVCRequestRunner defaultObjectsDict];
  NSDictionary *json = [_parser parseResponseFromData:responseData
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
