//
//  SSVCURLGenerator.h
//  SSVC
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSVCURLGenerator : NSObject

/// Designated initialiser
- (id)initWithBaseURL:(NSString *)url
           versionKey:(NSString *)versionKey
        versionNumber:(NSNumber *)versionNumber;

- (NSURL *)url;

@end
