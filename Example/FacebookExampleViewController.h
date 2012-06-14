//
//  FacebookExampleViewController.h
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 12/6/11.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExtFacebook.h"

@class ExtFacebook;

@interface FacebookExampleViewController : UIViewController<ExtFacebookDelegate>


@property (nonatomic, retain) ExtFacebook *extFacebook;

-(void)login;
-(void)uploadMedia;

@end
