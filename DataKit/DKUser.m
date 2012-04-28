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
#import "DKKeychain.h"

@implementation DKUser
DKSynthesize(sessionToken)

#define kDKUserEntityName @"datakit.users"
#define kDKUserNameField @"name"
#define kDKUserEmailField @"email"
#define kDKUserPasswdField @"passwd"
#define kDKUserSessionTokenKey @"sessionToken"

#define kDKUserKeychainServiceName @"com.chocomoko.DataKit.User"

+ (BOOL)signUpUserWithName:(NSString *)name password:(NSString *)password email:(NSString *)email error:(NSError **)error {
  if (name.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Username invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x100 userInfo:userInfo];
    }
    
    return NO;
  }
  if (password.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Password invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x102 userInfo:userInfo];
    }
    
    return NO;
  }
  if (email.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Email invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x101 userInfo:userInfo];
    }
    
    return NO;
  }
  
  // Request params
  NSDictionary *requestObjects = [NSDictionary dictionaryWithObjectsAndKeys:
                                  name, kDKUserNameField,
                                  email, kDKUserEmailField,
                                  password, kDKUserPasswdField, nil];
  
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

+ (BOOL)signInUserWithName:(NSString *)name password:(NSString *)password error:(NSError **)error {
  if (name.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Username invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x100 userInfo:userInfo];
    }
    
    return NO;
  }
  if (password.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Password invalid", nil) forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x102 userInfo:userInfo];
    }
    
    return NO;
  }
  
  // Request params
  NSDictionary *requestObjects = [NSDictionary dictionaryWithObjectsAndKeys:
                                  name, kDKUserNameField,
                                  password, kDKUserPasswdField, nil];
  
  // Send request synchronously
  DKRequest *request = [DKRequest request];
  request.cachePolicy = DKCachePolicyIgnoreCache;
  
  NSError *requestError = nil;
  NSString *sessionToken = [request sendRequestWithObject:requestObjects method:@"signIn" error:&requestError];
  if (requestError != nil || sessionToken.length == 0) {
    if (error != nil) {
      *error = requestError;
    }
    return NO;
  }
  
  // Store user in keychain
  NSMutableDictionary *secureInfo = [NSMutableDictionary dictionaryWithCapacity:3];
  [secureInfo setObject:name forKey:kDKUserNameField];
  [secureInfo setObject:password forKey:kDKUserPasswdField];
  [secureInfo setObject:sessionToken forKey:kDKUserSessionTokenKey];
  
  NSData *secureData = [NSKeyedArchiver archivedDataWithRootObject:secureInfo];
  
  NSError *kcErr = nil;
  BOOL success = [DKKeychain storeSecureData:secureData
                                  forService:kDKUserKeychainServiceName
                                     account:name
                                       error:&kcErr];
  if (!success) {
    NSLog(@"error: could not store session in keychain (%i)", kcErr.code);
    
    return NO;
  }
  
  return YES;
}

+ (instancetype)currentUser {
  NSArray *accounts = [DKKeychain accountsForService:kDKUserKeychainServiceName error:NULL];
  if (accounts.count > 0) {
    NSDictionary *account = [accounts objectAtIndex:0];
    NSString *accountName = [account objectForKey:kDKKeychainAccountName];
    
    if (accountName.length > 0) {
      NSError *kcErr = nil;
      NSData *secureData = [DKKeychain secureDataForService:kDKUserKeychainServiceName account:accountName error:&kcErr];
      
      if (secureData == nil || kcErr != nil) {
        NSLog(@"error: could not read account data (%i)", kcErr.code);
      } else {
        NSDictionary *secureInfo = [NSKeyedUnarchiver unarchiveObjectWithData:secureData];
        
        DKUser *user = [DKUser entityWithName:kDKUserEntityName];
        user.name = [secureInfo objectForKey:kDKUserNameField];
        
        // DEVNOTE: It's probably not a good idea to set the raw password on the entity
        // user.password = [secureInfo objectForKey:kDKUserPasswdField];
        
        user.sessionToken = [secureInfo objectForKey:kDKUserSessionTokenKey];

        return user;
      }
      
    } else {
      NSLog(@"error: could not get account name");
    }
  } else {
    NSLog(@"info: no current user set");
  }
  
  return nil;
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

@end
