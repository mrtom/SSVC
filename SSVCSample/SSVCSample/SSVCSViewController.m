//
//  SSVCSViewController.m
//  SSVCSample
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import "SSVCSViewController.h"

#import <SSVC/SSVC.h>
#import <SSVC/SSVCResponse.h>

@interface SSVCSViewController ()

@property (nonatomic, strong) SSVC *versionChecker;

@end

@implementation SSVCSViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if (self = [super initWithCoder:aDecoder]) {
    __weak SSVCSViewController *weakSelf = self;
    
    // Create the version checker and the callback blocks
    _versionChecker = [[SSVC alloc] initWithCompletionHandler:^(SSVCResponse *response) {
      [weakSelf __handleVersionCheckSuccessWithResponse:response];
    } failureHandler:^(NSError *error) {
      [weakSelf __handleVersionCheckFailureForError:error];
    }];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Check version
  [_feedbackIndicator startAnimating];
  _feedbackIndicator.hidden = NO;
  _feedbackLabel.text = @"Checking for Update";
  [_versionChecker checkVersion];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Private instance methods

- (void)__handleVersionCheckSuccessWithResponse:(SSVCResponse *)response
{
  _feedbackIndicator.hidden = YES;
  _feedbackLabel.text = @"Version Check Success!";
  
  _updateAvailableResult.text = response.updateAvailable ? @"Yes" : @"No";
  _updateRequiredResult.text = response.updateRequired ? @"Yes" : @"No";
  
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
  [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
  _updateSinceResult.text = [dateFormatter stringFromDate:response.updateAvailableSince];
  
  _latestVersionKeyResult.text = response.versionKey;
  _latestVersionNumberResult.text = [NSString stringWithFormat:@"%@", response.versionNumber];
}

- (void)__handleVersionCheckFailureForError:(NSError *)error
{
  _feedbackIndicator.hidden = YES;
  _feedbackLabel.text = @"Update Failed";
  NSLog(@"%@", [error localizedDescription]);
}

@end
