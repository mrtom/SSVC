//
//  SSVCResponse.h
//  SSVC
//
//  Created by Tom Elliott on 3/3/14.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSVCResponse : NSObject<NSCoding>

@property (nonatomic, assign, readonly) BOOL updateAvailable;
@property (nonatomic, assign, readonly) BOOL updateRequired;
@property (nonatomic, strong, readonly) NSNumber *minimumSupportedVersionNumber;
@property (nonatomic, strong, readonly) NSDate *updateAvailableSince;
@property (nonatomic, strong, readonly) NSString *versionKey;
@property (nonatomic, strong, readonly) NSNumber *versionNumber;

/// Designated initialiser
- (id)initWithUpdateAvailable:(BOOL)updateAvailable
               updateRequired:(BOOL)updateRequired
minimumSupportedVersionNumber:(NSNumber *)minimumSupportedVersionNumber
         updateAvailableSince:(NSDate *)updateAvailableSince
             latestVersionKey:(NSString *)versionKey
          latestVersionNumber:(NSNumber *)versionNumber;

@end
