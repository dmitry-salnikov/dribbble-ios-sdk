//
//  DROAuthManager.m
//  
//
//  Created by Vladimir Zgonik on 31.03.15.
//  Copyright (c) 2015 Agilie. All rights reserved.
//

#import "DribbbleSDK.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMOAuth2Authentication.h"

@interface DROAuthManager ()

@property (strong, nonatomic) UIWebView *webView;

@property (strong, nonatomic) id<NSObject> authCompletionObserver;
@property (strong, nonatomic) id<NSObject> authErrorObserver;

@property (strong, nonatomic) NSString *redirectUrl;

@property (copy, nonatomic) DROAuthHandler authHandler;

@end

@implementation DROAuthManager

- (GTMOAuth2ViewControllerTouch *)retrieveSignInControllerWithSettings:(DRApiClientSettings *)settings authHandler:(DROAuthHandler)authHandler {
    self.authHandler = authHandler;
    GTMOAuth2Authentication *auth = [GTMOAuth2Authentication authenticationWithServiceProvider:kIDMOAccountType
                                                      tokenURL:[NSURL URLWithString:settings.oAuth2TokenUrl]
                                                   redirectURI:settings.oAuth2RedirectUrl
                                                      clientID:settings.clientId
                                                  clientSecret:settings.clientSecret];
    auth.scope = [[settings.scopes allObjects] componentsJoinedByString:@"+"];
    NSURL *authURL = [NSURL URLWithString:settings.oAuth2AuthorizationUrl];
    
    // Display the authentication view
    GTMOAuth2ViewControllerTouch *viewController;
    viewController = [[GTMOAuth2ViewControllerTouch alloc] initWithAuthentication:auth
                                                                  authorizationURL:authURL
                                                                  keychainItemName:kIDMOAccountType
                                                                          delegate:self
                                                                  finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    return viewController;
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    NSError *payloadError = error;
    if (error) {
        NSString *errorTitle = auth.parameters[@"error"];
        NSString *errorMessage = auth.parameters[@"error_description"];
        if (errorTitle && errorMessage) {
            payloadError = [NSError errorWithDomain:error.domain
                                               code:error.code
                                           userInfo:@{ NSLocalizedDescriptionKey : errorMessage ?: errorTitle,
                                                       NSLocalizedFailureReasonErrorKey : errorTitle ?: @"unknown"}];
        }
    }
    [self finalizeAuthWithAccount:auth error:payloadError];
}

- (void)finalizeAuthWithAccount:(GTMOAuth2Authentication *)auth error:(NSError *)error {
    if (self.authHandler) {
        self.authHandler(auth, error);
        self.authHandler = nil;
    }
}

#pragma mark - OAuth2 Logic
//
//- (void)authorizeWithWebView:(UIWebView *)webView settings:(DRApiClientSettings *)settings authHandler:(DROAuthHandler)authHandler {
//    self.authHandler = authHandler;
//    
//    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
//    if (self.authCompletionObserver) [notificationCenter removeObserver:self.authCompletionObserver];
//    if (self.authErrorObserver) [notificationCenter removeObserver:self.authErrorObserver];
//    __weak typeof(self)weakSelf = self;
//    
//    self.authCompletionObserver = [notificationCenter addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *aNotification) {
//        NXOAuth2Account *account = [[aNotification userInfo] objectForKey:NXOAuth2AccountStoreNewAccountUserInfoKey];
//        DRLog(@"We have token in OAuthManager:%@", account.accessToken.accessToken);
//        if (account.accessToken.accessToken) {
//            [weakSelf finalizeAuthWithAccount:account error:nil];
//        } else {
//            [weakSelf finalizeAuthWithAccount:nil error:[NSError errorWithDomain:kDROAuthErrorDomain code:kHttpAuthErrorCode userInfo:nil]];
//        }
//        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf.authCompletionObserver];
//    }];
//    self.authErrorObserver = [notificationCenter addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *aNotification) {
//        NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
//        
//        NSData *responseData = error.userInfo[@"responseData"];
//        if (responseData) {
//            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
//            NSString *errorText = responseDict[@"error"];
//            NSString *errorDesc = responseDict[@"error_description"];
//            NSDictionary *userInfo = nil;
//            if (errorText && errorDesc) {
//                userInfo = @{ NSLocalizedDescriptionKey : errorDesc, kDROAuthErrorFailureKey : errorText, NSUnderlyingErrorKey : error };
//            }
//            NSError *bodyError = [[NSError alloc] initWithDomain:kDROAuthErrorDomain code:kHttpAuthErrorCode userInfo:userInfo];
//            [weakSelf finalizeAuthWithAccount:nil error:bodyError];
//        } else {
//            [weakSelf finalizeAuthWithAccount:nil error:error];
//        }
//
//        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf.authErrorObserver];
//    }];
//
//    [self requestAuthorizationWebView:webView withSettings:settings];
//}

#pragma mark - WebView Delegate
//
//- (void)webViewDidFinishLoad:(UIWebView *)webView {
//    
//}
//
//- (BOOL)isUrlRedirectUrl:(NSURL *)url {
//    NSURL *authUrl = [NSURL URLWithString:self.redirectUrl];
//    return ([[authUrl host] isEqualToString:url.host] && [[authUrl scheme] isEqualToString:url.scheme]);
//}
//
//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    if ([self isUrlRedirectUrl:request.URL]) {
//        self.webView.userInteractionEnabled = YES;
//        NSDictionary *params = [self paramsFromUrl:request.URL];
//        if ([params objectForKey:@"code"]) {
//            [[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:kIDMOAccountType] enumerateObjectsUsingBlock:^(NXOAuth2Account * obj, NSUInteger idx, BOOL *stop) {
//                [[NXOAuth2AccountStore sharedStore] removeAccount:obj];
//            }];
//            [[NXOAuth2AccountStore sharedStore] handleRedirectURL:request.URL];
//        } else {
//            self.webView.userInteractionEnabled = NO;
//        }
//        DRLog(@"webView:shouldStartLoadWithRequest returned NO for request: %@", request);
//        return NO;
//    } else if ([request.URL.absoluteString rangeOfString:kUnacceptableWebViewUrl options:NSCaseInsensitiveSearch].location != NSNotFound) {
//        NSError *error = [NSError errorWithDomain:kDROAuthErrorDomain code:kDROAuthErrorCodeUnacceptableRedirectUrl userInfo:@{ NSLocalizedDescriptionKey : kDROAuthErrorUnacceptableRedirectUrlDescription }];
//        [self finalizeAuthWithAccount:nil error:error];
//        DRLog(@"webView:shouldStartLoadWithRequest returned NO for request: %@", request);
//        return NO;
//    }
//    DRLog(@"webView:shouldStartLoadWithRequest allowed YES for request: %@", request);
//
//    return YES;
//}
//
//- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
//    DRLog(@"webview:didFailLoadWithError: %@\nREQUEST: %@", error, webView.request);
//    NSString *urlString = error.userInfo[NSURLErrorFailingURLStringErrorKey];
//    if (urlString && [self isUrlRedirectUrl:[NSURL URLWithString:urlString]]) {
//        // nop
//    } else {
//        [self finalizeAuthWithAccount:nil error:error];
//    }
//}

#pragma mark - Helpers



- (NSMutableDictionary *)paramsFromUrl:(NSURL *)url {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [[url query] componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if ([elts count] == 2) {
            [params setObject:[elts lastObject] forKey:[elts firstObject]];
        }
    }
    return params;
}
@end