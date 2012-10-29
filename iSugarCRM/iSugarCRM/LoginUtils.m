//
//  LoginUtils.m
//  iSugarCRM
//
//  Created by pramati on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginUtils.h"
#import "JSONKit.h"
#import "ApplicationKeyStore.h"
#import "SettingsStore.h"
#import <CommonCrypto/CommonDigest.h>
#import "AppDelegate.h"

@implementation LoginUtils

+(id) loginWithUsername:(NSString*) username password:(NSString*) password andUrl:(NSString *)url
{
    NSMutableDictionary *authDictionary=[[NSMutableDictionary alloc]init];
    [authDictionary setObject:username forKey:@"user_name"];
    [authDictionary setObject:password forKey:@"password"];
    NSMutableDictionary* restDataDictionary=[[NSMutableDictionary alloc]init];
    [restDataDictionary setObject:authDictionary forKey:@"user_auth"];
    [restDataDictionary setObject:@"soap_test" forKey:@"application"];
    NSMutableDictionary* urlParams=[[NSMutableDictionary alloc] init];
    [urlParams setObject:@"login" forKey:@"method"];
    [urlParams setObject:@"JSON" forKey:@"input_type"];
    [urlParams setObject:@"JSON" forKey:@"response_type"];
    [urlParams setObject:restDataDictionary forKey:@"rest_data"];
    //NSString* urlString = [[NSString stringWithFormat:@"%@",[self urlStringForParams:urlParams]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSString* urlString = [[NSString stringWithFormat:@"%@",[self urlString:url forParams:urlParams]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSLog(@"URLSTRING = %@",urlString);
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];  
    NSURLResponse* response = [[NSURLResponse alloc] init]; 
    NSError* error=nil;
    NSDictionary *result = nil;
    NSData* adata = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
   
    if (error == nil) {
        result = [[NSDictionary alloc]initWithObjectsAndKeys:
                   [adata objectFromJSONData],@"response",
                    nil];

    }else{
        result = [[NSDictionary alloc]initWithObjectsAndKeys:
                  (NSError *)error, @"Error",
                  nil];
    }
    return result;
}


+(BOOL) seamLessLogin
{
    NSError *error = nil;
    BOOL isSuccesfull = YES;
    if(session)
    {
        NSMutableDictionary* restDataDictionary=[[NSMutableDictionary alloc]init];
        [restDataDictionary setObject:session forKey:@"session"];
        NSMutableDictionary* urlParams=[[NSMutableDictionary alloc] init];
        [urlParams setObject:@"seamless_login" forKey:@"method"];
        [urlParams setObject:@"JSON" forKey:@"input_type"];
        [urlParams setObject:@"JSON" forKey:@"response_type"];
        [urlParams setObject:restDataDictionary forKey:@"rest_data"];
        //NSString* urlString = [[NSString stringWithFormat:@"%@",[self urlStringForParams:urlParams]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        NSString* urlString = [[NSString stringWithFormat:@"%@",[self urlString:[SettingsStore objectForKey:@"endpointURL"] forParams:urlParams]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        NSLog(@"URLSTRING = %@",urlString);
        NSMutableURLRequest* request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:@"POST"];  
        NSURLResponse* response = [[NSURLResponse alloc] init]; 
        error=nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        [data length];
        NSUInteger len = [data length];
        Byte *byteData = (Byte*)malloc(len);
        [data getBytes:byteData length:[data length]];
        NSString *responseValue = [NSString stringWithFormat:@"%s",byteData];
        NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
        if (data== nil) {
            [resultDict setObject:@"" forKey:@"data"];
        }
        else
        {
            NSString *str = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
            [resultDict setObject:str forKey:@"data"];
        }
        [resultDict setObject:responseValue forKey:@"statuscode"];
        if (![responseValue isEqualToString:@"1"]) {
            id response =[LoginUtils login];
            session = [[response objectForKey:@"response"]objectForKey:@"id"];
            if(!session){
                 dispatch_async(dispatch_get_main_queue(), ^(void) {
                     [LoginUtils displayLoginError:response];
                 });
                isSuccesfull = NO;
            }
        }
    }
    else
    {
        id response =[LoginUtils login];
        session = [[response objectForKey:@"response"]objectForKey:@"id"];
        if(!session){
            [LoginUtils displayLoginError:response];
            isSuccesfull = NO;
        }
    }
    return isSuccesfull;
}

