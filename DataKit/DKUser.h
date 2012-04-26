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
@property (nonatomic, readonly) BOOL isSignedIn UNIMPLEMENTED_ATTRIBUTE;
@property (nonatomic, readonly) BOOL isNew UNIMPLEMENTED_ATTRIBUTE;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *email;

+ (instancetype)lastAuthenticatedUser UNIMPLEMENTED_ATTRIBUTE;
+ (instancetype)userWithName:(NSString *)name password:(NSString *)password email:(NSString *)email;

- (BOOL)signUp:(NSError **)error;
- (BOOL)signIn:(NSError **)error UNIMPLEMENTED_ATTRIBUTE;
- (BOOL)signOut:(NSError **)error UNIMPLEMENTED_ATTRIBUTE;
- (BOOL)requestPasswordResetEmail:(NSError **)error UNIMPLEMENTED_ATTRIBUTE;

- (void)setPasswordHashed:(NSString *)passwordToHash;

@end
