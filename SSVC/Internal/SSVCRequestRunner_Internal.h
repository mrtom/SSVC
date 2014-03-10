//
//  SSVCRequestRunner_Internal.h
//  SSVC
//
//  Created by Tom Elliott on 10/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Needed for testing infrastructure
@interface SSVCRequestRunner_Internal : NSObject

- (SSVCURLConnection *)__newConnection;

@end
