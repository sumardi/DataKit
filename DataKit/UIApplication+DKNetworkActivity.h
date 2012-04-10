//
//  UIApplication+DKNetworkActivity.h
//  DataKit
//
//  Created by Erik Aigner on 10.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 Helper category for displaying the network activity indicator
 */
@interface UIApplication (DKNetworkActivity)

/**
 Begin a network activity
 */
+ (void)beginNetworkActivity;

/**
 End a network activity. Must be balanced with -beginNetworkActivity.
 */
+ (void)endNetworkActivity;

/**
 Returns the number of current network activities
 @return The number of current network activities
 */
+ (NSInteger)networkActivityCount;

@end
