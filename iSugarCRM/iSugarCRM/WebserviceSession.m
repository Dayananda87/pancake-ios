//
//  WebserviceSession.m
//  iSugarCRM
//
//  Created by Ved Surtani on 23/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "WebserviceSession.h"
#import "DataObject.h"
#import "DataObjectField.h"
#import "JSONKit.h"
#import "SyncHandler.h"
#define HTTPStatusOK 200
@interface WebserviceSession()
@property (assign)BOOL done;
@property (strong)NSURLConnection *conn;
@property (strong)NSURLRequest *req;
@property (strong)NSMutableData *responseData;
-(void) loadUrl:(NSURLRequest*) urlRequest;
-(void) finish;
@end

@implementation WebserviceSession
@synthesize uploadDataObjects;
@synthesize conn,req,responseData,done;
@synthesize metadata,syncAction,parent;
@synthesize executing = _isExecuting;
@synthesize finished = _isFinished ;
@synthesize completionBlock = _completionBlock;
@synthesize errorBlock = _errorBlock;

+(WebserviceSession*)sessionWithMetadata:(WebserviceMetadata*)metadata
{
    WebserviceSession *session = [[WebserviceSession alloc] init];
    session.metadata = metadata;
    return session;
}

-(void)startLoading:(NSString*)timestamp
{
    NSURLRequest *request = [metadata getRequestWithLastSyncTimestamp:timestamp];
    [self loadUrl:request];    
}

-(void) startLoadingWithStartDate:(NSString *)startDate endDate:(NSString *)endDate
{
    NSURLRequest *request = [metadata getRequestWithStartDate:startDate endDate:endDate];
    [self loadUrl:request];
}

-(void) startLoadingWithTimestamp:(NSString *)timestamp startDate:(NSString*)startDate endDate:(NSString*)endDate{
    NSURLRequest *request = [metadata getRequestWithLastSyncTimestamp:timestamp startDate:startDate endDate:endDate];
    [self loadUrl:request];

}

-(void)startUploading
{ 
    if(self.uploadDataObjects != nil){
        // Converting Dataobject to Namevalue arrays before posting . This should happed only here. 
        // Removed the conversion from one to other at all other places
        NSMutableArray* uploadObjects = [[NSMutableArray alloc] initWithCapacity:uploadDataObjects.count];
        for(DataObject* dataObject in uploadDataObjects)
        {
            [uploadObjects addObject:[dataObject nameValueArray]];
        }
        NSURLRequest *request = [metadata getWriteRequestWithData:uploadObjects];
        [self loadUrl:request]; 
    }
}


-(void) loadUrl:(NSURLRequest *)urlRequest
{
    self.req = urlRequest;
    [[SyncHandler sharedInstance] addSyncSession:self];
}

- (void)finish
{   
    //clean up
    conn = nil;
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _isExecuting = NO;
    _isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark NSOperation main

- (void)main
{
    self.done = NO;
    
    conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (conn != nil) {
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!done);
    }
    [self finish];
}

#pragma mark NSURLConnectionDataDelegate Methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{   
    if (self.errorBlock != nil ) {
        self.errorBlock(error, self.metadata.moduleName);
    }
    self.done = YES;
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSInteger errorCode = [(NSHTTPURLResponse*)response statusCode];
    if (errorCode == HTTPStatusOK){
        if(syncAction == kWrite){
            //return success or should wait for the response?   
           // [delegate sessionDidCompleteUploadSuccessfully:self]; should send a call back or not?
        } else if (syncAction == kRead){
//            if (delegate != nil && [delegate respondsToSelector:@selector(sessionWillStartLoading:)]) {
//                [delegate sessionWillStartLoading:self];
//            }
        }
    } else {
            if ( self.errorBlock != nil ){
                self.errorBlock([NSError errorWithDomain:@"HTTP ERROR" code:errorCode userInfo:nil], self.metadata.moduleName);
           }
        self.done = YES;
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (self.responseData == nil) {
        self.responseData = [NSMutableData data];
    }
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //parse only in data sync(download)
    
    if (syncAction == kWrite) {
        if (self.done == NO) {
            if ( nil != self.completionBlock) {
                self.completionBlock(nil, self.metadata.moduleName, self.syncAction, self.uploadDataObjects);
            }
        }
    }  
    else  
    { //read
        NSDictionary *responseDictionary = [self.responseData objectFromJSONData]; //parse using some parser
        id responseObjects = [responseDictionary valueForKeyPath:metadata.pathToObjectsInResponse];
        id relationshipList = [responseDictionary valueForKeyPath:metadata.pathToRelationshipInResponse];
      //    NSLog(@"response object for module: %@ data: %@",metadata.moduleName,responseObjects);
        if([responseObjects isKindOfClass:[NSDictionary class]]){
            responseObjects = [NSArray arrayWithObject:responseObjects];
        }
        NSMutableArray *arrayOfDataObjects = [[NSMutableArray alloc] init];
        int count = 0;
        for(NSDictionary *responseObject in responseObjects)
        { 
            @try {
                DataObjectMetadata *objectMetadata = [[SugarCRMMetadataStore sharedInstance] objectMetadataForModule:self.metadata.moduleName];
                DataObject *dataObject = [[DataObject alloc] initWithMetadata:objectMetadata];
                for(DataObjectField *field in [[objectMetadata fields] allObjects]) 
                {   
                    id value = [responseObject valueForKeyPath:[metadata.responseKeyPathMap objectForKey:field.name]];
                    if (value == nil) {
                        [dataObject setObject:@" " forFieldName:field.name];
                    } else {
                        [dataObject setObject:value forFieldName:field.name];
                    }
                    
                }
                if ([relationshipList count]>0) {
                NSArray *relationships = [[relationshipList objectAtIndex:count] objectForKey:[metadata.responseKeyPathMap objectForKey:@"relation_list"]];
                for(NSDictionary *relationship in relationships){
                    NSString* relatedModule = [relationship valueForKeyPath:[metadata.responseKeyPathMap objectForKey:@"related_module"]];
                    NSMutableArray *beanIds = [NSMutableArray array];
                    for(NSDictionary * bean in  [relationship valueForKeyPath:[metadata.responseKeyPathMap objectForKey:@"related_module_records"]]){
                        [beanIds addObject:[bean valueForKeyPath:[metadata.responseKeyPathMap objectForKey:@"related_record"]]];
                    }
                    if ([beanIds count]>0) {
                        [dataObject addRelationshipWithModule:relatedModule andBeans:beanIds]; 
                    }
                }
                }
                [arrayOfDataObjects addObject:dataObject];
                count++;
            }
            @catch (NSException *exception) {
                NSLog(@"Error Parsing Data with Exception = %@, %@",[exception name],[exception description]);
            }
        }
        if ( nil != self.completionBlock) {
            self.completionBlock(arrayOfDataObjects, self.metadata.moduleName, self.syncAction, nil);
        }
    }
    self.done = YES;
}


@end
