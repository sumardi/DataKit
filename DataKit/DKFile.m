//
//  DKFile.m
//  DataKit
//
//  Created by Erik Aigner on 13.03.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "DKFile.h"

#import "DKManager.h"
#import "DKRequest.h"
#import "DKNetworkActivity.h"
#import "NSURLConnection+Timeout.h"

@interface DKFile ()
@property (nonatomic, assign, readwrite) BOOL isVolatile;
@property (nonatomic, assign, readwrite) BOOL isLoading;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSData *data;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, copy) void (^saveResultBlock)(BOOL success, NSError *error);
@property (nonatomic, copy) void (^loadResultBlock)(BOOL success, NSData *data, NSError *error);
@property (nonatomic, copy) void (^uploadProgressBlock)(NSUInteger bytes, NSUInteger totalBytes);
@property (nonatomic, copy) void (^downloadProgressBlock)(NSUInteger bytes, NSUInteger totalBytes);
@property (nonatomic, strong) NSOutputStream *fileStream;
@property (nonatomic, copy) NSURL *fileURL;
@property (nonatomic, assign) NSUInteger bytesWritten;
@property (nonatomic, assign) NSUInteger bytesExpected;
@end

@implementation DKFile
DKSynthesize(isVolatile)
DKSynthesize(isLoading)
DKSynthesize(name)
DKSynthesize(data)
DKSynthesize(connection)
DKSynthesize(saveResultBlock)
DKSynthesize(loadResultBlock)
DKSynthesize(uploadProgressBlock)
DKSynthesize(downloadProgressBlock)
DKSynthesize(fileStream)
DKSynthesize(fileURL)
DKSynthesize(bytesWritten)
DKSynthesize(bytesExpected)

+ (DKFile *)fileWithData:(NSData *)data {
  return [[self alloc] initWithName:nil data:data];
}

+ (DKFile *)fileWithName:(NSString *)name {
  return [[self alloc] initWithName:name data:nil];
}

+ (DKFile *)fileWithName:(NSString *)name data:(NSData *)data {
  return [[self alloc] initWithName:name data:data];
}

- (id)initWithName:(NSString *)name data:(NSData *)data {
  self = [self init];
  if (self) {
    self.data = data;
    self.name = name;
    self.isVolatile = YES;
  }
  return self;
}

+ (BOOL)fileExists:(NSString *)fileName {
  return [self fileExists:fileName error:NULL];
}

+ (BOOL)fileExists:(NSString *)fileName error:(NSError **)error {
  // Send request synchronously
  DKRequest *request = [DKRequest request];
  request.cachePolicy = DKCachePolicyIgnoreCache;
  
  NSDictionary *dict = [NSDictionary dictionaryWithObject:fileName forKey:@"fileName"];
  
  NSError *requestError = nil;
  [request sendRequestWithObject:dict method:@"exists" error:&requestError];
  if (requestError != nil) {
    if (requestError.code != DKErrorDuplicateKey && error != NULL) {
      *error = requestError;
    }
    return NO;
  }
  return YES;
}

+ (void)fileExists:(NSString *)fileName inBackgroundWithBlock:(void (^)(BOOL exists, NSError *error))block {
  block = [block copy];
  dispatch_queue_t q = dispatch_get_current_queue();
  dispatch_async([DKManager queue], ^{
    NSError *error = nil;
    BOOL exists = [self fileExists:fileName error:&error];
    if (block != NULL) {
      dispatch_async(q, ^{
        block(exists, error); 
      });
    }
  });
}

+ (BOOL)deleteFile:(NSString *)fileName error:(NSError **)error {
  return [self deleteFiles:[NSArray arrayWithObject:fileName] error:error];
}

+ (BOOL)deleteFiles:(NSArray *)fileNames error:(NSError **)error {
  // Create the request  
  DKRequest *request = [DKRequest request];
  request.cachePolicy = DKCachePolicyIgnoreCache;
  
  NSDictionary *dict = [NSDictionary dictionaryWithObject:fileNames forKey:@"files"];
  
  NSError *requestError = nil;
  [request sendRequestWithObject:dict method:@"unlink" error:&requestError];
  if (requestError != nil) {
    if (error != nil) {
      *error = requestError;
    }
    return NO;
  }
  return YES;
}

