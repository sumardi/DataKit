//
//  DKUserTests.m
//  DataKit
//
//  Created by Erik Aigner on 26.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKUserTests.h"

#import "DataKit.h"
#import "DKTests.h"
#import "DKUser-Private.h"
#import "DKEntity-Private.h"

@implementation DKUserTests

- (void)setUp {
  [DKManager setAPIEndpoint:kDKEndpoint];
  [DKManager setAPISecret:kDKSecret];
}

- (void)testUserSignUp {
  // Drop old users
  NSError *dropError = nil;
  BOOL dropped = [DKManager dropDatabase:@"datakit.user" error:&dropError];
  
  STAssertTrue(dropped, nil);
  STAssertNil(dropError, dropError.localizedDescription);
  
  // Check if username length limit works
  NSString *uname = @"eri";
  NSString *upasswd = @"mypasswd";
  NSString *uemail = @"ax76s88sc8s@fakemail.xy";
  
  NSError *error = nil;
  BOOL success = [DKUser signUpUserWithName:uname password:upasswd email:uemail error:&error];
  
  STAssertFalse(success, nil);
  STAssertNotNil(error, nil);
  STAssertEquals(error.code, (NSInteger)100, @"code: %i", error.code);
  if (error != nil) {
    NSLog(@"got error as expected: %@", error.localizedDescription);
  }
  
  // Check if signup works
  uname = @"erik";
  error = nil;
  success = [DKUser signUpUserWithName:uname password:upasswd email:uemail error:&error];
  
  STAssertTrue(success, nil);
  STAssertNil(error, error.localizedDescription);
  
  // Check if signup with dupe email and name returns error correctly
  error = nil;
  success = [DKUser signUpUserWithName:uname password:upasswd email:uemail error:&error];
  
  STAssertFalse(success, nil);
  STAssertNotNil(error, nil);
  STAssertEquals(error.code, (NSInteger)103, @"code: %i", error.code);
  if (error != nil) {
    NSLog(@"got error as expected: %@", error.localizedDescription);
  }
  
  // Check if signup with dupe email returns error correctly
  uname = @"erik2";  
  error = nil;
  success = [DKUser signUpUserWithName:uname password:upasswd email:uemail error:&error];
  
  STAssertFalse(success, nil);
  STAssertNotNil(error, error.localizedDescription);
  STAssertEquals(error.code, (NSInteger)103, @"code: %i", error.code);
  
  // Check if signup with dupe name returns error correctly
  uname = @"erik";
  uemail = @"bx76s88sc8s@fakemail.xy";
  
  error = nil;
  success = [DKUser signUpUserWithName:uname password:upasswd email:uemail error:&error];
  
  STAssertFalse(success, nil);
  STAssertNotNil(error, nil);
  if (error != nil) {
    NSLog(@"got error as expected: %@", error.localizedDescription);
  }
}

- (void)testSignIn {
  // Drop old users
  NSError *dropError = nil;
  BOOL dropped = [DKManager dropDatabase:@"datakit.user" error:&dropError];
  
  STAssertTrue(dropped, nil);
  STAssertNil(dropError, dropError.localizedDescription);
  
  // Create test user
  NSString *uname = @"erik";
  NSString *upasswd = @"mypasswd";
  
  NSError *error = nil;
  BOOL success = [DKUser signUpUserWithName:uname password:upasswd email:@"test@email.xyz" error:&error];
  
  STAssertTrue(success, nil);
  STAssertNil(error, error.localizedDescription);
  
  // Create test user 2
  NSString *uname2 = @"erik2";
  NSString *upasswd2 = @"mypasswd";
  
  error = nil;
  success = [DKUser signUpUserWithName:uname2 password:upasswd2 email:@"test2@email.xyz" error:&error];
  
  STAssertTrue(success, nil);
  STAssertNil(error, error.localizedDescription);
  
  // Try to create user without signup method
  DKUser *manualUser = [DKUser entityWithName:@"datakit.user"];
  [manualUser setObject:@"ManualUser" forKey:@"name"];
  [manualUser setObject:@"mypasswdx" forKey:@"passwd"];
  
  error = nil;
  success = [manualUser save:&error];
  
  STAssertFalse(success, nil);
  STAssertNotNil(error, nil);
  
  // Sign in with wrong credentials
  error = nil;
  success = [DKUser signInUserWithName:uname password:@"wrongpassword" error:&error];
  
  STAssertFalse(success, nil);
  STAssertNotNil(error, nil);
  if (error != nil) {
    NSLog(@"got error as expected: %@", error.localizedDescription);
  }

  // Sign in with correct credentials
  error = nil;
  success = [DKUser signInUserWithName:uname password:upasswd error:&error];
  
  STAssertTrue(success, nil);
  STAssertNil(error, error.localizedDescription);
  
  // Check current user (should be user 1)
  DKUser *user = [DKUser currentUser];

  STAssertEqualObjects(user.name, uname, nil);
  STAssertTrue(user.password.length > 0, nil);
  STAssertTrue(user.sessionToken.length > 0, nil);
  
  // Sign in with user 2
  error = nil;
  success = [DKUser signInUserWithName:uname2 password:upasswd2 error:&error];
  
  STAssertTrue(success, nil);
  STAssertNil(error, error.localizedDescription);
  
  // Check current user (should be user 2)
  DKUser *user2 = [DKUser currentUser];
  
  STAssertEqualObjects(user2.name, uname2, nil);
  STAssertTrue(user2.password.length > 0, nil);
  STAssertTrue(user2.sessionToken.length > 0, nil);
  STAssertFalse([user.sessionToken isEqualToString:user2.sessionToken], nil);
  
  // Save custom property
  [user2 setObject:@"customValue" forKey:@"myval"];
  
  error = nil;
  success = [user2 save:&error];
  
  STAssertTrue(success, nil);
  STAssertNil(error, error.localizedDescription);
  STAssertEqualObjects([user2 objectForKey:@"myval"], @"customValue", nil);
  
  // Save locked property
  [user2 setObject:@"asdf" forKey:@"name"];
  
  error = nil;
  success = [user2 save:&error];
  
  STAssertFalse(success, nil);
  STAssertNotNil(error, nil);
  
  // Sign out
  error = nil;
  success = [DKUser signOut:&error];
  
  STAssertNil(error, error.localizedDescription);
  STAssertTrue(success, nil);
  
  DKUser *user3 = [DKUser currentUser];
  
  STAssertNil(user3, nil);
}

@end
