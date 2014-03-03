//
//  SSVCScheduler.h
//  SSVC
//
//  Created by Tom Elliott on 03/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SSVCSchedulerDelegate;

typedef NS_ENUM(NSUInteger, SSVCSchedulerRunPeriod) {
  SSVCSchedulerDoNotSchedule,
  SSVCSchedulerScheduleHourly,
  SSVCSchedulerScheduleDaily,
  SSVCSchedulerScheduleWeekly,
  SSVCSchedulerScheduleMonthly,
};

@interface SSVCScheduler : NSObject

// Designated initialiser
- (id)initWithPeriod:(SSVCSchedulerRunPeriod)period;

@property (nonatomic, weak) id<SSVCSchedulerDelegate> delegate;

- (void)startSchedulingWithLastVersionDateCheck:(NSDate *)lastCheckDate;

@end
