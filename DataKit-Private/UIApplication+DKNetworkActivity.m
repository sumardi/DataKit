//
//  UIApplication+DKNetworkActivity.m
//  DataKit
//
//  Created by Erik Aigner on 10.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "UIApplication+DKNetworkActivity.h"

#import <libkern/OSAtomic.h>


@implementation UIApplication (DKNetworkActivity)

static int32_t kDKUIApplicationNetworkActivityCount = 0;

+ (void)updateNetworkActivityStatus {
  [self sharedApplication].networkActivityIndicatorVisible = (kDKUIApplicationNetworkActivityCount > 0);
}

+ (void)beginNetworkActivity {
  OSAtomicIncrement32(&kDKUIApplicationNetworkActivityCount);
  [self updateNetworkActivityStatus];
}

+ (void)endNetworkActivity {
  OSAtomicDecrement32(&kDKUIApplicationNetworkActivityCount);
  
  // Delay update a little to avoid flickering
  double delayInSeconds = 0.2;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [self updateNetworkActivityStatus];
  });
}

+ (NSInteger)networkActivityCount {
  return kDKUIApplicationNetworkActivityCount;
}

@end
