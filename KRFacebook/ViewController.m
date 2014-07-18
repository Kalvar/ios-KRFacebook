//
//  ViewController.m
//  KRFacebook
//
//  Created by Kalvar on 12/10/15.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import "ViewController.h"
#import "KRFacebook.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize facebook = _facebook;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _facebook = [KRFacebook sharedManager];
    _facebook.permissions = [NSArray arrayWithObjects:
                             @"read_stream",
                             @"publish_stream",
                             @"email",
                             @"user_photos",
                             @"user_events",
                             @"user_checkins",
                             nil];
    [_facebook awakeFBSession];
} 

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma IBActions
-(IBAction)uploadPhotoToAlbum:(id)sender
{
    /*
     * @ Reference
     *   - About albums
     *     - https://developers.facebook.com/docs/graph-api/reference/v2.0/album
     *
     *   - About upload photo to album
     *     - https://developers.facebook.com/docs/graph-api/reference/v2.0/album/photos
     *
     *   - Permission is user_photos
     *
     * @ Notice
     *   - You have to wait for the console appears logs when you pressed the " Upload url photo to album " button to start in uploading.
     */
    //To get your all of albums and please don't forget the permission of ' user_photos '.
    NSString *_getAlbumsGraphPath = @"me?fields=albums";
    [_facebook requestGraphApiPath:_getAlbumsGraphPath completionHandler:^(BOOL finished, id result) {
        if( finished )
        {
            NSLog(@"#1 GraphAPI result : %@", result);
            //To upload a photo from URL link in your particular album.
            if( [result isKindOfClass:[NSDictionary class]] )
            {
                NSDictionary *_albums = [(NSDictionary *)result objectForKey:@"albums"];
                if( [[_albums objectForKey:@"data"] count] > 0 )
                {
                    //To enumerate all albums.
                    NSArray *_allAlbums = [_albums objectForKey:@"data"];
                    for( NSDictionary *_eachAlbums in _allAlbums )
                    {
                        NSLog(@"#2 Each album info : %@", _eachAlbums);
                    }
                    
                    //In this case that I wanna pick my No. 3 album to upload my photo.
                    NSString *_albumId                = [[_allAlbums objectAtIndex:2] objectForKey:@"id"];
                    NSString *_uploadToAlbumGraphPath = [NSString stringWithFormat:@"%@/photos", _albumId];
                    NSDictionary *_parameters         = @{@"url"    : @"Your photo url link.",
                                                          //If you wanna upload local image file that you can use imageNamed or imageWithContentsOfFile to fetch it to convert NSData use for uploading.
                                                          //@"source" : UIImagePNGRepresentation([UIImage imageNamed:@"sample.png"]),
                                                          //As below is photo comments.
                                                          @"message" : @"The photo comments."
                                                          };
                    [_facebook requestGraphApiPath:_uploadToAlbumGraphPath parameters:_parameters httpMethod:KRFacebookHttpMethodPost completionHandler:^(BOOL finished, id result) {
                        if( finished )
                        {
                            NSLog(@"#3 Uploaded results : %@", result);
                        }
                    }];
                    
                }
            }
        }
    }];
}

-(IBAction)callGraphAPI:(id)sender
{
    NSString *_graphApiPath = @"me?fields=home.with(facebook).limit(10)";
    [_facebook requestGraphApiPath:_graphApiPath completionHandler:^(BOOL finished, id result) {
        if( finished )
        {
            NSLog(@"GraphAPI result : %@", result);
        }
    }];
}

-(IBAction)publishAFeed:(id)sender
{
    if( [_facebook isFBSessionOpen] )
    {
        //To publish a feed.
        [_facebook publishNewsFeedWallWithTitle:@"Test Topic"
                                       titleURL:@"http://www.google.com"
                                        message:@"Test Content Message"
                                   errorHandler:^(NSError *error) {
                                       //...
                                   } completionHandler:^(BOOL finished, id result) {
                                       NSLog(@"result 1: %@", result);
                                   }];
    }
    else
    {
        [_facebook loginWithCompletion:^(BOOL success, NSDictionary *userInfo) {
            if( success )
            {
                [_facebook publishNewsFeedWallWithTitle:@"Test Topic"
                                               titleURL:@"http://www.google.com"
                                                message:@"Test Content Message"
                                           errorHandler:^(NSError *error) {
                                               //...
                                           } completionHandler:^(BOOL finished, id result) {
                                               NSLog(@"result 2: %@", result);
                                           }];
            }
        }];
    }
}

-(IBAction)publishImage:(id)sender
{
    [self.facebook publishNewsFeedWithPhotoURL:@"https://dl.dropboxusercontent.com/u/83663874/GitHubs/TryGong-1.png"
                             clickPhotoTurnURL:@"http://www.google.com"
                                         title:@"Tells everyone."
                                      subtitle:@"But keep it be a secret."
                                   description:@"I love Open Source."
                                      titleURL:@"http://www.yahoo.com"
                                   bottomTitle:@"Kalvar.Info"
                                bottomTitleURL:@"http://kalvar.info"
                                 bottomMessage:@"Happy Coder."
                                  errorHandler:^(NSError *error) {
                                      //...
                                  }
                             completionHandler:^(BOOL finished, id result) {
                                 if( finished )
                                 {
                                     NSLog(@"result : %@", result);
                                 }
                             }];
}

