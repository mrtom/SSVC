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
  NSUInteger numberOfOccurancesOfQM = [self numberOfOccurancesOfNeedle:@"?" inHaystack:urlString];
  NSUInteger numberOfOccurancesOfA = [self numberOfOccurancesOfNeedle:@"&" inHaystack:urlString];
  
  XCTAssertFalse(range.location == NSNotFound, @"A ? must exist in the URL");
  XCTAssertEqual(@1, @(numberOfOccurancesOfQM), @"Only one ? character should be found together");
  XCTAssertEqual(@4, @(numberOfOccurancesOfA), @"4 & characters should be found all together");
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
  NSUInteger numberOfOccurancesOfQM = [self numberOfOccurancesOfNeedle:@"?" inHaystack:urlString];
  NSUInteger numberOfOccurancesOfA = [self numberOfOccurancesOfNeedle:@"&" inHaystack:urlString];
  
  XCTAssertFalse(range.location == NSNotFound, @"A & must exist in the URL");
  XCTAssertEqual(@1, @(numberOfOccurancesOfQM), @"Only one ? character should be found together");
  XCTAssertEqual(@5, @(numberOfOccurancesOfA), @"5 & characters should be found all together");
}

- (void)testURLGeneratorContainsVersionValueForVersionKey
{
  NSString *baseURL = @"http://www.foo.comr";
  NSString *versionKey = @"version_key";
  NSNumber *versionNumber = @1;
  
  SSVCURLGenerator *urlGenerator = [[SSVCURLGenerator alloc] initWithBaseURL:baseURL
                                                                  versionKey:versionKey
                                                               versionNumber:versionNumber];
  
  NSURL *url = [urlGenerator url];
  NSString *urlString = [url absoluteString];
  
  NSString *getKV = [NSString stringWithFormat:@"%@=%@", SSVCLatestVersionKey, versionKey];
  NSRange range = [urlString rangeOfString:getKV options:0];
  NSUInteger numberOfOccurances = [self numberOfOccurancesOfNeedle:getKV inHaystack:urlString];
  
  XCTAssertFalse(range.location == NSNotFound, @"Key-value pair must occur in GET params");
  XCTAssertEqual(@1, @(numberOfOccurances), @"Only one kv pair should be found together");
}

- (void)testURLGeneratorContainsVersionNumberValueForVersionNumberKey
{
  NSString *baseURL = @"http://www.foo.com";
  NSString *versionKey = @"version_key";
  NSNumber *versionNumber = @1;
  
  SSVCURLGenerator *urlGenerator = [[SSVCURLGenerator alloc] initWithBaseURL:baseURL
                                                                  versionKey:versionKey
                                                               versionNumber:versionNumber];
  
  NSURL *url = [urlGenerator url];
  NSString *urlString = [url absoluteString];
  
  NSString *getKV = [NSString stringWithFormat:@"%@=%@", SSVCLatestVersionNumber, versionNumber];
  NSRange range = [urlString rangeOfString:getKV options:0];
  NSUInteger numberOfOccurances = [self numberOfOccurancesOfNeedle:getKV inHaystack:urlString];
  
  XCTAssertFalse(range.location == NSNotFound, @"Key-value pair must occur in GET params");
  XCTAssertEqual(@1, @(numberOfOccurances), @"Only one kv pair should be found together");
}

- (void)testURLGeneratorContainsVersionValueForVersionKeyWhenBaseURLAlreadyContainsGETParams
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
  NSUInteger numberOfOccurances = [self numberOfOccurancesOfNeedle:getKV inHaystack:urlString];
  
  XCTAssertFalse(range.location == NSNotFound, @"Key-value pair must occur in GET params");
  XCTAssertEqual(@1, @(numberOfOccurances), @"Only one kv pair should be found together");
}

- (void)testURLGeneratorContainsVersionNumberValueForVersionNumberKeyWhenBaseURLAlreadyContainsGETParams
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
  NSUInteger numberOfOccurances = [self numberOfOccurancesOfNeedle:getKV inHaystack:urlString];
  
  XCTAssertFalse(range.location == NSNotFound, @"Key-value pair must occur in GET params");
  XCTAssertEqual(@1, @(numberOfOccurances), @"Only one kv pair should be found together");
}

