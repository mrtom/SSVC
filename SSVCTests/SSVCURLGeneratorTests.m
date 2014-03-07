//
//  SSVCURLGeneratorTests.m
//  SSVC
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "SSVC.h"
#import "SSVCURLGenerator.h"

@interface SSVCURLGeneratorTests : XCTestCase

@end

@implementation SSVCURLGeneratorTests

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

- (void)testURLGeneratorAppendsQuestionMarkForSeperatorWhenBaseURLDoesNotHaveGETParams
{
  NSString *baseURL = @"http://www.foo.com/";
  NSString *versionKey = @"version_key";
  NSNumber *versionNumber = @1;
  
  SSVCURLGenerator *urlGenerator = [[SSVCURLGenerator alloc] initWithBaseURL:baseURL
                                                                  versionKey:versionKey
                                                               versionNumber:versionNumber];
  
  NSURL *url = [urlGenerator url];
  NSString *urlString = [url absoluteString];
  
  NSRange range = [urlString rangeOfString:@"?" options:NSBackwardsSearch];
  
  XCTAssertFalse(range.location == NSNotFound, @"A ? must exist in the URL");
  XCTAssertEqual(range.length, 1u, @"Only one ? character should be found together");
}

- (void)testURLGeneratorAppendsAmpersandForSeperatorWhenBaseURLAlreadyContainsGETParams
{
  NSString *baseURL = @"http://www.foo.com?foo=bar";
  NSString *versionKey = @"version_key";
  NSNumber *versionNumber = @1;
  
  SSVCURLGenerator *urlGenerator = [[SSVCURLGenerator alloc] initWithBaseURL:baseURL
                                                                  versionKey:versionKey
                                                               versionNumber:versionNumber];
  
  NSURL *url = [urlGenerator url];
  NSString *urlString = [url absoluteString];
  
  NSRange range = [urlString rangeOfString:@"&" options:NSBackwardsSearch];
  
  XCTAssertFalse(range.location == NSNotFound, @"A & must exist in the URL");
  XCTAssertEqual(range.length, 1u, @"Only one & character should be found together");
}

- (void)testURLGeneratorContainsVersionValueForVersionKey
{
  NSString *baseURL = @"http://www.foo.com?foo=bar";
  NSString *versionKey = @"version_key";
  NSNumber *versionNumber = @1;
  
  SSVCURLGenerator *urlGenerator = [[SSVCURLGenerator alloc] initWithBaseURL:baseURL
                                                                  versionKey:versionKey
                                                               versionNumber:versionNumber];
  
  NSURL *url = [urlGenerator url];
  NSString *urlString = [url absoluteString];
  
  NSString *getKV = [NSString stringWithFormat:@"%@=%@", SSVCLatestVersionKey, versionKey];
  NSRange range = [urlString rangeOfString:getKV options:0];
  NSUInteger kvLength = [getKV length];
  
  XCTAssertFalse(range.location == NSNotFound, @"Key-value pair must occur in GET params");
  XCTAssertEqual(range.length, kvLength, @"Only one kv pair should be found together");
}

- (void)testURLGeneratorContainsVersionNumberValueForVersionNumberKey
{
  NSString *baseURL = @"http://www.foo.com?foo=bar";
  NSString *versionKey = @"version_key";
  NSNumber *versionNumber = @1;
  
  SSVCURLGenerator *urlGenerator = [[SSVCURLGenerator alloc] initWithBaseURL:baseURL
                                                                  versionKey:versionKey
                                                               versionNumber:versionNumber];
  
  NSURL *url = [urlGenerator url];
  NSString *urlString = [url absoluteString];
  
  NSString *getKV = [NSString stringWithFormat:@"%@=%@", SSVCLatestVersionNumber, versionNumber];
  NSRange range = [urlString rangeOfString:getKV options:0];
  NSUInteger kvLength = [getKV length];
  
  XCTAssertFalse(range.location == NSNotFound, @"Key-value pair must occur in GET params");
  XCTAssertEqual(range.length, kvLength, @"Only one kv pair should be found together");
}


@end
