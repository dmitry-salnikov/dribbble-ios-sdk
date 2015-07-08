//
//  DROAuthManager.h
//  
//
//  Created by Vladimir Zgonik on 31.03.15.
//  Copyright (c) 2015 Agilie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DribbbleSDK.h"

@class DRApiClientSettings, GTMOAuth2Authentication, GTMOAuth2ViewControllerTouch;

@interface DROAuthManager : NSObject <UIWebViewDelegate>

//@property (strong, nonatomic) GTMOAuth2Authentication *authentification;

- (GTMOAuth2ViewControllerTouch *)retrieveSignInControllerWithSettings:(DRApiClientSettings *)settings authHandler:(DROAuthHandler)authHandler;

//- (void)authorizeWithWebView:(UIWebView *)webView settings:(DRApiClientSettings *)settings authHandler:(DROAuthHandler)authHandler;

@end
