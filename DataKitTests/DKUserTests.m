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

@implementation DKUserTests

- (void)setUp {
  [DKManager setAPIEndpoint:kDKEndpoint];
  [DKManager setAPISecret:kDKSecret];
}

- (void)testUserSignUp {
  // Drop old users
  NSError *dropError = nil;
  BOOL dropped = [DKManager dropDatabase:@"datakit.users" error:&dropError];
  
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
  BOOL dropped = [DKManager dropDatabase:@"datakit.users" error:&dropError];
  
  STAssertTrue(dropped, nil);
  STAssertNil(dropError, dropError.localizedDescription);
  
  // Create test user
  NSString *uname = @"erik";
  NSString *upasswd = @"mypasswd";
  
  NSError *error = nil;
  BOOL success = [DKUser signUpUserWithName:uname password:upasswd email:@"test@email.xyz" error:&error];
  
  STAssertTrue(success, nil);
  STAssertNil(error, error.localizedDescription);
  
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
}

@end
