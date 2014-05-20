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
#import "SSVCURLConnection.h"
#import "SSVCResponseParserProtocol.h"

static NSString *const kInvalidResponse = @"invalidResponse";
static NSString *const kValidFullResponse = @"validFullResponse";
static NSString *const kValidFullResponse2 = @"validFullResponse2";

static NSString *const kValidResponseNoMinimumSupportedVersion = @"validResponseNoMinimumSupportedVersion";
static NSString *const kValidResponseNoAvailableSince = @"validResponseNoAvailableSince";
static NSString *const kValidResponseNoVersionKey = @"validResponseNoVersionKey";
static NSString *const kValidResponseNoVersionNumber = @"validResponseNoVersionNumber";

@interface SSVCRequestRunnerTests : XCTestCase

@end

@implementation SSVCRequestRunnerTests

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testSuccessBlockIsCalledAfterSuccessfulVersionFetch
{
  __block BOOL waitingForBlock = YES;
  __block BOOL successBlockCalled = NO;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    successBlockCalled = YES;
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    XCTFail(@"Failure block should not be called");
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kValidFullResponse withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:[SSVCJSONParser new]
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  XCTAssertTrue(successBlockCalled, @"Success block must be called for this test to pass");
}

- (void)testFailureBlockIsCalledAfterUnsuccessfulVersionFetch
{
  __block BOOL waitingForBlock = YES;
  __block BOOL failureBlockCalled = NO;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    XCTFail(@"Success block should not be called");
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    XCTAssertNotNil(error, @"Error should not be nil if there's a failure");
    failureBlockCalled = YES;
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:@"I_DO_NOT_EXIST" withExtension:@"kittens"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:[SSVCJSONParser new]
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  XCTAssertTrue(failureBlockCalled, @"Failure block must be called for this test to pass");
}

- (void)testFailureBlockIsCalledAfterUnsuccessfulJSONParse
{
  id mockJSONParser = [OCMockObject mockForProtocol:@protocol(SSVCResponseParserProtocol)];
  [[[mockJSONParser stub] andReturn:nil] parseResponseFromData:[OCMArg any] error:((NSError * __autoreleasing *)[OCMArg anyPointer])];
  
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
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kValidFullResponse withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:mockJSONParser
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  XCTAssertTrue(failureBlockCalled, @"Failure block must be called for this test to pass");
}

- (void)testLastResponseIsCorrectlySavedToNSUserDefaultsAfterSuccessfulFetch
{
  __block BOOL waitingForBlock = YES;
  __block BOOL successBlockCalled = NO;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *archivedResponseData = [userDefaults objectForKey:SSVCResponseFromLastVersionCheck];
    SSVCResponse *archivedResponse = [NSKeyedUnarchiver unarchiveObjectWithData:archivedResponseData];
    
    XCTAssertEqualObjects(archivedResponse, response, @"The returned response should be equal to the archived response");
    
    successBlockCalled = YES;
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    XCTFail(@"Failure block should not be called");
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kValidFullResponse withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:[SSVCJSONParser new]
                                                   scheduler:nil                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
}

- (void)testSavedResponseIsNotUpdatedAfterUnsuccessfulFetch
{
  id mockJSONParser = [OCMockObject mockForProtocol:@protocol(SSVCResponseParserProtocol)];
  [[[mockJSONParser stub] andReturn:nil] parseResponseFromData:[OCMArg any] error:((NSError * __autoreleasing *)[OCMArg anyPointer])];
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  id savedResponseBefore = [userDefaults objectForKey:SSVCResponseFromLastVersionCheck];
  
  __block BOOL waitingForBlock = YES;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    XCTFail(@"Success block should not be called");
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kInvalidResponse withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:mockJSONParser
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  
  id savedResponseAfter = [userDefaults objectForKey:SSVCResponseFromLastVersionCheck];
  
  XCTAssertEqual(savedResponseBefore, savedResponseAfter, @"Response should not be saved after unsuccessful fetch");
}

- (void)testLastVersionCheckDateIsUpdatedAfterUnsuccessfulFetch
{
  id mockJSONParser = [OCMockObject mockForProtocol:@protocol(SSVCResponseParserProtocol)];
  [[[mockJSONParser stub] andReturn:nil] parseResponseFromData:[OCMArg any] error:((NSError * __autoreleasing *)[OCMArg anyPointer])];
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  id dateBefore = [userDefaults objectForKey:SSVCDateOfLastVersionCheck];
  
  __block BOOL waitingForBlock = YES;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    XCTFail(@"Success block should not be called");
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kInvalidResponse withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:mockJSONParser
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  
  id dateAfter = [userDefaults objectForKey:SSVCDateOfLastVersionCheck];
  
  XCTAssertNotEqual(dateBefore, dateAfter, @"Response should not be saved after unsuccessful fetch. Before: %@, after: %@", dateBefore, dateAfter);
  XCTAssertNotNil(dateAfter, @"Date should be set after unsuccessful fetch");
}

