//
//  DKUser.h
//  DataKit
//
//  Created by Erik Aigner on 25.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKEntity.h"

#define UNIMPLEMENTED_ATTRIBUTE

/**
 Class for accessing the user auth system.
 */
@interface DKUser : DKEntity
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *password;
@property (nonatomic, copy, readonly) NSString *email;
@property (nonatomic, readonly) BOOL isSignedIn;
@property (nonatomic, copy, readonly) NSString *sessionToken;

+ (BOOL)signUpUserWithName:(NSString *)name password:(NSString *)password email:(NSString *)email error:(NSError **)error;
+ (instancetype)signInUserWithName:(NSString *)name password:(NSString *)password error:(NSError **)error;
+ (instancetype)currentUser;
+ (BOOL)signOut:(NSError **)error;
+ (BOOL)deleteCurrentUser:(NSError **)error;

+ (BOOL)requestPasswordResetForUsername:(NSString *)name orEmail:(NSString *)email error:(NSError **)error UNIMPLEMENTED_ATTRIBUTE;

/** @name Deleting Users */

- (BOOL)delete UNAVAILABLE_ATTRIBUTE;
- (BOOL)delete:(NSError **)error UNAVAILABLE_ATTRIBUTE;
- (void)deleteInBackground UNAVAILABLE_ATTRIBUTE;
- (void)deleteInBackgroundWithBlock:(void (^)(DKEntity *, NSError *))block UNAVAILABLE_ATTRIBUTE;

@end
