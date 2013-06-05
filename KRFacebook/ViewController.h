//
//  ViewController.h
//  KRFacebook
//
//  Created by Kalvar on 12/10/15.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KRFacebook.h"

@class KRFacebook;

@interface ViewController : UIViewController<KRFacebookDelegate>

@property (nonatomic, strong) KRFacebook *facebook;

@end
