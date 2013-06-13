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
    facebook = [[KRFacebook alloc] initWithDelegate:self];
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

-(IBAction)login:(id)sender
{
    [self.facebook login];
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

-(void)krFacebook:(KRFacebook *)_krFacebook didSavedUserPrivations:(NSDictionary *)_savedDatas
{
    NSLog(@"datas : %@", _savedDatas);
}


@end
