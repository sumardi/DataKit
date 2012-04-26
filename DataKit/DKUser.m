//
//  DKUser.m
//  DataKit
//
//  Created by Erik Aigner on 25.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKUser.h"

#import "DKRequest.h"
#import "DKUser-Private.h"

@implementation DKUser
DKSynthesize(name)
DKSynthesize(email)
DKSynthesize(password)

+ (instancetype)userWithName:(NSString *)name password:(NSString *)password email:(NSString *)email {
  DKUser *user = [DKUser new];
  user.name = name;
  user.password = password;
  user.email = email;

  return user;
}

- (BOOL)signUp:(NSError **)error {
  NSDictionary *requestObjects = [NSDictionary dictionaryWithObjectsAndKeys:
                                  self.name, @"name",
                                  self.email, @"email",
                                  self.password, @"passwd", nil];
  
  // Send request synchronously
  DKRequest *request = [DKRequest request];
  request.cachePolicy = DKCachePolicyIgnoreCache;
  
  NSError *requestError = nil;
  [request sendRequestWithObject:requestObjects method:@"signUp" error:&requestError];
  if (requestError != nil) {
    if (error != nil) {
      *error = requestError;
    }
    return NO;
  }
  
  return YES;
}

@end
