//
//  SSVCJSONParser.h
//  SSVC
//
//  Created by Tom Elliott on 06/03/2014.
//  Copyright (c) 2014 Sneaky Snail. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SSVCResponseParserProtocol.h"

@interface SSVCJSONParser : NSObject<SSVCResponseParserProtocol>

- (NSDictionary *)parseResponseFromData:(NSData *)data error:(NSError **)error;

@end
