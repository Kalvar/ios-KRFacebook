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
    facebook = [[KRFacebook alloc] initWithDelegate:self];
    //facebook = [[KRFacebook alloc] initWithDevKey:@"Your Developer Key of Facebook App" delegate:self];
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated{
//    [facebook logout];
//    [facebook login];
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    [facebook release];
    [super dealloc];
}

#pragma IBActions
-(IBAction)publishAFeed:(id)sender{
    [self.facebook alreadyLogged];
    //To publish a feed.
    [self.facebook publishOnFeedsWallWithTitle:@"Test Topic"
                                  andTitleHref:@"http://www.google.com"
                                    andMessage:@"Test Content"];
}

-(IBAction)publishImage:(id)sender{
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

-(IBAction)login:(id)sender{
    [self.facebook login];
}

-(IBAction)logout:(id)sender{
    [self.facebook logout];
}

#pragma KRFacebookDelegate
-(void)krFacebookDidLogin{
    //NSLog(@"krFacebookDidLogin");
}

-(void)krFacebookDidLogout{
    //NSLog(@"krFacebookDidLogout");
}

-(void)krFacebookDidCancel{
    //NSLog(@"krFacebookDidCancel");
}

-(void)krFacebookDidFinishAllRequests{
    //NSLog(@"krFacebookDidFinishAllRequests");
    
}

-(void)krFacebook:(KRFacebook *)_krFacebook didSavedUserPrivations:(NSDictionary *)_savedDatas{
    //NSLog(@"datas : %@", _savedDatas);
}


@end
