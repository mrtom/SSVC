//
//  SSVCRequestRunnerTests.m
//  SSVC
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <XCTest/XCTest.h>

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
  NSString *badJSON = @"blahblah:";
  
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