- (BOOL)delete {
  return [self delete:NULL];
}

- (BOOL)delete:(NSError **)error {
  return [isa deleteFile:self.name error:error];
}

- (void)deleteInBackgroundWithBlock:(void (^)(BOOL success, NSError *error))block {
  block = [block copy];
  dispatch_queue_t q = dispatch_get_current_queue();
  dispatch_async([DKManager queue], ^{
    NSError *error = nil;
    BOOL success = [self delete:&error];
    if (block != NULL) {
      dispatch_async(q, ^{
        block(success, error); 
      });
    }
  });
}

- (NSString *)readAssignedFileName:(NSHTTPURLResponse *)response {
  return [[response allHeaderFields] objectForKey:kDKRequestHeaderAssignedFileName];
}

- (BOOL)saveSynchronous:(BOOL)saveSync
            resultBlock:(void (^)(BOOL success, NSError *error))resultBlock
          progressBlock:(void (^)(NSUInteger bytes, NSUInteger totalBytes))progressBlock
                  error:(NSError **)error {
  // Check if data is set
  if (self.data.length == 0) {
    [NSException raise:NSInternalInconsistencyException format:NSLocalizedString(@"Cannot save file with no data set", nil)];
    return NO;
  }
  
  // Create url request
  NSURL *URL = [DKManager endpointForMethod:@"store"];
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
  
  req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
  req.HTTPBody = self.data;
  req.HTTPMethod = @"POST";
  
  NSString *contentLen = [NSString stringWithFormat:@"%u", self.data.length];
  
  [req setValue:contentLen forHTTPHeaderField:@"Content-Length"];
  [req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
  [req setValue:[DKManager APISecret] forHTTPHeaderField:kDKRequestHeaderSecret];
  if (name_.length > 0) {
    [req setValue:name_ forHTTPHeaderField:kDKRequestHeaderFileName];
  }
  
  // Log
  if ([DKManager requestLogEnabled]) {
    NSLog(@"[FILE] save '%@' (%u bytes)", self.name, self.data.length);
  }
  
  // Start network activity indicator
  self.isLoading = YES;
  [DKNetworkActivity begin];
  
  // Save synchronous
  if (saveSync) {
    NSError *reqError = nil;
    NSHTTPURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response timeout:20.0 error:&reqError];
    
    // End network activity
    self.isLoading = NO;
    [DKNetworkActivity end];
    
    // Parse response
    NSError *parseErr = nil;
    [DKRequest parseResponse:response withData:data error:&parseErr];
    
    if (parseErr == nil) {
      self.name = [self readAssignedFileName:response];
      self.isVolatile = NO;
      return YES;
    }
    else {
      if (error != NULL) {
        *error = parseErr;
      }
    }
  }
  
  // Save asynchronous
  else {
    self.saveResultBlock = resultBlock;
    self.loadResultBlock = nil;
    self.downloadProgressBlock = nil;
    self.uploadProgressBlock = progressBlock;
    
    self.connection = [NSURLConnection connectionWithRequest:req delegate:self];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSRunLoopCommonModes];
    [self.connection start];
  }
  
  return NO;
}

- (BOOL)save {
  return [self save:NULL];
}

- (BOOL)save:(NSError **)error {
  return [self saveSynchronous:YES resultBlock:NULL progressBlock:NULL error:error];
}

- (void)saveInBackgroundWithBlock:(void (^)(BOOL success, NSError *error))block {
  [self saveSynchronous:NO resultBlock:block progressBlock:NULL error:NULL];
}

- (void)saveInBackgroundWithBlock:(void (^)(BOOL success, NSError *error))block progressBlock:(void (^)(NSUInteger bytes, NSUInteger totalBytes))progressBlock {
  [self saveSynchronous:NO resultBlock:block progressBlock:progressBlock error:NULL];
}

