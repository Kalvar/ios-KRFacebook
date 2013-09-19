## Supports

KRFacebook supports FacebookSDK 3.6, that you can easy share Youtube video, share your video file, upload a photo, upload several photos, upload your video, request GraphAPI, and easy write the message on the news feed wall.

## How To Get Started

It need to go to *-info.plist set the facebook app developer key up with following the Facebook rules.

<img src="https://dl.dropbox.com/u/83663874/GitHubs/KRFacebook-1.png" alt=" *-info.plist" title=" *-info.plist" style="margin: 20px;" class="center" />

``` objective-c

#import "KRFacebook.h"

@interface ViewController ()

@property (nonatomic, strong) KRFacebook *facebook;

@end

@implementation ViewController

@synthesize facebook;

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

#pragma IBActions
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
    NSDictionary *_userInfo = [_facebook getUserInfo];
    NSLog(@"_userInfo : %@", _userInfo);
}
```

## Version

KRFacebook now is V2.0.

## License

KRFacebook is available under the MIT license ( or Whatever you wanna do ). See the LICENSE file for more info.

## Others

KRFacebook used FBSBJSON and FacebookSDK 3.6+.