- (void)testURLGeneratorContainsLanguageCode
{
  NSString *baseURL = @"http://www.foo.com?foo=bar";
  NSString *versionKey = @"version_key";
  NSNumber *versionNumber = @1;
  
  SSVCURLGenerator *urlGenerator = [[SSVCURLGenerator alloc] initWithBaseURL:baseURL
                                                                  versionKey:versionKey
                                                               versionNumber:versionNumber];
  
  NSURL *url = [urlGenerator url];
  NSString *urlString = [url absoluteString];

  NSLocale *locale = [NSLocale currentLocale];
  NSString *languageCode = [locale objectForKey:NSLocaleLanguageCode];
  
  NSString *languageCodeKV = [NSString stringWithFormat:@"%@=%@", SSVCLocaleLanguageCode, languageCode];
  NSRange range = [urlString rangeOfString:languageCodeKV];
  
  NSUInteger numberOfOccurances = [self numberOfOccurancesOfNeedle:languageCodeKV inHaystack:urlString];
  
  XCTAssertFalse(range.location == NSNotFound, @"Language code must occure in GET params");
  XCTAssertEqual(@1, @(numberOfOccurances), @"Language code must only occur once in GET params");
}

- (void)testURLGeneratorContainsLocaleCode
{
  NSString *baseURL = @"http://www.foo.com?foo=bar";
  NSString *versionKey = @"version_key";
  NSNumber *versionNumber = @1;
  
  SSVCURLGenerator *urlGenerator = [[SSVCURLGenerator alloc] initWithBaseURL:baseURL
                                                                  versionKey:versionKey
                                                               versionNumber:versionNumber];
  
  NSURL *url = [urlGenerator url];
  NSString *urlString = [url absoluteString];
  
  NSLocale *locale = [NSLocale currentLocale];
  NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
  
  NSString *countryCodeKV = [NSString stringWithFormat:@"%@=%@", SSVCLocaleCountryCode, countryCode];
  NSRange range = [urlString rangeOfString:countryCodeKV];
  
  NSUInteger numberOfOccurances = [self numberOfOccurancesOfNeedle:countryCode inHaystack:urlString];
  
  XCTAssertFalse(range.location == NSNotFound, @"Country code must occure in GET params");
  XCTAssertEqual(@1, @(numberOfOccurances), @"Country code must only occur once in GET params");
}

#pragma mark - Utility methods

- (void)testOccuranceOfNeedleMethod
{
  NSString *haystack = @"How many pies can a pie eater eat if a pie eater eats all the pie?";
  
  NSUInteger flibbleCount = [self numberOfOccurancesOfNeedle:@"flibble" inHaystack:haystack];
  NSUInteger howCount = [self numberOfOccurancesOfNeedle:@"How" inHaystack:haystack];
  NSUInteger allCount = [self numberOfOccurancesOfNeedle:@"all" inHaystack:haystack];
  NSUInteger pieCount = [self numberOfOccurancesOfNeedle:@"pie" inHaystack:haystack];
  
  XCTAssertEqual(@0, @(flibbleCount), @"There is no 'flibble'");
  XCTAssertEqual(@1, @(howCount), @"There is one 'how'");
  XCTAssertEqual(@1, @(allCount), @"There is one 'all'");
  XCTAssertEqual(@4, @(pieCount), @"There are lots of pies. 4 to be precise. Pie is tasty!");
}

- (NSUInteger)numberOfOccurancesOfNeedle:(NSString *)needle inHaystack:(NSString *)haystack
{
  NSUInteger count = 0, length = [haystack length];
  NSRange range = NSMakeRange(0, length);
  while(range.location != NSNotFound) {
    range = [haystack rangeOfString:needle options:0 range:range];
    if(range.location != NSNotFound) {
      range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
      count++;
    }
  }
  
  return count;
}


@end
