//
//  SSVCSchedulerTests.m
//  SSVC
//
//  Created by Tom Elliott on 18/05/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "SSVCScheduler.h"
#import "SSVCSchedulerDelegate.h"
#import "SSVCScheduler+Internal.h"

@interface SSVCSchedulerTests : XCTestCase

@property (nonatomic, assign) BOOL didRun;
@property (nonatomic, assign) BOOL waitingForResults;

@end

@implementation SSVCSchedulerTests

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

#pragma mark - Test we schedule the timer correctly

- (void)testStartSchedulingFromDateInPast
{
  SSVCScheduler *scheduler = [[SSVCScheduler alloc] initWithPeriod:SSVCSchedulerScheduleDaily];
  
  id mockDelegate = [OCMockObject mockForProtocol:@protocol(SSVCSchedulerDelegate)];
  [[mockDelegate expect] periodElapsedForScheduler:scheduler];
  
  scheduler.delegate = mockDelegate;
  
  NSDate *lastCheckDate = [NSDate distantPast];
  [scheduler startSchedulingFromLastCheckDate:lastCheckDate];
  
  [mockDelegate verify];
}

- (void)testStartSchedulingFromLastCheckDateWithPeriodHourly
{
  NSTimeInterval secondsPerHour = 60 /* minutes per hour */ * 60 /* seconds per minute */;
  NSDate *now = [NSDate date];
  NSDate *fireDate = [NSDate dateWithTimeInterval:secondsPerHour sinceDate:now];
  NSTimeInterval fireInterval = [fireDate timeIntervalSinceDate:now];
  
  id mockTimer = [OCMockObject mockForClass:[NSTimer class]];
  (void) [[mockTimer expect] scheduledTimerWithTimeInterval:fireInterval
                                                     target:[OCMArg any]
                                                   selector:[OCMArg anySelector]
                                                   userInfo:[OCMArg any]
                                                    repeats:NO];
  
  id mockDate = [OCMockObject niceMockForClass:[NSDate class]];
  [[[mockDate expect] andReturn:now] date];
  
  SSVCScheduler *scheduler = [[SSVCScheduler alloc] initWithPeriod:SSVCSchedulerScheduleHourly];
  [scheduler startSchedulingFromLastCheckDate:now];
  
  [mockTimer verify];
}

- (void)testStartSchedulingFromLastCheckDateWithPeriodDaily
{
  NSTimeInterval secondsPerDay = 24 /* hours per day */ * 60 /* minutes per hour */ * 60 /* seconds per minute */;
  NSDate *now = [NSDate date];
  NSDate *fireDate = [NSDate dateWithTimeInterval:secondsPerDay sinceDate:now];
  NSTimeInterval fireInterval = [fireDate timeIntervalSinceDate:now];
  
  id mockDate = [OCMockObject niceMockForClass:[NSDate class]];
  [[[mockDate expect] andReturn:now] date];
  
  id mockTimer = [OCMockObject mockForClass:[NSTimer class]];
  (void) [[mockTimer expect] scheduledTimerWithTimeInterval:fireInterval
                                                     target:[OCMArg any]
                                                   selector:[OCMArg anySelector]
                                                   userInfo:[OCMArg any]
                                                    repeats:NO];
  
  SSVCScheduler *scheduler = [[SSVCScheduler alloc] initWithPeriod:SSVCSchedulerScheduleDaily];
  [scheduler startSchedulingFromLastCheckDate:now];
  
  [mockTimer verify];
}

- (void)testStartSchedulingFromLastCheckDateWithPeriodWeekly
{
  NSTimeInterval secondsPerWeek = 7 /* days per week */ * 24 /* hours per day */ * 60 /* minutes per hour */ * 60 /* seconds per minute */;
  NSDate *now = [NSDate date];
  NSDate *fireDate = [NSDate dateWithTimeInterval:secondsPerWeek sinceDate:now];
  NSTimeInterval fireInterval = [fireDate timeIntervalSinceDate:now];
  
  id mockDate = [OCMockObject niceMockForClass:[NSDate class]];
  [[[mockDate expect] andReturn:now] date];
  
  id mockTimer = [OCMockObject mockForClass:[NSTimer class]];
  (void) [[[mockTimer expect] andReturn:mockTimer] scheduledTimerWithTimeInterval:fireInterval
                                                     target:[OCMArg any]
                                                   selector:[OCMArg anySelector]
                                                   userInfo:[OCMArg any]
                                                    repeats:NO];

  SSVCScheduler *scheduler = [[SSVCScheduler alloc] initWithPeriod:SSVCSchedulerScheduleWeekly];
  [scheduler startSchedulingFromLastCheckDate:now];
  
  [mockTimer verify];
}

