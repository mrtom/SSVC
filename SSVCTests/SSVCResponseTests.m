//
//  SSVCResponseTests.m
//  SSVC
//
//  Created by Tom Elliott on 18/05/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "SSVCResponse.h"

@interface SSVCResponseTests : XCTestCase

@end


@implementation SSVCResponseTests

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

- (void)testFullSSVCResponse
{
  NSDate *now = [NSDate date];
  
  SSVCResponse *response = [[SSVCResponse alloc] initWithUpdateAvailable:YES
                                                          updateRequired:NO
                                           minimumSupportedVersionNumber:@12345
                                                    updateAvailableSince:now
                                                        latestVersionKey:@"Monkeys"
                                                     latestVersionNumber:@87654];
  
  XCTAssertEqual(YES, response.updateAvailable, @"Update available should be equal to YES");
  XCTAssertEqual(NO, response.updateRequired, @"Update is not required");
  XCTAssertEqualObjects(@12345, response.minimumSupportedVersionNumber, @"Numbers should match");
  XCTAssertEqualObjects(now, response.updateAvailableSince, @"Dates should match");
  XCTAssertEqualObjects(@"Monkeys", response.versionKey, @"Version keys should match");
  XCTAssertEqualObjects(@87654, response.versionNumber, @"Version numbers should match");
}

- (void)testSSVCResponseEquality
{
  NSDate *now = [NSDate date];
  NSDate *earlier = [NSDate dateWithTimeInterval:-30 sinceDate:now];
  
  SSVCResponse *response0 = [[SSVCResponse alloc] initWithUpdateAvailable:YES
                                                           updateRequired:NO
                                            minimumSupportedVersionNumber:@12345
                                                     updateAvailableSince:now
                                                         latestVersionKey:@"Monkeys"
                                                      latestVersionNumber:@87654];
  
  SSVCResponse *response1 = [[SSVCResponse alloc] initWithUpdateAvailable:YES
                                                          updateRequired:NO
                                           minimumSupportedVersionNumber:@12345
                                                    updateAvailableSince:now
                                                        latestVersionKey:@"Monkeys"
                                                     latestVersionNumber:@87654];
  
  SSVCResponse *response2 = [[SSVCResponse alloc] initWithUpdateAvailable:NO
                                                           updateRequired:NO
                                            minimumSupportedVersionNumber:@12345
                                                     updateAvailableSince:now
                                                         latestVersionKey:@"Monkeys"
                                                      latestVersionNumber:@87654];
  
  SSVCResponse *response3 = [[SSVCResponse alloc] initWithUpdateAvailable:YES
                                                           updateRequired:YES
                                            minimumSupportedVersionNumber:@12345
                                                     updateAvailableSince:now
                                                         latestVersionKey:@"Monkeys"
                                                      latestVersionNumber:@87654];
  
  SSVCResponse *response4 = [[SSVCResponse alloc] initWithUpdateAvailable:YES
                                                           updateRequired:NO
                                            minimumSupportedVersionNumber:@12346
                                                     updateAvailableSince:now
                                                         latestVersionKey:@"Monkeys"
                                                      latestVersionNumber:@87654];
  
  SSVCResponse *response5 = [[SSVCResponse alloc] initWithUpdateAvailable:YES
                                                           updateRequired:NO
                                            minimumSupportedVersionNumber:@12345
                                                     updateAvailableSince:earlier
                                                         latestVersionKey:@"Monkeys"
                                                      latestVersionNumber:@87654];
  
  SSVCResponse *response6 = [[SSVCResponse alloc] initWithUpdateAvailable:YES
                                                           updateRequired:NO
                                            minimumSupportedVersionNumber:@12345
                                                     updateAvailableSince:earlier
                                                         latestVersionKey:@"Penguins"
                                                      latestVersionNumber:@87654];
  
  SSVCResponse *response7 = [[SSVCResponse alloc] initWithUpdateAvailable:YES
                                                           updateRequired:NO
                                            minimumSupportedVersionNumber:@12345
                                                     updateAvailableSince:earlier
                                                         latestVersionKey:@"Monkeys"
                                                      latestVersionNumber:@97654];
  
  NSArray *responseArray = [NSArray arrayWithObjects:response0,
                            response1,
                            response2,
                            response3,
                            response4,
                            response5,
                            response6,
                            response7,
                            nil];
  
  XCTAssertEqualObjects(response0, response1, @"These really are the same");
  
  for (NSUInteger i = 1; i < [responseArray count]; i++) {
    for (NSUInteger j = 1; j < [responseArray count]; j++) {
      if (i == j) {
        XCTAssertEqualObjects([responseArray objectAtIndex:i], [responseArray objectAtIndex:j], @"Response %d and response %d are the same", i, j);
      } else {
        XCTAssertNotEqualObjects([responseArray objectAtIndex:i], [responseArray objectAtIndex:j], @"Response %d and response %d are not the same", i, j);
      }
    }
  }
}

- (void)testSSVCResponseArchiving
{
  NSDate *now = [NSDate date];
  
  SSVCResponse *response = [[SSVCResponse alloc] initWithUpdateAvailable:YES
                                                          updateRequired:NO
                                           minimumSupportedVersionNumber:@12346
                                                    updateAvailableSince:now
                                                        latestVersionKey:@"Monkeys"
                                                     latestVersionNumber:@87654];
  
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:response];
  SSVCResponse *response2 = (SSVCResponse *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  
  XCTAssertEqualObjects(response, response2, @"Encoding and decoding shouldn't change the value of the object");
}

@end
