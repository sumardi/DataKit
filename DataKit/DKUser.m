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

+ (instancetype)signUpUserWithName:(NSString *)name password:(NSString *)password email:(NSString *)email error:(NSError **)error {
  if (name.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Username invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x100 userInfo:userInfo];
    }
    
    return nil;
  }
  if (password.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Password invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x102 userInfo:userInfo];
    }
    
    return nil;
  }
  if (email.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Email invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x101 userInfo:userInfo];
    }
    
    return nil;
  }
  
  // Request params
  NSDictionary *requestObjects = [NSDictionary dictionaryWithObjectsAndKeys:
                                  name, @"name",
                                  email, @"email",
                                  password, @"passwd", nil];
  
  // Send request synchronously
  DKRequest *request = [DKRequest request];
  request.cachePolicy = DKCachePolicyIgnoreCache;
  
  NSError *requestError = nil;
  [request sendRequestWithObject:requestObjects method:@"signUp" error:&requestError];
  if (requestError != nil) {
    if (error != nil) {
      *error = requestError;
    }
    return nil;
  }
  
  // Create user and return
  DKUser *user = [DKUser entityWithName:kDKUserEntityName];
  user.name = name;
  user.email = email;
  user.password = password;
  
  return user;
}

+ (instancetype)signInUserWithName:(NSString *)name password:(NSString *)password error:(NSError **)error {
  if (name.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Username invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x100 userInfo:userInfo];
    }
    
    return nil;
  }
  if (password.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Password invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x102 userInfo:userInfo];
    }
    
    return nil;
  }
  
  // Request params
  NSDictionary *requestObjects = [NSDictionary dictionaryWithObjectsAndKeys:
                                  name, @"name",
                                  password, @"passwd", nil];
  
  // Send request synchronously
  DKRequest *request = [DKRequest request];
  request.cachePolicy = DKCachePolicyIgnoreCache;
  
  NSError *requestError = nil;
  NSString *sessionToken = [request sendRequestWithObject:requestObjects method:@"signIn" error:&requestError];
  if (requestError != nil || sessionToken.length == 0) {
    if (error != nil) {
      *error = requestError;
    }
    return nil;
  }
  
  // Create user and return
  DKUser *user = [DKUser entityWithName:kDKUserEntityName];
  user.name = name;
  user.password = password;
  user.sessionToken = sessionToken;
  
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

@end
