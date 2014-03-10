//
//  SSVCRequestRunnerTests.m
//  SSVC
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "SSVCJSONParser.h"
#import "SSVCRequestRunner.h"
#import "SSVCRequestRunner_Internal.h"
#import "SSVCURLConnection.h"
#import "SSVCResponseParserProtocol.h"

@interface SSVCRequestRunnerTests : XCTestCase

@end

@implementation SSVCRequestRunnerTests

- (void)setUp
{
  [super setUp];
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testSuccessBlockIsCalledAfterSuccessfulVersionFetch
{
  
}

- (void)testFailureBlockIsCalledAfterUnsuccessfulVersionFetch
{
  
}

- (void)testFailureBlockIsCalledAfterUnsuccessfulJSONParse
{
  NSError *error = [[NSError alloc] init];
  NSData*data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
  
  id mockJSONParser = [OCMockObject mockForProtocol:@protocol(SSVCResponseParserProtocol)];
  [[[mockJSONParser stub] andReturn:nil] parseResponseFromData:data error:&error];
  
  __block BOOL waitingForBlock = YES;
  __block BOOL failureBlockCalled = NO;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    XCTFail(@"Success block should not be called");
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    failureBlockCalled = YES;
    waitingForBlock = NO;
  };
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:[NSURL URLWithString:@"foo"]
                                                                      parser:mockJSONParser
                                                              scheduler:nil
                                                          lastCheckDate:[NSDate distantPast]
                                                                success:success
                                                                failure:failure];
  
  SSVCURLConnection *connection = [[SSVCURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:nil] delegate:runner];
  id connectionMock = [OCMockObject partialMockForObject:connection];
  [[connectionMock stub] start];

  id runnerMock = [OCMockObject partialMockForObject:runner];
  [[[runnerMock stub] andReturn:connectionMock] __newConnection];
  
  // Run code
  [runnerMock checkVersion];
  
  // Fake response from mock SSVCURLConnection
  int statusCode = 200;
  id responseMock = [OCMockObject mockForClass:[NSHTTPURLResponse class]];
  [[[responseMock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];

  [runner connection:connectionMock didReceiveResponse:responseMock];
  [runner connection:connectionMock didReceiveData:data];
  [runner connectionDidFinishLoading:connectionMock];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  XCTAssertTrue(failureBlockCalled, @"Failure block must be called for this test to pass");
}

- (void)testLastResponseIsCorrectlySavedToNSUserDefaultsAfterSuccessfulFetch
{
  
}

- (void)testSavedResponseIsNotUpdatedAfterUnsuccessfulFetch
{
  
}

- (void)testLastVersionCheckDateIsSavedToNSUserDefaults
{
  
}

@end
