//
//  SSVCResponse.m
//  SSVC
//
//  Created by Tom Elliott on 3/3/14.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import "SSVCResponse.h"

#import "SSVC.h"

@implementation SSVCResponse

- (id)init{
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"Must use initWithUpdateAvailable: updateRequired: latestVersionKey: latestVersionNumber: instead"
                               userInfo:nil];
}

- (id)initWithUpdateAvailable:(BOOL)updateAvailable
               updateRequired:(BOOL)updateRequired
             latestVersionKey:(NSString *)versionKey
          latestVersionNumber:(NSNumber *)versionNumber
{
  if (self = [super init]) {
    _updateAvailable = updateAvailable;
    _updateRequired = updateRequired;
    _versionKey = versionKey;
    _versionNumber = versionNumber;
  }
  return self;
}

#pragma mark - NSCoder methods

- (id)initWithCoder:(NSCoder *)decoder {
  if (self = [super init]) {
    _updateAvailable = [decoder decodeBoolForKey:SSVCUpdateAvailable];
    _updateRequired = [decoder decodeBoolForKey:SSVCUpdateRequired];
    _versionKey = [decoder decodeObjectForKey:SSVCLatestVersionKey];
    _versionNumber = [decoder decodeObjectForKey:SSVCLatestVersionNumber];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeBool:_updateAvailable forKey:SSVCUpdateAvailable];
  [encoder encodeBool:_updateRequired forKey:SSVCUpdateRequired];
  [encoder encodeObject:_versionKey forKey:SSVCLatestVersionKey];
  [encoder encodeObject:_versionNumber forKey:SSVCLatestVersionNumber];
}

@end
