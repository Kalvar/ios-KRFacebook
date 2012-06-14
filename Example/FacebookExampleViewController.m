//
//  FacebookExampleViewController.m
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 12/6/11.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import "FacebookExampleViewController.h"

@interface FacebookExampleViewController ()

@end

@implementation FacebookExampleViewController

@synthesize extFacebook;

-(id)init{
    self = [super init];
    if( self ){
        //If you didn't have DevKey, then you logged facebook who will see facebook feeds wall by yourself.
        extFacebook = [[ExtFacebook alloc] initWithDevKey:@"Your Developer Key of Facebook App" delegate:self];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{

    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)dealloc{
    [extFacebook release];
    [super dealloc];
}

#pragma My Methods
-(void)login{
    [self.extFacebook login];
}

#pragma ExtFacebook Delegate
-(void)extFacebook:(ExtFacebook *)_extFacebook didLogin:(BOOL)_isLogin{
    if( [self.extFacebook alreadyLogged] ){
        [self.extFacebook uploadWithMediaPath:@"/Users/Tester/Desktop/sample.mp4" 
                                     andTitle:@"Test Topic" 
                               andDescription:@"So Cool! \n Wow"];     
    }   
}

-(void)extFacebook:(ExtFacebook *)_extFacebook didLogout:(BOOL)_isLogout{

}

-(void)extFacebook:(ExtFacebook *)_extFacebook didSavedUserPrivations:(NSDictionary *)_savedDatas{

}

-(void)extFacebook:(ExtFacebook *)_extFacebook didLoadWithResponses:(id)_results andKindOf:(NSString *)_perform{
    //NSLog(@"%@", _perform);
}

-(void)extFacebook:(ExtFacebook *)_extFacebook didFailWithResponses:(NSError *)_errors andKindOf:(NSString *)_perform{
    //NSLog(@"error : %@", [_errors localizedDescription]);
}




@end