+(BOOL)keyChainHasUserData
{
    int passwordLen;
    ApplicationKeyStore *keyChain = [[ApplicationKeyStore alloc]initWithName:@"iSugarCRM-keystore"];
    if([[NSUserDefaults standardUserDefaults] objectForKey:kAppAuthenticationState] == nil)
    {
        [keyChain.keyChainData setObject:@"" forKey:(__bridge id)kSecAttrAccount];
        [keyChain.keyChainData setObject:(id)@"iSugarCRM-keystore" forKey:(__bridge id)kSecAttrGeneric];
        [keyChain.keyChainData setObject:(__bridge id)kSecAttrAccessibleAlwaysThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
        [keyChain.keyChainData setObject:@"" forKey:(__bridge id)kSecValueData];
    }
    passwordLen = [[keyChain objectForKey:(__bridge id)kSecValueData] length];
    
    if(passwordLen == 0){
        return FALSE;
    }else{
        return TRUE;
    }
}

+(id)login
{
    NSString *username,*password,*url;
    ApplicationKeyStore *keyChain = [[ApplicationKeyStore alloc]initWithName:@"iSugarCRM-keystore"];
    username = [keyChain objectForKey:(__bridge id)kSecAttrAccount];
    password = [keyChain objectForKey:(__bridge id)kSecValueData];
    url = [[NSUserDefaults standardUserDefaults] objectForKey:@"endpointURL"];
    return [self loginWithUsername:username password:[self md5Hash:password] andUrl:(NSString *)url];
    //return [self login:username :[self md5Hash:password]];
}

+(void)displayLoginError:(id)response
{
    AppDelegate *sharedAppDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;    
    [sharedAppDelegate performSelectorInBackground:@selector(dismissWaitingAlert) withObject:nil];
    if([response objectForKey:@"Error"])
    {
        [self showError:[response objectForKey:@"Error"]];
    }
    else
    {
        NSString  *errorDescription,*errorName;
        if([[[response objectForKey:@"response"]objectForKey:@"name"] length]!=0){
            errorName = [[response objectForKey:@"response"]objectForKey:@"name"];
        }else{
            errorName = @"Invalid Login";
        }
        
        if([[[response objectForKey:@"response"]objectForKey:@"description"] length]!=0){
            errorDescription = [[response objectForKey:@"response"]objectForKey:@"description"];
        }else{
            errorDescription = @"Login attempt failed please check the username and password";
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:errorName message:errorDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [self showAlert:alertView];
    }
}

+(NSString*)urlString:(NSString *)url forParams:(NSMutableDictionary*)params
{
    NSString* urlString  = [NSString stringWithFormat:@"%@?",url];//[NSString stringWithFormat:@"%@?",sugarEndpoint];
    
    bool is_first=YES;
    for(id key in [params allKeys])
    {
        if(![[key description] isEqualToString:@"rest_data"]){   
            
            if (is_first) {
                urlString=[urlString stringByAppendingString:[NSString stringWithFormat:@"%@=%@",key,[params objectForKey:key]]];
                is_first=NO;
            }
            else{
                urlString=[urlString stringByAppendingString:[NSString stringWithFormat:@"&%@=%@",key,[params objectForKey:key]]];
            }
        }
        else{
            if (is_first) {
                urlString=[urlString stringByAppendingString:[NSString stringWithFormat:@"%@=%@",key,[[params objectForKey:key]JSONString ]]];
                is_first=NO;
            }
            else{
                urlString=[urlString stringByAppendingString:[NSString stringWithFormat:@"&%@=%@",key,[[params objectForKey:key]JSONString]]];
            }
            
        }
    }
    NSLog(@"%@",urlString);
    return urlString;
}

+(void) showError:(NSError *)error
{
    //[spinner setHidden:YES];
    //    UIWindow *appWindow = (UIWindow* ) [UIApplication sharedApplication].keyWindow;
    //    appWindow.rootViewController = self;
    NSString *messageString = [error localizedDescription];//customize this message with network error.code;
    NSLog(@"Code-->%d",[error code]);
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:messageString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [self showAlert:alertView];
}

+ (void) showAlert:(UIAlertView*) alert
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        [alert show];
    });
}

+ (NSString *) md5Hash:(NSString*)string
{
    const char *cStr = [string UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], 
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];  
}
@end
