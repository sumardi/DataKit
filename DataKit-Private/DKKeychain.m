//
//  DKKeychain.m
//  DataKit
//
//  Created by Erik Aigner on 28.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKKeychain.h"

NSString *const kDKKeychainAccountName = @"acct";

@implementation DKKeychain

// Ported parts from SSKeychain by Sam Soffes
//
// Sam's Github: https://github.com/samsoffes
// SSKeychain: https://github.com/samsoffes/sskeychain

+ (NSMutableDictionary *)keychainQueryForService:(NSString *)service account:(NSString *)account {
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
  [dict setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
  if (service.length > 0) {
    [dict setObject:service forKey:(__bridge id)kSecAttrService];
  }
  if (account.length > 0) {
    [dict setObject:service forKey:(__bridge id)kSecAttrAccount];
  }
  
  return dict;
}

+ (BOOL)removePasswordForService:(NSString *)service account:(NSString *)account error:(NSError **)error {
  OSStatus status = DKKeychainStatusInvalidArguments;
  if (service.length > 0) {
    NSMutableDictionary *query = [self keychainQueryForService:service account:account];
    status = SecItemDelete((__bridge CFDictionaryRef)query);
  }
  if (status != noErr && error != NULL) {
    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil];
  }
  
  return (status == noErr);
}

+ (BOOL)storeSecureData:(NSData *)data forService:(NSString *)service account:(NSString *)account error:(NSError **)error {
  OSStatus status = DKKeychainStatusInvalidArguments;
  if (data.length > 0 && service.length > 0 && account.length > 0) {
    [self removePasswordForService:service account:account error:NULL];
    
    NSMutableDictionary *query = [self keychainQueryForService:service account:account];
    [query setObject:data forKey:(__bridge id)kSecValueData];
    
    status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
  }
  if (status != noErr && error != NULL) {
    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil];
  }
  
  return (status == noErr);
}

+ (NSArray *)accountsForService:(NSString *)service error:(NSError **)error {
  OSStatus status = DKKeychainStatusInvalidArguments;
  
  NSMutableDictionary *query = [self keychainQueryForService:service account:nil];
  [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
  [query setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
  
  CFArrayRef result = NULL;
  status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
  if (status != noErr && error != NULL) {
    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil];
  }
  
  return CFBridgingRelease(result);
}

+ (NSData *)secureDataForService:(NSString *)service account:(NSString *)account error:(NSError **)error {
  OSStatus status = DKKeychainStatusInvalidArguments;
  
  CFDataRef result = nil;
  if (service.length > 0 || account.length > 0) {
    NSMutableDictionary *query = [self keychainQueryForService:service account:account];
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
  }
  if (status != noErr && error != NULL) {
    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil];
  }
  
  return CFBridgingRelease(result);
}

@end
