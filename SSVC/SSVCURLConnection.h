//
//  SSVCURLConnection.h
//  SSVC
//
//  Created by Tom Elliott on 3/3/14.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSVCURLConnection : NSURLConnection

@property(nonatomic, strong) NSMutableData *data;
@property(nonatomic, copy) void (^onComplete)();
@property(nonatomic, copy) void (^onError)(NSError *error);

@end
