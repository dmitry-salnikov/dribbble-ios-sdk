//
//  ViewController.m
//  DribbbleSDKExample
//
//  Created by Dmitry Salnikov on 6/11/15.
//  Copyright (c) 2015 Agilie. All rights reserved.
//

#import "MainViewController.h"
#import "LoginViewController.h"
#import "DribbbleSDK.h"
#import <BlocksKit+UIKit.h>
#import "ApiCallFactory.h"
#import "ApiCallWrapper.h"
#import "TestApiViewController.h"

typedef void(^UserUploadImageBlock)(NSURL *fileUrl, NSData *imageData);

// SDK setup constants

static NSString * const kIDMOAuth2ClientId = @"<YOUR CLIENT ID>";
static NSString * const kIDMOAuth2ClientSecret = @"<YOUR CLIENT SECRET>";
static NSString * const kIDMOAuth2ClientAccessToken = @"<YOUR ACCESS TOKEN>";

static NSString * const kIDMOAuth2RedirectURL = @"<YOUR APP REDIRECT URL>";
static NSString * const kIDMOAuth2AuthorizationURL = @"https://dribbble.com/oauth/authorize";
static NSString * const kIDMOAuth2TokenURL = @"https://dribbble.com/oauth/token";

static NSString * const kBaseApiUrl = @"https://api.dribbble.com/v1/";

// ---

static NSString * kCellIdentifier = @"cellIdentifier";
static NSString * kSegueIdentifierAuthorize = @"authorizeSegue";
static NSString * kSegueIdentifierTestApi = @"testApiSegue";

@interface MainViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) DRApiClient *apiClient;

@property (strong, nonatomic) NSArray *apiCallWrappers;

@property (copy, nonatomic) UserUploadImageBlock userUploadImageBlock;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;

@end

@implementation MainViewController

#pragma mark - View LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.apiCallWrappers = [ApiCallFactory demoApiCallWrappers];
    [self setupApiClient];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.signOutButton.hidden = ![self.apiClient isUserAuthorized];
    self.signInButton.hidden = [self.apiClient isUserAuthorized];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdentifierAuthorize]) {
        LoginViewController *loginViewController = (LoginViewController *)segue.destinationViewController;
        loginViewController.apiClient = self.apiClient;
        loginViewController.authCompletionHandler = ^(BOOL success) {
            NSLog(@"Signed in successfully? %d", success);
        };
    } else if ([segue.identifier isEqualToString:kSegueIdentifierTestApi]) {
        TestApiViewController *testApiController = (TestApiViewController *)segue.destinationViewController;
        testApiController.apiCallWrapper = sender;
        testApiController.apiClient = self.apiClient;
    }
}

#pragma mark - Internal

- (void)setupApiClient {
    DRApiClientSettings *settings = [[DRApiClientSettings alloc] initWithBaseUrl:kBaseApiUrl
                                                               oAuth2RedirectUrl:kIDMOAuth2RedirectURL
                                                          oAuth2AuthorizationUrl:kIDMOAuth2AuthorizationURL
                                                                  oAuth2TokenUrl:kIDMOAuth2TokenURL
                                                                        clientId:kIDMOAuth2ClientId
                                                                    clientSecret:kIDMOAuth2ClientSecret
                                                               clientAccessToken:kIDMOAuth2ClientAccessToken
                                                                          scopes:[NSSet setWithObjects:kDRPublicScope, kDRWriteScope, kDRUploadScope, kDRCommentScope, nil]];
    self.apiClient = [[DRApiClient alloc] initWithSettings:settings];
    __weak typeof(self) weakSelf = self;
    self.apiClient.defaultErrorHandler = ^ (NSError *error) {
        if (error.domain == NSURLErrorDomain && ![weakSelf.apiClient isUserAuthorized]) {
            [weakSelf performSegueWithIdentifier:kSegueIdentifierAuthorize sender:nil];
        } else {
            [UIAlertView bk_showAlertViewWithTitle:@"Error" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
        }
    };
}

#pragma mark - IBActions

- (IBAction)pressSignOut:(id)sender {
    [self.apiClient logout];
    self.signOutButton.hidden = ![self.apiClient isUserAuthorized];
    self.signInButton.hidden = [self.apiClient isUserAuthorized];
}

#pragma mark - Table View Delegate + Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.apiCallWrappers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    ApiCallWrapper *wrapper = self.apiCallWrappers[indexPath.row];
    cell.textLabel.text = wrapper.title;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ApiCallWrapper *wrapper = self.apiCallWrappers[indexPath.row];
    [self performSegueWithIdentifier:kSegueIdentifierTestApi sender:wrapper];
}

@end
