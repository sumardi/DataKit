//
//  DKKeychain.h
//  DataKit
//
//  Created by Erik Aigner on 28.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
  DKKeychainStatusInvalidArguments = 0x100
};
typedef NSInteger DKKeychainStatus;

extern NSString *const kDKKeychainAccountName;

@interface DKKeychain : NSObject

+ (BOOL)removePasswordForService:(NSString *)service account:(NSString *)account error:(NSError **)error;
+ (BOOL)storeSecureData:(NSData *)data forService:(NSString *)service account:(NSString *)account error:(NSError **)error;
+ (NSArray *)accountsForService:(NSString *)service error:(NSError **)error;
+ (NSData *)secureDataForService:(NSString *)service account:(NSString *)account error:(NSError **)error;

@end
