## Supports

KRFacebook integrates Facebook 3.0, it also supports MRC ( Manual Reference Counting ). But it still have no support Graph API and all of New 3.x APIs. We'll try to integrate it as soon as possible. If you did want it support to ARC, that just use Xode tool to auto convert to ARC. ( Xcode > Edit > Refactor > Convert to Objective-C ARC )

## How To Get Started

To import "KRFacebook.h".

``` objective-c
@property (nonatomic, retain) KRFacebook *facebook;

- (void)viewDidLoad
{
    facebook = [[KRFacebook alloc] initWithDelegate:self];
    //facebook = [[KRFacebook alloc] initWithDevKey:@"Your Developer Key of Facebook App" delegate:self];
    [super viewDidLoad];
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
```

## Version

KRFacebook now is V0.9 Beta.

## License

KRFacebook is available under the MIT license ( or Whatever you wanna do ). See the LICENSE file for more info.
