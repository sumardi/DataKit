//
//  DKUser-Private.h
//  DataKit
//
//  Created by Erik Aigner on 26.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKUser.h"

@interface DKUser ()
@property (nonatomic, copy, readwrite) NSString *sessionToken;

+ (BOOL)userNameAndPasswordValid:(NSError **)error;

- (BOOL)deleteCurrentUser:(NSError **)error;

@end