- (NSData *)loadSynchronous:(BOOL)loadSync
                resultBlock:(void (^)(BOOL success, NSData *data, NSError *error))resultBlock
              progressBlock:(void (^)(NSUInteger bytes, NSUInteger totalBytes))progressBlock
                      error:(NSError **)error {
  // Check for file name
  if (self.name.length == 0) {
    [NSException raise:NSInternalInconsistencyException
                format:NSLocalizedString(@"Invalid filename", nil)];
    return nil;
  }
  
  // Create url request
  NSURL *URL = [DKManager endpointForMethod:@"stream"];
  
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
  req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
  [req setValue:[DKManager APISecret] forHTTPHeaderField:kDKRequestHeaderSecret];
  if (self.name.length > 0) {
    [req setValue:self.name forHTTPHeaderField:kDKRequestHeaderFileName];
  }
  
  // Log
  if ([DKManager requestLogEnabled]) {
    NSLog(@"[FILE] load '%@'", self.name);
  }
  
  // Start network activity indicator
  self.isLoading = YES;
  [DKNetworkActivity begin];
  
  // Load sync
  if (loadSync) {
    NSError *reqError = nil;
    NSHTTPURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response timeout:20.0 error:&reqError];
    
    // End network activity
    self.isLoading = NO;
    [DKNetworkActivity end];
    
    if (response.statusCode == 200) {
      self.isVolatile = NO;
      return data;
    }
    else {
      if (error != NULL) {
        *error = reqError;
      }
    }
  }
  
  // Load async
  else {
    self.saveResultBlock = nil;
    self.loadResultBlock = resultBlock;
    self.downloadProgressBlock = progressBlock;
    self.uploadProgressBlock = nil;
    self.bytesWritten = 0;
    self.bytesExpected = 0;
    
    [self openTempFileStream];
    
    self.connection = [NSURLConnection connectionWithRequest:req delegate:self];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSRunLoopCommonModes];
    [self.connection start];
  }
  
  return nil;
}

- (NSData *)loadData {
  return [self loadData:NULL];
}

- (NSData *)loadData:(NSError **)error {
  return [self loadSynchronous:YES resultBlock:NULL progressBlock:NULL error:error];
}

- (void)loadDataInBackgroundWithBlock:(void (^)(BOOL success, NSData *data, NSError *error))block {
  [self loadDataInBackgroundWithBlock:block progressBlock:NULL];
}

- (void)loadDataInBackgroundWithBlock:(void (^)(BOOL success, NSData *data, NSError *error))block progressBlock:(void (^)(NSUInteger bytes, NSUInteger totalBytes))progressBlock {
  [self loadSynchronous:NO resultBlock:block progressBlock:progressBlock error:NULL];
}

- (void)abort {
  [self.connection cancel];
  [self closeStreamAndCleanUpTempFiles];
  
  // When the connection is cancelled we will not receive any delegate messages,
  // so we have to end the network activity manually.
  if (self.isLoading) {
    self.isLoading = NO;
    [DKNetworkActivity end];
  }
  
  if (self.saveResultBlock != nil) {
    self.saveResultBlock(NO, nil);
  }
  else if (self.loadResultBlock != nil) {
    self.loadResultBlock(NO, nil, nil);
  }
}

- (NSURL *)generatePublicURL:(NSError **)error {
  if (self.name.length == 0) {
    if (error != NULL) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Invalid file name", nil)
                                                           forKey:NSLocalizedDescriptionKey];
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0x100 userInfo:userInfo];
    }
    return nil;
  }
  
  // Create request dict
  NSMutableDictionary *requestDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      self.name, @"fileName", nil];
  
  // Send request synchronously
  DKRequest *request = [DKRequest request];
  request.cachePolicy = DKCachePolicyIgnoreCache;
  
  NSError *requestError = nil;
  NSDictionary *dict = [request sendRequestWithObject:requestDict method:@"publish" error:&requestError];
  if (requestError != nil || ![dict isKindOfClass:[NSDictionary class]]) {
    if (error != NULL) {
      *error = requestError;
    }
    return nil;
  }
  
  NSString *ep = [DKManager APIEndpoint];
  NSString *key = [dict objectForKey:@"key"];
  NSString *path = [@"public" stringByAppendingPathComponent:key];
  NSString *absoluteString = [NSString stringWithFormat:@"%@/%@", ep, path];
  
  return [NSURL URLWithString:absoluteString]; 
}