- (void)testLastVersionCheckDateIsSavedToNSUserDefaults
{
  __block BOOL waitingForBlock = YES;
  __block BOOL successBlockCalled = NO;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSDate *now = [NSDate date];
    NSDate *lastCheckDate = [userDefaults objectForKey:SSVCDateOfLastVersionCheck];
    NSTimeInterval timeDifference = [lastCheckDate timeIntervalSinceDate:now];
    
    XCTAssertTrue(timeDifference < 1, @"Last check date should have been updated recently. Now: %@, last check date: %@", now, lastCheckDate);
    
    successBlockCalled = YES;
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    XCTFail(@"Failure block should not be called");
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kValidFullResponse withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:[SSVCJSONParser new]
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
}

// TODO: Test more like this, for the range of expected values
- (void)testValidFullResponseContainsExpectedValues
{
  __block BOOL waitingForBlock = YES;
  __block BOOL successBlockCalled = NO;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    XCTAssertEqualObjects(response.minimumSupportedVersionNumber, @16809984, @"Minimum supported version number should be \"16809984\"");
    XCTAssertEqualObjects(@(response.updateAvailable), @YES, @"An update should be marked as available");
    XCTAssertEqualObjects(@(response.updateRequired), @YES, @"An update is required");
    XCTAssertEqualObjects(response.updateAvailableSince, [NSDate dateWithTimeIntervalSince1970:1388750400], @"The update available since date should be since timestamp 1388750400");
    XCTAssertEqualObjects(response.versionKey, @"1.0", @"Version key should be \"1.0\"");
    XCTAssertEqualObjects(response.versionNumber, @16809984, @"Version number should be \"16809984\"");
    
    successBlockCalled = YES;
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    XCTFail(@"Failure block should not be called");
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kValidFullResponse withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:[SSVCJSONParser new]
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  XCTAssertTrue(successBlockCalled, @"Success block must be called for this test to pass");
}

// Minimum supported version number explicitly set to 0
- (void)testValidFullResponse2ContainsExpectedValues
{
  __block BOOL waitingForBlock = YES;
  __block BOOL successBlockCalled = NO;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    XCTAssertEqualObjects(response.minimumSupportedVersionNumber, @0, @"Minimum supported version number should be \"0\"");
    XCTAssertEqualObjects(@(response.updateAvailable), @YES, @"An update should be marked as available");
    XCTAssertEqualObjects(@(response.updateRequired), @NO, @"An update is not required");
    XCTAssertEqualObjects(response.updateAvailableSince, [NSDate dateWithTimeIntervalSince1970:1388750400], @"The update available since date should be since timestamp 1388750400");
    XCTAssertEqualObjects(response.versionKey, @"1.0", @"Version key should be \"1.0\"");
    XCTAssertEqualObjects(response.versionNumber, @16809984, @"Version number should be \"16809984\"");
    
    successBlockCalled = YES;
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    XCTFail(@"Failure block should not be called");
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kValidFullResponse2 withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:[SSVCJSONParser new]
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  XCTAssertTrue(successBlockCalled, @"Success block must be called for this test to pass");
}

// Does not cotain minimum supported version number
- (void)testValidResponseNoMinimumSupportedVersionContainsExpectedValues
{
  __block BOOL waitingForBlock = YES;
  __block BOOL successBlockCalled = NO;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    XCTAssertEqualObjects(response.minimumSupportedVersionNumber, @(SSVCNoMinimumSupportedVersionNumber), @"Minimum supported version number should be \"0\"");
    XCTAssertEqualObjects(@(response.updateAvailable), @YES, @"An update should be marked as available");
    XCTAssertEqualObjects(@(response.updateRequired), @NO, @"An update is not required");
    XCTAssertEqualObjects(response.updateAvailableSince, [NSDate dateWithTimeIntervalSince1970:1388750400], @"The update available since date should be since timestamp 1388750400");
    XCTAssertEqualObjects(response.versionKey, @"1.0", @"Version key should be \"1.0\"");
    XCTAssertEqualObjects(response.versionNumber, @16809984, @"Version number should be \"16809984\"");
    
    successBlockCalled = YES;
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    XCTFail(@"Failure block should not be called");
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kValidResponseNoMinimumSupportedVersion withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:[SSVCJSONParser new]
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  XCTAssertTrue(successBlockCalled, @"Success block must be called for this test to pass");
}

