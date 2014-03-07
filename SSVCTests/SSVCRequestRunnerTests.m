//
//  SSVCRequestRunnerTests.m
//  SSVC
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <OCMock/OCMock.h>

#import "SSVCJSONParser.h"

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
  id mockJSONParser = [OCMockObject mockForClass:[SSVCJSONParser class]];
  [[[mockJSONParser expect] andReturn:nil] parseJSONFromData:nil andError:nil];
  
  
  id mockTableView = [OCMockObject mockForClass:[UITableView class]];
//	[[[mockTableView expect] andReturn:nil] dequeueReusableCellWithIdentifier:@"HelloWorldCell"];

  [mockTableView verify];
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
