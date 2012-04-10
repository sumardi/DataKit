//
//  UIApplication+DKNetworkActivity.h
//  DataKit
//
//  Created by Erik Aigner on 10.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (DKNetworkActivity)

+ (void)beginNetworkActivity;
+ (void)endNetworkActivity;
+ (NSInteger)networkActivityCount;

@end
