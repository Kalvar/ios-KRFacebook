## Supports

KRFacebook integrates Facebook 3.1, and it supports to 3.3 and ARC.

## How To Get Started

It need to setup the Facebook Developer Key for FACEBOOK_DEVELOPER_KEY in KRFacebook.h, and go to *-info.plist set the facebook developer key up with following the Facebook rules too.

``` objective-c

#import "KRFacebook.h"

@property (nonatomic, strong) KRFacebook *facebook;

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
```

## Version

KRFacebook now is V1.1.

## License

KRFacebook is available under the MIT license ( or Whatever you wanna do ). See the LICENSE file for more info.