- (void)testValidResponseNoAvailableSinceContainsExpectedValues
{
  __block BOOL waitingForBlock = YES;
  __block BOOL successBlockCalled = NO;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    XCTAssertEqualObjects(response.minimumSupportedVersionNumber, @16809984, @"Minimum supported version number should be \"16809984\"");
    XCTAssertEqualObjects(@(response.updateAvailable), @YES, @"An update  be marked as available");
    XCTAssertEqualObjects(@(response.updateRequired), @YES, @"An update is required");
    XCTAssertEqualObjects(response.updateAvailableSince, [NSDate distantPast], @"The update available since date should be in the distant past");
    XCTAssertEqualObjects(response.versionKey, @"1.0", @"Version key should be \"1.0\"");
    XCTAssertEqualObjects(response.versionNumber, @16809984, @"Version number should be \"16809984\"");
    
    successBlockCalled = YES;
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    XCTFail(@"Failure block should not be called");
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kValidResponseNoAvailableSince withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:[SSVCJSONParser new]
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  XCTAssertTrue(successBlockCalled, @"Success block must be called for this test to pass");
}

- (void)testValidResponseNoVersionKeyContainsExpectedValues
{
  __block BOOL waitingForBlock = YES;
  __block BOOL successBlockCalled = NO;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    XCTAssertEqualObjects(response.minimumSupportedVersionNumber, @16809984, @"Minimum supported version number should be \"16809984\"");
    XCTAssertEqualObjects(@(response.updateAvailable), @YES, @"An update should be marked as available");
    XCTAssertEqualObjects(@(response.updateRequired), @YES, @"An update is required");
    XCTAssertEqualObjects(response.updateAvailableSince, [NSDate dateWithTimeIntervalSince1970:1388750400], @"The update available since date should be since timestamp 1388750400");
    XCTAssertEqualObjects(response.versionKey, SSVCNoVersionKey, @"Version key should be \"%@\"", SSVCNoVersionKey);
    XCTAssertEqualObjects(response.versionNumber, @16809984, @"Version number should be \"16809984\"");
    
    successBlockCalled = YES;
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    XCTFail(@"Failure block should not be called");
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kValidResponseNoVersionKey withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:[SSVCJSONParser new]
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  XCTAssertTrue(successBlockCalled, @"Success block must be called for this test to pass");
}

- (void)testValidResponseNoVersionNumberContainsExpectedValues
{
  __block BOOL waitingForBlock = YES;
  __block BOOL successBlockCalled = NO;
  
  ssvc_fetch_success_block_t success = ^(SSVCResponse *response) {
    XCTAssertEqualObjects(response.minimumSupportedVersionNumber, @16809984, @"Minimum supported version number should be \"16809984\"");
    XCTAssertEqualObjects(@(response.updateAvailable), @YES, @"An update should be marked as available");
    XCTAssertEqualObjects(@(response.updateRequired), @YES, @"An update is required");
    XCTAssertEqualObjects(response.updateAvailableSince, [NSDate dateWithTimeIntervalSince1970:1388750400], @"The update available since date should be since timestamp 1388750400");
    XCTAssertEqualObjects(response.versionKey, @"1.0", @"Version key should be \"1.0\"");
    XCTAssertEqualObjects(response.versionNumber, @(SSVCNoVersionNumber), @"Version number should be equal to 'SSVCNoVersionNumber'");
    
    successBlockCalled = YES;
    waitingForBlock = NO;
  };
  ssvc_fetch_failure_block_t failure = ^(NSError *error) {
    XCTFail(@"Failure block should not be called");
    waitingForBlock = NO;
  };
  
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSURL *testResponseURL = [testBundle URLForResource:kValidResponseNoVersionNumber withExtension:@"json"];
  
  id runner = [[SSVCRequestRunner alloc] initWithCallbackURL:testResponseURL
                                                      parser:[SSVCJSONParser new]
                                                   scheduler:nil
                                                     success:success
                                                     failure:failure];
  [runner checkVersion];
  
  // Verify results
  while(waitingForBlock) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  XCTAssertTrue(successBlockCalled, @"Success block must be called for this test to pass");
}

@end
