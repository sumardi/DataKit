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
#import "DKEntity-Private.h"
#import "NSData+DataKit.h"

@implementation DKUser
DKSynthesize(sessionToken)

#define kDKUserEntityName @"datakit.users"
#define kDKUserNameField @"name"
#define kDKUserEmailField @"email"
#define kDKUserPasswdField @"passwd"

+ (instancetype)userWithName:(NSString *)name password:(NSString *)password email:(NSString *)email {
  DKUser *user = [self entityWithName:kDKUserEntityName];
  user.name = name;
  user.password = password;
  if (email.length > 0) {
    user.email = email;
  }

  return user;
}

- (NSString *)name {
  return [[self objectForKey:kDKUserNameField] copy];
}

- (void)setName:(NSString *)name {
  [self setObject:[name copy] forKey:kDKUserNameField];
}

- (NSString *)email {
  return [[self objectForKey:kDKUserEmailField] copy];
}

- (void)setEmail:(NSString *)email {
  [self setObject:[email copy] forKey:kDKUserEmailField];
}

- (NSString *)password {
  return [[self objectForKey:kDKUserPasswdField] copy];
}

- (void)setPassword:(NSString *)password {
  [self setObject:[password copy] forKey:kDKUserPasswdField];
}

- (BOOL)isSignedIn {
  return (self.sessionToken.length > 0);
}

- (BOOL)userNameAndPasswordValid:(NSError **)error {
  if (self.name.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Username invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x100 userInfo:userInfo];
    }
    
    return NO;
  }
  if (self.password.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Password invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x102 userInfo:userInfo];
    }
    
    return NO;
  }
  
  return YES;
}

- (BOOL)signUp:(NSError **)error {
  if (![self userNameAndPasswordValid:error]) {
    return NO;
  }
  if (self.email.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Email invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x101 userInfo:userInfo];
    }
    
    return NO;
  }
  
  // Request params
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

- (BOOL)signIn:(NSError **)error {
  if (![self userNameAndPasswordValid:error]) {
    return NO;
  }
  
  // Request params
  NSDictionary *requestObjects = [NSDictionary dictionaryWithObjectsAndKeys:
                                  self.name, @"name",
                                  self.password, @"passwd", nil];
  
  // Send request synchronously
  DKRequest *request = [DKRequest request];
  request.cachePolicy = DKCachePolicyIgnoreCache;
  
  NSError *requestError = nil;
  self.sessionToken = [request sendRequestWithObject:requestObjects method:@"signIn" error:&requestError];
  if (requestError != nil || self.sessionToken.length == 0) {
    if (error != nil) {
      *error = requestError;
    }
    return NO;
  }
  
  return YES;
}

@end
