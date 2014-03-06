//
//  SSVCURLGenerator.m
//  SSVC
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import "SSVCURLGenerator.h"

#import "SSVC.h"

static NSString *const kSSVCClientProtocolVersion = @"SSVCClientProtocolVersion";
static NSUInteger const kSSVCClientProtocolVersionNumber = 1;

@interface SSVCURLGenerator()

@property (nonatomic, strong, readonly) NSString *baseUrl;
@property (nonatomic, strong, readonly) NSString *versionKey;
@property (nonatomic, strong, readonly) NSNumber *versionNumber;
@property (nonatomic, strong, readonly) NSString *seperator;

@end

@implementation SSVCURLGenerator

#pragma mark - Initialisation

- (id)init{
  @throw  [NSException exceptionWithName:NSInternalInconsistencyException
                                  reason:@"Must use initWithURLRequest:... instead"
                                userInfo:nil];
}

// Designated initialiser
- (id)initWithBaseURL:(NSString *)url
           versionKey:(NSString *)versionKey
        versionNumber:(NSNumber *)versionNumber
{
  if (self = [super init]) {
    _baseUrl = url;
    _versionKey = versionKey;
    _versionNumber = versionNumber;
    
    NSRange questionMarkRange = [_baseUrl rangeOfString:@"?" options:NSBackwardsSearch];
    _seperator = questionMarkRange.location == NSNotFound ? @"?" : @"&";
  }
  return self;
}

- (NSURL *)url
{
  
  return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@=%@&%@=%@&%@=%@",
          _baseUrl, _seperator,
          SSVCLatestVersionKey, _versionKey,
          SSVCLatestVersionNumber, _versionNumber,
          kSSVCClientProtocolVersion, @(kSSVCClientProtocolVersionNumber)]];
}

@end