- (void)generatePublicURLInBackgroundWithBlock:(void (^)(NSURL *publicURL, NSError *error))block {
  block = [block copy];
  dispatch_queue_t q = dispatch_get_current_queue();
  dispatch_async([DKManager queue], ^{
    NSError *error = nil;
    NSURL *url = [self generatePublicURL:&error];
    if (block != NULL) {
      dispatch_async(q, ^{
        block(url, error); 
      });
    }
  });
}

#pragma mark - Private

- (void)openTempFileStream {
  [self closeStreamAndCleanUpTempFiles];
  
  CFUUIDRef uuidRef = CFUUIDCreate(NULL);
  NSString *uuid = CFBridgingRelease(CFUUIDCreateString(NULL, uuidRef));
  CFRelease(uuidRef);
  
  self.fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:uuid]];
  self.fileStream = [NSOutputStream outputStreamWithURL:self.fileURL append:NO];
  
  [self.fileStream open];
}

- (void)closeStreamAndCleanUpTempFiles {
  // Close file stream
  [self.fileStream close];
  self.fileStream = nil;
  
  // Remove temp file
  NSError *error = nil;
  if (![[NSFileManager defaultManager] removeItemAtURL:self.fileURL error:&error]) {
    NSLog(@"error: could not remove temp file (reason: '%@')", error.localizedDescription);
  }
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  // End network activity
  self.isLoading = NO;
  [DKNetworkActivity end];
  
  if (self.saveResultBlock != nil) {
    self.saveResultBlock(NO, error);
  }
  else if (self.loadResultBlock != nil) {
    self.loadResultBlock(NO, nil, error);
  }
  [self closeStreamAndCleanUpTempFiles];
  [connection cancel];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  if ([self.fileStream hasSpaceAvailable]) {
    [self.fileStream write:data.bytes maxLength:data.length];
    self.bytesWritten += data.length;
    if (self.downloadProgressBlock != nil) {
      self.downloadProgressBlock(self.bytesWritten, self.bytesExpected);
    }
  }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  // End network activity
  self.isLoading = NO;
  [DKNetworkActivity end];
  
  if (self.loadResultBlock != nil) {
    self.loadResultBlock(YES, [NSData dataWithContentsOfURL:self.fileURL], nil);
  }
  [self closeStreamAndCleanUpTempFiles];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
    return;
  }
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
  
  if (self.saveResultBlock != nil) {
    NSError *error = nil;    
    if (httpResponse.statusCode == 200 /* HTTP: Created */) {
      self.name = [self readAssignedFileName:httpResponse];
      self.isVolatile = NO;
      self.saveResultBlock(YES, nil);
    }
    else if (httpResponse.statusCode == 400 /* HTTP: Conflict */) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"File already exists", nil)
                                                           forKey:NSLocalizedDescriptionKey];
      error = [NSError errorWithDomain:NSCocoaErrorDomain code:409 userInfo:userInfo];
    }
    else {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Unknown server response", nil)
                                                           forKey:NSLocalizedDescriptionKey];
      error = [NSError errorWithDomain:NSCocoaErrorDomain code:500 userInfo:userInfo];
    }
    
    // Abort and pass error
    if (error != NULL) {
      [connection cancel];
      self.saveResultBlock(NO, error);
    }
  }
  else if (self.loadResultBlock != nil) {
    NSDictionary *headers = [httpResponse allHeaderFields];
    for (NSString *key in headers) {
      if ([key caseInsensitiveCompare:@"Content-Length"] == NSOrderedSame) {
        NSString *len = [headers objectForKey:key];
        self.bytesExpected = [len integerValue];
        break;
      }
    }
  }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
  if (self.uploadProgressBlock != nil) {
    self.uploadProgressBlock(totalBytesWritten, totalBytesExpectedToWrite);
  }
}

@end