- (void)testStartSchedulingFromLastCheckDateWithPeriodMonthly
{
  NSCalendar *usersCalendar = [[NSLocale currentLocale] objectForKey:NSLocaleCalendar];
  NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
  
  [offsetComponents setMonth:1];
  
  NSDate *now = [NSDate date];
  NSDate *fireDate = [usersCalendar dateByAddingComponents:offsetComponents toDate:now options:0];
  NSTimeInterval fireInterval = [fireDate timeIntervalSinceDate:now];
  
  id mockDate = [OCMockObject niceMockForClass:[NSDate class]];
  [[[mockDate expect] andReturn:now] date];
  
  id mockTimer = [OCMockObject mockForClass:[NSTimer class]];
  (void) [[mockTimer expect] scheduledTimerWithTimeInterval:fireInterval
                                                     target:[OCMArg any]
                                                   selector:[OCMArg anySelector]
                                                   userInfo:[OCMArg any]
                                                    repeats:NO];

  SSVCScheduler *scheduler = [[SSVCScheduler alloc] initWithPeriod:SSVCSchedulerScheduleMonthly];
  [scheduler startSchedulingFromLastCheckDate:now];
  
  [mockTimer verify];
}

#pragma mark - Test callback fired correctly

- (void)testStartSchedulingFromLastCheckDateWithPeriodHourlyCallDelegateWhenTimerFires
{
  SSVCScheduler *scheduler = [[SSVCScheduler alloc] initWithPeriod:SSVCSchedulerScheduleHourly];
  
  id mockDelegate = [OCMockObject mockForProtocol:@protocol(SSVCSchedulerDelegate)];
  [[mockDelegate expect] periodElapsedForScheduler:scheduler];
  
  scheduler.delegate = mockDelegate;
  
  NSDate *lastCheckDate = [NSDate date];
  [scheduler startSchedulingFromLastCheckDate:lastCheckDate];
  
  // Grab the timer from the private API. This kinda sucks, but ho hum...
  NSTimer *timer = scheduler.versionCheckTimer;
  [timer fire];
  
  [mockDelegate verify];
}

- (void)testStartSchedulingFromLastCheckDateWithPeriodDailyCallDelegateWhenTimerFires
{
  SSVCScheduler *scheduler = [[SSVCScheduler alloc] initWithPeriod:SSVCSchedulerScheduleDaily];
  
  id mockDelegate = [OCMockObject mockForProtocol:@protocol(SSVCSchedulerDelegate)];
  [[mockDelegate expect] periodElapsedForScheduler:scheduler];
  
  scheduler.delegate = mockDelegate;
  
  NSDate *lastCheckDate = [NSDate date];
  [scheduler startSchedulingFromLastCheckDate:lastCheckDate];
  
  // Grab the timer from the private API. This kinda sucks, but ho hum...
  NSTimer *timer = scheduler.versionCheckTimer;
  [timer fire];
  
  [mockDelegate verify];
}

- (void)testStartSchedulingFromLastCheckDateWithPeriodWeeklyCallDelegateWhenTimerFires
{
  SSVCScheduler *scheduler = [[SSVCScheduler alloc] initWithPeriod:SSVCSchedulerScheduleWeekly];
  
  id mockDelegate = [OCMockObject mockForProtocol:@protocol(SSVCSchedulerDelegate)];
  [[mockDelegate expect] periodElapsedForScheduler:scheduler];
  
  scheduler.delegate = mockDelegate;
  
  NSDate *lastCheckDate = [NSDate date];
  [scheduler startSchedulingFromLastCheckDate:lastCheckDate];
  
  // Grab the timer from the private API. This kinda sucks, but ho hum...
  NSTimer *timer = scheduler.versionCheckTimer;
  [timer fire];
  
  [mockDelegate verify];
}

- (void)testStartSchedulingFromLastCheckDateWithPeriodMonthlyCallDelegateWhenTimerFires
{
  SSVCScheduler *scheduler = [[SSVCScheduler alloc] initWithPeriod:SSVCSchedulerScheduleMonthly];
  
  id mockDelegate = [OCMockObject mockForProtocol:@protocol(SSVCSchedulerDelegate)];
  [[mockDelegate expect] periodElapsedForScheduler:scheduler];
  
  scheduler.delegate = mockDelegate;
  
  NSDate *lastCheckDate = [NSDate date];
  [scheduler startSchedulingFromLastCheckDate:lastCheckDate];
  
  // Grab the timer from the private API. This kinda sucks, but ho hum...
  NSTimer *timer = scheduler.versionCheckTimer;
  [timer fire];
  
  [mockDelegate verify];
}


@end
