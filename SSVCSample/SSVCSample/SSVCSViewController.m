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
      SSVCSViewController *strongSelf = weakSelf;
      if (strongSelf) {
        strongSelf.feedbackIndicator.hidden = YES;
        strongSelf.feedbackLabel.text = @"Version Check Success!";
        
        strongSelf.updateAvailableResult.text = response.updateAvailable ? @"Yes" : @"No";
        strongSelf.updateRequiredResult.text = response.updateRequired ? @"Yes" : @"No";
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        strongSelf.updateSinceResult.text = [dateFormatter stringFromDate:response.updateAvailableSince];
        
        strongSelf.latestVersionKeyResult.text = response.versionKey;
        strongSelf.latestVersionNumberResult.text = [NSString stringWithFormat:@"%@", response.versionNumber];
      }
    } failureHandler:^(NSError *error) {
      SSVCSViewController *strongSelf = weakSelf;
      if (strongSelf) {
        strongSelf.feedbackIndicator.hidden = YES;
        strongSelf.feedbackLabel.text = @"Update Failed";
        NSLog(@"%@", [error localizedDescription]);
      }
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

@end
