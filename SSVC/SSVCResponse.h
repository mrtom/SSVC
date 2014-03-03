//
//  SSVCResponse.h
//  SSVC
//
//  Created by Tom Elliott on 3/3/14.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSVCResponse : NSObject

@property (nonatomic, assign, readonly) BOOL updateAvailable;
@property (nonatomic, assign, readonly) BOOL updateRequired;

@end
