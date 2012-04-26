//
//  DKUser.h
//  DataKit
//
//  Created by Erik Aigner on 25.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKEntity.h"

@interface DKUser : DKEntity
@property (nonatomic, readonly) BOOL isSignedIn;
@property (nonatomic, readonly) BOOL isNew;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *password;
@property (nonatomic, copy, readonly) NSString *email;

+ (DKUser *)lastAuthenticatedUser;
+ (DKUser *)userWithName:(NSString *)name password:(NSString *)password email:(NSString *)email;

- (BOOL)signUp:(NSError **)error;
- (BOOL)signIn:(NSError **)error;
- (BOOL)signOut:(NSError **)error;
- (BOOL)requestPasswordResetEmail:(NSError **)error;

+ (id)new UNAVAILABLE_ATTRIBUTE;
- (id)init UNAVAILABLE_ATTRIBUTE;

@end
