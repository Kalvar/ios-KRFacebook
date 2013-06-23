//
//  ViewController.m
//  KRFacebook
//
//  Created by Kalvar on 12/10/15.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize facebook;

- (void)viewDidLoad
{
    [super viewDidLoad];
    //Default using method.
    facebook = [[KRFacebook alloc] initWithDelegate:self];
    /*
    //Customize the facebook permissions if you want, and the permissions will be the default standard request.
    facebook = [[KRFacebook alloc] initWithPermissions:[NSArray arrayWithObjects:
                                                        @"read_stream",
                                                        @"publish_stream",
                                                        @"offline_access",
                                                        @"email",
                                                        @"user_photos",
                                                        @"user_events",
                                                        @"user_checkins",
                                                        nil]
                                              delegate:self];
     */
    //You can use another Facebook Developer Key different the KRFacebook.h define your default developer key.
    //facebook = [[KRFacebook alloc] initWithDevKey:@"Your Developer Key of Facebook App" delegate:self];
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma IBActions
-(IBAction)publishAFeed:(id)sender
{
    if( [self.facebook alreadyLogged] )
    {
        //To publish a feed.
        [self.facebook publishOnFeedsWallWithTitle:@"Test Topic"
                                      andTitleHref:@"http://www.google.com"
                                        andMessage:@"Test Content"];
    }
}

-(IBAction)publishImage:(id)sender
{
    [self.facebook publishFeedsWithImageSrc:@"http://sample.com/sample1.jpg"
                                  imageJump:@"http://www.google.com"
                                      title:@"An Image Testing Topic."
                                   subtitle:@"An Image Subtitle."
                                description:@"An Image Description."
                                  titleHref:@"To connect the URL of title."
                                  miniTitle:@"Yes, Just Mini tip."
                              miniTitleHref:@"To connect the URL of miniTitle."
                                miniMessage:@"Nothing else."];
}

-(IBAction)uploadImage:(id)sender
{
    //Take a look ~
    //Method 1
    [self.facebook uploadWithImage:[UIImage imageNamed:@"sample.png"] description:@"Uploaded from an Image"];
    //Method 2
    [self.facebook uploadWithPhotoPath:@"/var/mobile/krfacebook/sample.png" description:@"Uploaded from a local file path"];
    //Method 3
    [self.facebook uploadWithPhotoURL:[NSURL URLWithString:@"http://sample.com/sampe1.jpg"] description:@"Uploaded from URL"];
}

-(IBAction)login:(id)sender
{
    //Use default permissions to Login.
    [self.facebook login];
    /*
    //Dynamic using custom permissions to Login.
    [self.facebook loginWithPermissions:[NSArray arrayWithObjects:
                                         @"read_stream",
                                         @"publish_stream",
                                         @"offline_access",
                                         @"email",
                                         @"user_photos",
                                         nil]];
     */
}

-(IBAction)logout:(id)sender
{
    [self.facebook logout];
}

-(IBAction)awakeSession:(id)sender
{
    [self.facebook awakeSession];
}

#pragma KRFacebookDelegate
-(void)krFacebookDidLogin
{
    NSLog(@"krFacebookDidLogin");
}

-(void)krFacebookDidLogout
{
    NSLog(@"krFacebookDidLogout");
}

-(void)krFacebookDidCancel
{
    NSLog(@"krFacebookDidCancel");
}

-(void)krFacebookDidFinishAllRequests
{
    NSLog(@"krFacebookDidFinishAllRequests");
}

-(void)krFacebook:(KRFacebook *)_krFacebook didSavedUserPrivateInfo:(NSDictionary *)_userInfo
{
    NSLog(@"_userInfo : %@", _userInfo);
}

/*
 * @ Here is your requests received the Facebook's Response Values.
 */
-(void)krFacebookDidLoadWithResponses:(id)_results
{
    NSLog(@"_results : %@", _results);
}


@end
