//
//  SSVCSchedulerDelegate.h
//  SSVC
//
//  Created by Tom Elliott on 03/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SSVCScheduler.h"

@protocol SSVCSchedulerDelegate <NSObject>

@required
- (void)periodElapsedForScheduler:(SSVCScheduler *)scheduler;

@end
