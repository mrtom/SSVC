//
//  SSVCSViewController.h
//  SSVCSample
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSVCSViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *feedbackLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *feedbackIndicator;

@property (strong, nonatomic) IBOutlet UILabel *updateAvailableTitle;
@property (strong, nonatomic) IBOutlet UILabel *updateAvailableResult;
@property (strong, nonatomic) IBOutlet UILabel *updateRequiredTitle;
@property (strong, nonatomic) IBOutlet UILabel *updateRequiredResult;
@property (strong, nonatomic) IBOutlet UILabel *updateSinceTitle;
@property (strong, nonatomic) IBOutlet UILabel *updateSinceResult;
@property (strong, nonatomic) IBOutlet UILabel *latestVersionKeyTitle;
@property (strong, nonatomic) IBOutlet UILabel *latestVersionKeyResult;
@property (strong, nonatomic) IBOutlet UILabel *latestVersionNumberTitle;
@property (strong, nonatomic) IBOutlet UILabel *latestVersionNumberResult;

@end
