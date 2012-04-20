//
//  NSURLConnection+Timeout.h
//  DataKit
//
//  Created by Erik Aigner on 20.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnection (Timeout)

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response timeout:(NSTimeInterval)timeout error:(NSError **)error;

@end
