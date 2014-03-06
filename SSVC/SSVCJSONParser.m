//
//  SSVCJSONParser.m
//  SSVC
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import "SSVCJSONParser.h"

@implementation SSVCJSONParser

- (NSDictionary *)parseResponseFromData:(NSData *)data error:(NSError **)error
{
  return [self parseJSONFromData:data error:error];
}

- (NSDictionary *)parseJSONFromData:(NSData *)data error:(NSError **)error
{
  return [NSJSONSerialization JSONObjectWithData:data
                                         options:kNilOptions
                                           error:error];
}

@end
