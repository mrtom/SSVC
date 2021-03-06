//
//  SSVCResponse.m
//  SSVC
//
//  Created by Tom Elliott on 3/3/14.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import "SSVCResponse.h"

#import "SSVC.h"

static NSString *const kSSVCResponseCreatedDate = @"kSSVCResponseCreatedDate";

@interface SSVCResponse()

@property (nonatomic, strong, readonly) NSDate *createdDate;

@end

@implementation SSVCResponse

- (id)init{
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"Must use initWithUpdateAvailable: updateRequired: latestVersionKey: latestVersionNumber: instead"
                               userInfo:nil];
}

// Designated initialiser
- (id)initWithUpdateAvailable:(BOOL)updateAvailable
               updateRequired:(BOOL)updateRequired
minimumSupportedVersionNumber:(NSNumber *)minimumSupportedVersionNumber
         updateAvailableSince:(NSDate *)updateAvailableSince
             latestVersionKey:(NSString *)versionKey
          latestVersionNumber:(NSNumber *)versionNumber
{
  if (self = [super init]) {
    _updateAvailable = updateAvailable;
    _updateRequired = updateRequired;
    _minimumSupportedVersionNumber = minimumSupportedVersionNumber;
    _updateAvailableSince = updateAvailableSince;
    _versionKey = versionKey;
    _versionNumber = versionNumber;
    
    _createdDate = [NSDate date];
  }
  return self;
}

#pragma mark - NSCoder methods

- (id)initWithCoder:(NSCoder *)decoder {
  if (self = [super init]) {
    _updateAvailable = [decoder decodeBoolForKey:SSVCUpdateAvailable];
    _updateRequired = [decoder decodeBoolForKey:SSVCUpdateRequired];
    _minimumSupportedVersionNumber = [decoder decodeObjectForKey:SSVCMinimumSupportedVersionNumber];
    _updateAvailableSince = [decoder decodeObjectForKey:SSVCLatestVersionAvailableSince];
    _versionKey = [decoder decodeObjectForKey:SSVCLatestVersionKey];
    _versionNumber = [decoder decodeObjectForKey:SSVCLatestVersionNumber];
    _createdDate = [decoder decodeObjectForKey:kSSVCResponseCreatedDate];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeBool:_updateAvailable forKey:SSVCUpdateAvailable];
  [encoder encodeBool:_updateRequired forKey:SSVCUpdateRequired];
  [encoder encodeObject:_minimumSupportedVersionNumber forKey:SSVCMinimumSupportedVersionNumber];
  [encoder encodeObject:_updateAvailableSince forKey:SSVCLatestVersionAvailableSince];
  [encoder encodeObject:_versionKey forKey:SSVCLatestVersionKey];
  [encoder encodeObject:_versionNumber forKey:SSVCLatestVersionNumber];
  [encoder encodeObject:_createdDate forKey:kSSVCResponseCreatedDate];
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger updateAvailableHash = _updateAvailable ? 1109 : 1879;
  NSUInteger updateRequiredHash = _updateRequired ? 3163 : 3761;
  NSUInteger minimumSupportedVersionNumberHash = [_minimumSupportedVersionNumber hash];
  NSUInteger updateAvailableSinceHash = [_updateAvailableSince hash];
  NSUInteger versionKeyHash = [_versionKey hash];
  NSUInteger versionNumberHash = [_versionNumber hash];
  
  // We don't includle created date here, because we don't care about that for equality.
  // We want two objects to be considered equal if the values of the response is equal
  //NSUInteger createdDateHash = [_createdDate hash];
  
  return updateAvailableHash ^ updateRequiredHash ^ minimumSupportedVersionNumberHash ^ updateAvailableSinceHash ^ versionKeyHash ^ versionNumberHash;
}

- (BOOL)isEqual:(id)object
{
  if (self == object) return YES;
  
  if (!_updateAvailable == [object updateAvailable]) return NO;
  if (!_updateRequired == [object updateRequired]) return NO;
  if (![_minimumSupportedVersionNumber isEqualToNumber:[object minimumSupportedVersionNumber]]) return NO;
  if (![_updateAvailableSince isEqual:[object updateAvailableSince]]) return NO;
  if (![_versionKey isEqualToString:[object versionKey]]) return NO;
  if (![_versionNumber isEqualToNumber:[object versionNumber]]) return NO;
  
  // Ignore created date. See [self hash] for rationale
  //if (![_createdDate isEqualToDate:[object createdDate]]) return NO;
  
  return YES;
}

@end
