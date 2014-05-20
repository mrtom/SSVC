//
//  SSVCScheduler.m
//  SSVC
//
//  Created by Tom Elliott on 03/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import "SSVCScheduler.h"

#import "SSVCSchedulerDelegate.h"

static const NSTimeInterval kSecondsPerHour = 60 * 60;
static const NSTimeInterval kSecondsPerDay = 24 * kSecondsPerHour;
static const NSTimeInterval kSecondsPerWeek = 7 * kSecondsPerDay;

@interface SSVCScheduler()

@property (nonatomic, assign, readonly) SSVCSchedulerRunPeriod period;
@property (nonatomic, strong) NSTimer *versionCheckTimer;

@end

@implementation SSVCScheduler

- (id)init
{
  return [self initWithPeriod:SSVCSchedulerDoNotSchedule];
}

// Designated initialiser
- (id)initWithPeriod:(SSVCSchedulerRunPeriod)period
{
  if (self = [super init]) {
    _period = period;
  }
  return self;
}

#pragma mark - Public instance methods

- (void)startSchedulingFromLastCheckDate:(NSDate *)lastCheckDate
{
  NSAssert([NSThread isMainThread], @"Must be called on the main thread");
  
  if (_versionCheckTimer) {
    [_versionCheckTimer invalidate];
  }
  
  NSDate *now = [NSDate date];
  NSDate *maximumValidLastDate;
  NSDate *minimumValidNextDate;
  NSCalendar *usersCalendar;
  
  switch (_period) {
    case SSVCSchedulerDoNotSchedule:
      maximumValidLastDate = [NSDate distantPast];
      minimumValidNextDate = [NSDate distantFuture];
      break;
    case SSVCSchedulerScheduleHourly:
      maximumValidLastDate = [NSDate dateWithTimeInterval:-kSecondsPerHour sinceDate:now];
      minimumValidNextDate = [NSDate dateWithTimeInterval:kSecondsPerHour sinceDate:lastCheckDate];
      break;
    case SSVCSchedulerScheduleDaily:
      maximumValidLastDate = [NSDate dateWithTimeInterval:-kSecondsPerDay sinceDate:now];
      minimumValidNextDate = [NSDate dateWithTimeInterval:kSecondsPerDay sinceDate:lastCheckDate];
      break;
    case SSVCSchedulerScheduleWeekly:
      maximumValidLastDate = [NSDate dateWithTimeInterval:-kSecondsPerWeek sinceDate:now];
      minimumValidNextDate = [NSDate dateWithTimeInterval:kSecondsPerWeek sinceDate:lastCheckDate];
      break;
    case SSVCSchedulerScheduleMonthly:
      usersCalendar = [[NSLocale currentLocale] objectForKey:NSLocaleCalendar];
      NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
      
      [offsetComponents setMonth:-1];
      maximumValidLastDate = [usersCalendar dateByAddingComponents:offsetComponents toDate:now options:0];
      
      [offsetComponents setMonth:1];
      minimumValidNextDate = [usersCalendar dateByAddingComponents:offsetComponents toDate:lastCheckDate options:0];
      break;
  }
  
  if ([lastCheckDate compare:maximumValidLastDate] == NSOrderedAscending) {
    // Last check date is before the maximum valid last date, so we need to do a check now
    [self __scheduleVersionCheck];
  } else {
    // Last check date is after the maximum valid last date, so we must schedule a check
    // We want to schedule this for the time given by minimumValidNextDate, but because
    // we want to use scheduledTimerWithTimeInterval (as we can stub it from the tests)
    // we must re-calculate an NSTimeInterval :(
    NSTimeInterval fireInterval = [minimumValidNextDate timeIntervalSinceDate:now];
    
    _versionCheckTimer = [NSTimer scheduledTimerWithTimeInterval:fireInterval
                                                          target:self
                                                        selector:@selector(__scheduleVersionCheck)
                                                        userInfo:Nil
                                                         repeats:NO];
  }
}

#pragma mark - Private instance methods

- (void)__scheduleVersionCheck
{
  [self.delegate periodElapsedForScheduler:self];
}

@end
