//
//  DKUser.h
//  DataKit
//
//  Created by Erik Aigner on 25.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKEntity.h"

#define UNIMPLEMENTED_ATTRIBUTE

@interface DKUser : DKEntity
@property (nonatomic, readonly) BOOL isNew UNIMPLEMENTED_ATTRIBUTE;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *email;

+ (BOOL)signUpUserWithName:(NSString *)name password:(NSString *)password email:(NSString *)email error:(NSError **)error;
+ (BOOL)signInUserWithName:(NSString *)name password:(NSString *)password error:(NSError **)error;
+ (instancetype)currentUser;
+ (BOOL)signOut:(NSError **)error;

+ (BOOL)requestPasswordResetForUsername:(NSString *)name orEmail:(NSString *)email error:(NSError **)error UNIMPLEMENTED_ATTRIBUTE;

@end