-(IBAction)uploadImage:(id)sender
{
    //Method 1
    [_facebook uploadImage:[UIImage imageNamed:@"Default.png"]
               description:@"Upload image method 1."
              errorHandler:^(NSError *error) {
                  //...
              } completionHandler:^(BOOL finished, id result) {
                  //...
              }];
    
    //Method 2
    [_facebook uploadPhotoHttpURL:[NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/83663874/GitHubs/TryGong-1.png"]
                      description:@"Upload image method 2."
                     errorHandler:^(NSError *error) {
                         //...
                     } completionHandler:^(BOOL finished, id result) {
                         //...
                     }];
    
    //Method 3
    [_facebook uploadPhotoLocalPath:@"/var/mobile/krfacebook/sample.png"
                        description:@"Upload image method 3."
                       errorHandler:^(NSError *error) {
                           //...
                       } completionHandler:^(BOOL finished, id result) {
                           //...
                       }];
}

-(IBAction)shareVideo:(id)sender
{
    //Method 1, Share Youtube Video.
    [_facebook publishNewsFeedWithYoutubeVideoId:@"Q9uTyjJQ0VU"
                               viewoThumbnailURL:@"https://dl.dropboxusercontent.com/u/83663874/GitHubs/TryGong-1.png"
                                   thumbnailSize:CGSizeMake(160.0f, 120.0f)
                                        playSize:CGSizeMake(480.0f, 320.0f)
                                           title:@"史詩"
                                        subtitle:@"Taiwan Rapper."
                                     description:@"Keep Rapping."
                                        titleURL:@"http://www.youtube.com/watch?v=Q9uTyjJQ0VU"
                                     bottomTitle:@"Hello, Hip-Hop."
                                  bottomTitleURL:@"http://www.youtube.com/watch?v=Q9uTyjJQ0VU"
                                   bottomMessage:@"I love Hip-Hop."
                                    errorHandler:^(NSError *error) {
                                        //...
                                    } completionHandler:^(BOOL finished, id result) {
                                        if( finished )
                                        {
                                            NSLog(@"uploadVideo : %@", result);
                                        }
                                    }];
    
    //Method 2, Share Your Video.
    [_facebook publishNewsFeedWithVideoURL:@"http://www.youtube.com/v/Q9uTyjJQ0VU"
                         viewoThumbnailURL:@"https://dl.dropboxusercontent.com/u/83663874/GitHubs/TryGong-1.png"
                             thumbnailSize:CGSizeMake(160.0f, 120.0f)
                                  playSize:CGSizeMake(480.0f, 320.0f)
                                     title:@"史詩"
                                  subtitle:@"Taiwan Rapper."
                               description:@"Keep Rapping."
                                  titleURL:@"http://www.youtube.com/watch?v=Q9uTyjJQ0VU"
                               bottomTitle:@"Hello, Hip-Hop."
                            bottomTitleURL:@"http://www.youtube.com/watch?v=Q9uTyjJQ0VU"
                             bottomMessage:@"I love Hip-Hop."
                              errorHandler:^(NSError *error) {
                                  //...
                              } completionHandler:^(BOOL finished, id result) {
                                  if( finished )
                                  {
                                      NSLog(@"uploadVideo : %@", result);
                                  }
                              }];
}

-(IBAction)uploadVideo:(id)sender
{
    [_facebook uploadVideoLocalPath:@"/var/mobile/krfacebook/sample.mp4"
                              title:@"Nice Video."
                        description:@"Wow, Video."
                       errorHandler:^(NSError *error) {
                           //...
                       } completionHandler:^(BOOL finished, id result) {
                           //...
                       }];
    
}

-(IBAction)login:(id)sender
{
    [_facebook loginWithCompletion:^(BOOL success, NSDictionary *userInfo) {
        if( success )
        {
            NSLog(@"login userInfo : %@", userInfo);
        }
    }];
}

-(IBAction)logout:(id)sender
{
    [_facebook logout];
}

-(IBAction)awakeSession:(id)sender
{
    [_facebook awakeFBSession];
}

-(IBAction)getPrivateUserInfo:(id)sender
{
    //Me Info, Email, Profile Picture, Profile Name
    NSDictionary *_userInfo = _facebook.userInfo;
    NSString *_userId       = _facebook.userId;
    NSString *_userEmail    = _facebook.userEmail;
    NSString *_userName     = _facebook.userName;
    NSString *_userGender   = _facebook.userGender;
    NSLog(@"_userInfo : %@", _userInfo);
}

@end
