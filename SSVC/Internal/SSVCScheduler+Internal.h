//
//  SSVCScheduler+Internal.h
//  SSVC
//
//  Created by Tom Elliott on 20/05/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Needed for testing infrastructure
@interface SSVCScheduler (Internal)

@property (nonatomic, strong) NSTimer *versionCheckTimer;

@end
