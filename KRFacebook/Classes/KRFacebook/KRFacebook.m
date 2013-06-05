//
//  KRFacebook.m
//  
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 2013/01/20.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

/*
 * @self.executing 參數說明 (後續會再增加) :
 *
 *  init                    : 初始化
 *  upload.media            : 上傳影音
 *  post.feeds.word         : 發佈純文字留言
 *  post.feeds.media        : 發佈影音留言
 *  upload.photos           : 上傳圖片
 *  get.upload.limit.size   : 取得上傳的檔案容量限制
 *  login                   : 登入
 *  logout                  : 登出
 *  cancel                  : 取消登入
 *  get.user.photos         : 取得使用者相片
 *  get.user.permissions    : 取得認證類型資訊
 *  get.user.feeds          : 取得塗鴉牆資訊
 *  get.user.friends        : 取得朋友群資訊
 *  get.user.albums         : 取得相簿資訊
 *  get.user.informations   : 取得個人資訊
 *  get.user.groups         : 取得個人粉絲團
 *  get.user.uploads        : 取得個人上傳過的影音資料
 *  get.user.homes          : 取得個人首頁最新的塗鴉留言
 *  get.user.links          : 取得個人按過讚的粉絲團( 加入過的 )
 *  get.user.events         : 取得個人正在進行的活動事件
 */

#import "KRFacebook.h"
#import "AppDelegate.h"

@interface KRFacebook ()
{
    __strong Facebook *facebook;
    
}

@property (strong, readonly) Facebook *facebook;
@property (nonatomic, assign) BOOL isString;

@end

@interface KRFacebook (fixPrivate)

-(void)_initWithCommonVars:(NSString *)_devKeys 
               andDelegate:(id<KRFacebookDelegate>)_delegate;

-(NSString *)_getSavedString:(NSString *)_nsdefaultKey;

-(NSDictionary *)_getSavedDatas;

-(void)_savingPrivateInformationOfUserInApp:(NSDictionary *)_responses;

-(NSDictionary *)_setupParamsWithUploadImageUrl:(id)_imageUrl 
                               imageDescription:(NSString *)_description;

-(NSDictionary *)_setupParamsWithUploadMediaUrl:(id)mediaUrl 
                                       andTitle:(NSString *)mediaTitle 
                                 andDescription:(NSString *)mediaDesc;

-(NSDictionary *)_setupParamsWithFeedsConfigs:(NSDictionary *)miniWordsConfigs 
                                   andMessage:(NSString *)message;

-(NSDictionary *)_setupParamsWithFeedMediaConfigs:(NSDictionary *)mediaAttachConfigs 
                              andMiniWordsConfigs:(NSDictionary *)miniWordsConfigs 
                                       andMessage:(NSString *)message;

-(NSDictionary *)_setupConfigsOfMiniTitle:(NSString *)miniTitle 
                              andMiniHref:(NSString *)miniHref;

-(void)_uploadWithMediaConfigs:(NSDictionary *)_mediaConfigs;

//
-(void)_requestDidLoadResult:(id)result;
-(void)_requestDidFailWithError:(NSError *)error;

@end

@implementation KRFacebook (fixPrivate)

/*
 * @重要參數說明 : 
 *   self.saveUser     = 登入後，儲存指定的使用者資訊
 *   self.devKey       = Facebook App 的 Developer Key
 *   self.fbPermissons = 登入後，要向 FB 請求的資料項目
 *   self.executing    = 當前在執行的動作
 */
-(void)_initWithCommonVars:(NSString *)_devKeys 
               andDelegate:(id<KRFacebookDelegate>)_delegate{
    self.saveUser     = NO;
    self.isLogged     = NO;
    self.delegate     = _delegate;
    self.devKey       = _devKeys;     
    self.fbPermissons = [NSArray arrayWithObjects:
                         @"read_stream", 
                         @"publish_stream", 
                         @"offline_access",
                         @"email",
                         @"user_photos",
                         @"user_events",
                         @"user_checkins",
                         nil];     
    self.executing     = @"init";
    self.processing    = KRFacebookProcessForNothing;
    facebook           = nil; //[[Facebook alloc] initWithAppId:self.devKey andDelegate:self];
    jsonWriter         = [[FBSBJSON alloc] init];
    //
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.session.isOpen) {
        appDelegate.session = [[FBSession alloc] initWithPermissions:self.fbPermissons];
    }
    fbSession = appDelegate.session;
    
}

-(NSString *)_getSavedString:(NSString *)_nsdefaultKey
{
    return [NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:_nsdefaultKey]];
}

-(NSDictionary *)_getSavedDatas
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [self _getSavedString:FACEBOOK_ACCESS_TOKEN_KEY],    FACEBOOK_ACCESS_TOKEN_KEY,
            [self _getSavedString:FACEBOOK_EXPIRATION_DATE_KEY], FACEBOOK_EXPIRATION_DATE_KEY,
            [self _getSavedString:FACEBOOK_USER_ACCOUNT_KEY],    FACEBOOK_USER_ACCOUNT_KEY,
            [self _getSavedString:FACEBOOK_USER_ID_KEY],         FACEBOOK_USER_ID_KEY,
            [self _getSavedString:FACEBOOK_USER_NAME_KEY],       FACEBOOK_USER_NAME_KEY,
            nil];
}

/*
 * 匯整與儲存 User 的私人資訊在 App 裡，並同時觸發委派進行儲存至 Server 的資料互動
 */
-(void)_savingPrivateInformationOfUserInApp:(NSDictionary *)_responses
{
    //NSLog(@"_savingPrivateInformationOfUserInApp : %@", _responses);
    [[NSUserDefaults standardUserDefaults] setObject:[_responses objectForKey:@"email"] forKey:FACEBOOK_USER_ACCOUNT_KEY];
    [[NSUserDefaults standardUserDefaults] setObject:[_responses objectForKey:@"id"] forKey:FACEBOOK_USER_ID_KEY];
    [[NSUserDefaults standardUserDefaults] setObject:[_responses objectForKey:@"name"] forKey:FACEBOOK_USER_NAME_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize]; 
    if( [self.delegate respondsToSelector:@selector(krFacebook:didSavedUserPrivations:)] ){
        [self.delegate krFacebook:self didSavedUserPrivations:[self _getSavedDatas]];
    }
    
}

/*
 * @上傳 : 
 *   取得上傳圖片所使用的參數(Params)
 */
-(NSDictionary *)_setupParamsWithUploadImageUrl:(id)_imageUrl 
                               imageDescription:(NSString *)_description{
    NSData *imageData;
    if( [_imageUrl isKindOfClass:[NSURL class]] ){
        imageData = [NSData dataWithContentsOfURL:(NSURL *)_imageUrl];
    }else{
        imageData = [NSData dataWithContentsOfFile:(NSString *)_imageUrl];
    }
    UIImage *image    = [[UIImage alloc] initWithData:imageData];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   image, @"picture",
                                   _description, @"caption",
								   nil];
    return params;
}

/*
 * @上傳 : 
 *   取得上傳影音所使用的參數(Params)
 */
-(NSDictionary *)_setupParamsWithUploadMediaUrl:(id)mediaUrl 
                                       andTitle:(NSString *)mediaTitle 
                                 andDescription:(NSString *)mediaDesc
{
    NSData *mediaData;
    if( [mediaUrl isKindOfClass:[NSURL class]] ){
        mediaData = [NSData dataWithContentsOfURL:(NSURL *)mediaUrl];
    }else{
        mediaData = [NSData dataWithContentsOfFile:(NSString *)mediaUrl];
    }
    NSArray *urlArray  = [(NSString *)mediaUrl componentsSeparatedByString:@"/"];
    NSString *fileName = [[urlArray objectAtIndex:(int)( [urlArray count] - 1 )] 
                          stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];  
    NSArray *nameArray = [fileName componentsSeparatedByString:@"."];
    NSString *fileExt  = [[nameArray objectAtIndex:1] 
                          stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; 
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   mediaData, fileName,
                                   [self getFileMimeTypeWithExt:fileExt], @"contentType",
                                   mediaTitle, @"title",
                                   mediaDesc, @"description",
                                   nil];  
    return params;
}

/*
 * @純文字留言 : 
 *   取得純文字留言使用的參數(Params)字串
 */
-(NSDictionary *)_setupParamsWithFeedsConfigs:(NSDictionary *)miniWordsConfigs 
                                   andMessage:(NSString *)message
{
    NSString *miniWordsJsonString = [jsonWriter stringWithObject:miniWordsConfigs error:nil];
    NSMutableDictionary *params   = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     miniWordsJsonString, @"action_links", 
                                     message, @"message",
                                     nil];      
    return params;
}

/*
 * @多媒體留言 : 
 *   取得多媒體留言使用的參數(Params)字串
 */
-(NSDictionary *)_setupParamsWithFeedMediaConfigs:(NSDictionary *)mediaAttachConfigs 
                              andMiniWordsConfigs:(NSDictionary *)miniWordsConfigs 
                                       andMessage:(NSString *)message
{
    NSString *miniWordsJsonString   = [jsonWriter stringWithObject:miniWordsConfigs];
    NSString *mediaAttachJsonString = [jsonWriter stringWithObject:mediaAttachConfigs];
    NSMutableDictionary *params     = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       miniWordsJsonString, @"action_links", 
                                       mediaAttachJsonString, @"attachment",
                                       message, @"message",
                                       nil];
    return params;
}

/*
 * 迷你文字標題留言設定
 */
-(NSDictionary *)_setupConfigsOfMiniTitle:(NSString *)miniTitle 
                              andMiniHref:(NSString *)miniHref
{
    NSDictionary *miniWrodsConfigs = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                miniTitle, @"text", 
                                                                miniHref, @"href", 
                                                                nil], nil];    
    return miniWrodsConfigs;
}

/*
 * 上傳影片
 */
-(void)_uploadWithMediaConfigs:(NSDictionary *)_mediaConfigs{
    self.executing  = @"upload.media";
    self.processing = KRFacebookProcessForUploadMedia;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:_mediaConfigs];
//    [facebook requestWithGraphPath:@"me/videos"
//                         andParams:params 
//                     andHttpMethod:@"POST"
//                       andDelegate:self];
    
    
    FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                     graphPath:@"me/videos"
                                                    parameters:params
                                                    HTTPMethod:@"POST"];
    
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self _requestDidLoadResult:result];
    }];
    
}

#pragma 
/*
 * @ 原來的 FBRequestDelegate + FBSessionDelegate 搬到這裡變成自函式
 */
//原先是 request:(FBRequest *)request didLoad:(id)result
-(void)_requestDidLoadResult:(id)result{
	if ( [result isKindOfClass:[NSArray class]] ) {
		result = [result objectAtIndex:0];
	}
    
    if( [result isKindOfClass:[NSData class]] ){
        NSString *_tempResult = [[NSString alloc] initWithData:(NSData *)result encoding:NSUTF8StringEncoding];
        result = [NSString stringWithString:_tempResult];
    }
    
    self.isString = [result isKindOfClass:[NSString class]] ? YES : NO;
    
    if( [self.delegate respondsToSelector:@selector(krFacebook:didLoadWithResponses:andKindOf:)] ){
        [self.delegate krFacebook:self didLoadWithResponses:result andKindOf:self.executing];
    }
    
    if( self.isString && [self.delegate respondsToSelector:@selector(krFacebook:didLoadWithResponseOfString:andKindOf:)] ){
        [self.delegate krFacebook:self didLoadWithResponseOfString:result andKindOf:self.executing];
    }else{
        if( self.saveUser ){
            self.saveUser = NO;
            [self _savingPrivateInformationOfUserInApp:result];
        }
        if( [result isKindOfClass:[NSDictionary class]] &&
           [self.delegate respondsToSelector:@selector(krFacebook:didLoadWithResponsesOfDictionary:andKindOf:)]){
            [self.delegate krFacebook:self didLoadWithResponsesOfDictionary:result andKindOf:self.executing];
        }
    }
    
    if( [self.delegate respondsToSelector:@selector(krFacebookDidFinishAllRequests)] ){
        [self.delegate krFacebookDidFinishAllRequests];
    }
    //NSLog(@"fbRequest didLoad (FinishAllRequests)");
}

//原先是 request:(FBRequest *)request didFailWithError:(NSError *)error
-(void)_requestDidFailWithError:(NSError *)error{
    if( [self.delegate respondsToSelector:@selector(krFacebook:didFailWithResponses:andKindOf:)] ){
        [self.delegate krFacebook:self didFailWithResponses:error andKindOf:self.executing];
    }
}


@end

@implementation KRFacebook

@synthesize jsonWriter,
            facebook,
            devKey,
            delegate,
            isLogged,
            isString,
            executing,
            saveUser,
            fbPermissons;
@synthesize processing;
//
@synthesize fbSession;

#pragma Construct
+(KRFacebook *)sharedManager
{
    static dispatch_once_t pred;
    static KRFacebook *_krFacebook = nil;
    dispatch_once(&pred, ^{
        _krFacebook = [[KRFacebook alloc] init];
    });
    return _krFacebook;
    //return [[self alloc] init];
}

-(KRFacebook *)initWithDelegate:(id<KRFacebookDelegate>)_sdkDelegate
{
    self = [super init];
    if( self ){
        [self _initWithCommonVars:FACEBOOK_DEVELOPER_KEY andDelegate:_sdkDelegate];
    }
    return self;
}

-(KRFacebook *)initWithDevKey:(NSString *)_devKey delegate:(id<KRFacebookDelegate>)_sdkDelegate{
    self = [super init];
    if( self ){       
        NSString *_tempDevKeys = ( [_devKey length] > 0 )? _devKey : FACEBOOK_DEVELOPER_KEY;
        [self _initWithCommonVars:_tempDevKeys andDelegate:_sdkDelegate];
    }
    return self;
}


#pragma Settup Attach Configs
-(NSDictionary *)setConfigsOfVideoUrl:(NSString *)videoSrc 
                          andImageSrc:(NSString *)imageSrc 
                        andImageWidth:(NSString *)imageWidth 
                       andImageHeight:(NSString *)imageHeight 
                         andPlayWidth:(NSString *)expandedWidth 
                        andPlayHeight:(NSString *)expandedHeight
{
    NSDictionary *mediaConfigs = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"flash", @"type",
                                                            videoSrc, @"swfsrc",
                                                            imageSrc, @"imgsrc",
                                                            imageWidth, @"width", 
                                                            imageHeight, @"height", 
                                                            expandedWidth, @"expanded_width",
                                                            expandedHeight, @"expanded_height",
                                                            nil], nil];
    return mediaConfigs;
    
    
}

-(NSDictionary *)setConfigsOfImageUrl:(NSString *)imageSrc 
                              andHref:(NSString *)imageHref
{
    NSDictionary *mediaConfigs = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"image", @"type",
                                                            imageSrc, @"src",
                                                            imageHref, @"href",
                                                            nil], nil];    
    return mediaConfigs;
    
}

-(NSArray *)setConfigsOfImagesUrlObjects:(NSArray *)imageSrcArray
                          andHrefObjects:(NSArray *)imageHrefArray
{
    NSMutableArray *tempMediaConfigs = [[NSMutableArray alloc] initWithCapacity:0];
    int _count = [imageSrcArray count];
    for( int i=0; i<_count; i++ ){
        [tempMediaConfigs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     @"image", @"type",
                                     [imageSrcArray objectAtIndex:i], @"src",
                                     [imageHrefArray objectAtIndex:i], @"href",
                                     nil]];
    }
    NSArray *mediaConfigs = [NSArray arrayWithArray:tempMediaConfigs];
    return mediaConfigs;
}

-(NSDictionary *)setConfigsOfMusicUrl:(NSString *)musicSrc 
                             andTitle:(NSString *)songName 
                            andSinger:(NSString *)singerName 
                             andAlbum:(NSString *)albumName
{
    NSDictionary *mediaConfigs = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"music", @"type",
                                                            musicSrc, @"src",
                                                            songName, @"title",
                                                            singerName, @"artist", 
                                                            albumName, @"album", 
                                                            nil], nil];
    return mediaConfigs;
    
}

-(NSDictionary *)setMediaAttachConfigsWithTitle:(NSString *)title 
                                    andSubtitle:(NSString *)subtitle 
                                 andDescription:(NSString *)description 
                                   andTitleHref:(NSString *)titleHref 
                                andMediaConfigs:(NSDictionary *)mediaConfigs
{

    NSDictionary *mediaAttachConfigs = [NSDictionary dictionaryWithObjectsAndKeys:
                                        title, @"name",
                                        subtitle, @"caption", 
                                        description, @"description",
                                        mediaConfigs, @"media",
                                        titleHref, @"href",
                                        nil];        
    return mediaAttachConfigs;
}

#pragma Publish Feeds (發佈各式留言)
/*
 * @發佈純文字留言 : 
 *   _title     : 留言最下面的迷你小標題
 *   _titleHref : 點小標題時要導向的超連結
 *   _message   : 留言主內容
 */
-(void)publishOnFeedsWallWithTitle:(NSString *)_title 
                      andTitleHref:(NSString *)_titleHref 
                        andMessage:(NSString *)_message
{
    NSString *miniWordsJsonString = [jsonWriter stringWithObject:[self _setupConfigsOfMiniTitle:_title andMiniHref:_titleHref]  
                                                           error:nil];
    NSMutableDictionary *params   = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     miniWordsJsonString, @"action_links", 
                                     _message, @"message",
                                     nil];    
    self.executing  = @"post.feeds.word";
    self.processing = KRFacebookProcessForPublishOnFeeds;
    //REST API
    __block FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                    restMethod:@"stream.publish"
                                                    parameters:params
                                                    HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self _requestDidLoadResult:result];
    }];
    
}

//[多媒體留言] : 文字 + Youtube Flash 影片 / 圖片 / 音樂
-(void)publishOnMediaConfigs:(NSDictionary *)mediaAttachConfigs 
         andMiniWordsConfigs:(NSDictionary *)miniWordsConfigs 
                  andMessage:(NSString *)message
{
    NSString *miniWordsJsonString   = [jsonWriter stringWithObject:miniWordsConfigs];
    NSString *mediaAttachJsonString = [jsonWriter stringWithObject:mediaAttachConfigs];
    NSMutableDictionary *params     = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       miniWordsJsonString, @"action_links", 
                                       mediaAttachJsonString, @"attachment",
                                       message, @"message",
                                       nil];
    self.executing  = @"post.feeds.media"; 
    self.processing = KRFacebookProcessForPublishOnMedia;
    __block FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                    restMethod:@"stream.publish"
                                                    parameters:params
                                                    HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self _requestDidLoadResult:result];
    }];
    
}

/*
 * @ 一次性設定發表單張圖片留言 : MiniMessage 會出現在 Title 下面那一區
 *
 * @ Post 單張圖片留言的正確設定流程 : 
 *  1).  設定圖片的 URL
 *  2).  點選圖片時，要導向的網址
 *  3).  設定圖片留言的大標題
 *  4).  副標題
 *  5).  說明內容
 *  6).  大標題的超連結
 *  7).  迷你標題
 *  8).  點選迷你標題時，要導向的網址
 *  9).  設定 MiniMessage 參數，會出現在大標題底下的那一空白區塊
 */
-(void)publishFeedsWithImageSrc:(NSString *)_imageSrc
                      imageJump:(NSString *)_imageHref
                          title:(NSString *)_title
                       subtitle:(NSString *)_subtitle
                    description:(NSString *)_description
                      titleHref:(NSString *)_titleHref
                      miniTitle:(NSString *)_miniTitle
                  miniTitleHref:(NSString *)_miniTitleHref
                    miniMessage:(NSString *)_miniMessage
{
    NSDictionary *miniWordsArray    = [self _setupConfigsOfMiniTitle:_miniTitle 
                                                         andMiniHref:_miniTitleHref];
    NSDictionary *mediaMessageArray = [self setMediaAttachConfigsWithTitle:_title 
                                                               andSubtitle:_subtitle
                                                            andDescription:_description
                                                              andTitleHref:_titleHref
                                                           andMediaConfigs:[self setConfigsOfImageUrl:_imageSrc
                                                                                              andHref:_imageHref]];
    [self publishOnMediaConfigs:mediaMessageArray 
            andMiniWordsConfigs:miniWordsArray 
                     andMessage:_miniMessage];
    
}

/*
 * @ 一次性設定並發佈多張圖片留言 :: 陣列( imageSrcArray / imageHrefArray 需為互相對應的陣列 )
 * @ Post 多張圖片 : 
 *   //圖片 URL
 *   NSArray *imagesUrls  = [NSArray arrayWithObjects:@"http://www.flashaim.tv/images/poster/fb_poster.png", 
 *                                                    @"http://www.flashaim.tv/images/poster/flashaim_about_poster.png", 
 *                                                    nil];
 *   //點選圖片時，要導向的 URL
 *   NSArray *imageJumps = [NSArray arrayWithObjects:@"http://www.flashaim.tv/?menu=fb", 
 *                                                   @"http://www.flashaim.tv/?menu=flashaim_about", 
 *                                                   nil]; 
 */
-(void)publishFeedsWithImageUrls:(NSArray *)_imageSrcArray
                      imageJumps:(NSArray *)_imageHrefArray
                           title:(NSString *)_title
                        subtitle:(NSString *)_subtitle
                     description:(NSString *)_description
                       titleHref:(NSString *)_titleHref
                       miniTitle:(NSString *)_miniTitle
                   miniTitleHref:(NSString *)_miniTitleHref
                     miniMessage:(NSString *)_miniMessage
{
    NSDictionary *miniWordsArray    = [self _setupConfigsOfMiniTitle:_miniTitle 
                                                         andMiniHref:_miniTitleHref];
    NSDictionary *mediaMessageArray = [self setMediaAttachConfigsWithTitle:_title 
                                                               andSubtitle:_subtitle
                                                            andDescription:_description
                                                              andTitleHref:_titleHref
                                                           andMediaConfigs:(NSDictionary *)[self setConfigsOfImagesUrlObjects:_imageSrcArray
                                                                                                               andHrefObjects:_imageHrefArray]];
    [self publishOnMediaConfigs:mediaMessageArray 
            andMiniWordsConfigs:miniWordsArray
                     andMessage:_miniMessage];
    
}
/*
 * @ 一次性設定發表影音文章
 *
 * @ Post 影音留言的正確設定流程 : 
 *  1).  設定影片的 URL
 *  2).  影片縮圖 Src
 *  3).  未播放時呈現的影片縮圖寬高
 *  4).  播放時呈現的影片寬高
 *  5).  影音留言的大標題
 *  6).  副標題
 *  7).  說明內容
 *  8).  大標題的超連結
 *  9).  留言最下面的迷你小標題
 *  10). 點選迷你小標題時，要導向的網址
 *  11). 設定 MiniMessage 參數，會出現在大標題底下的那一空白區塊
 */
-(void)publishFeedsWithVideoUrl:(NSString *)_videoUrl
                       imageSrc:(NSString *)_imageSrc
                     imageWidth:(NSString *)_imageWidth
                    imageHeight:(NSString *)_imageHeight
                      playWidth:(NSString *)_playWidth
                     playHeight:(NSString *)_playHeight
                          title:(NSString *)_title
                       subtitle:(NSString *)_subtitle
                    description:(NSString *)_description
                      titleHref:(NSString *)_titleHref
                      miniTitle:(NSString *)_miniTitle
                  miniTitleHref:(NSString *)_miniTitleHref
                    miniMessage:(NSString *)_miniMessage
{
    NSDictionary *miniWordsArray    = [self _setupConfigsOfMiniTitle:_miniTitle 
                                                         andMiniHref:_miniTitleHref];
    NSDictionary *mediaMessageArray = [self setMediaAttachConfigsWithTitle:_title 
                                                               andSubtitle:_subtitle
                                                            andDescription:_description
                                                              andTitleHref:_titleHref
                                                           andMediaConfigs:[self setConfigsOfVideoUrl:_videoUrl 
                                                                                          andImageSrc:_imageSrc 
                                                                                        andImageWidth:_imageWidth 
                                                                                       andImageHeight:_imageHeight 
                                                                                         andPlayWidth:_playWidth 
                                                                                        andPlayHeight:_playHeight]];
    [self publishOnMediaConfigs:mediaMessageArray 
            andMiniWordsConfigs:miniWordsArray 
                     andMessage:_miniMessage];
    
}

#pragma Uploading Methods
/*
 * @上傳單張圖片
 *   _imageUrl    : 輸入圖片的 URL 進行上傳
 *   _description : 圖片敍述，可用 \n 斷行
 */ 
-(void)uploadWithPhotoUrl:(id)_imageUrl 
           andDescription:(NSString *)_description{
    self.executing  = @"upload.photos"; 
    self.processing = KRFacebookProcessForUploadPhoto;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self _setupParamsWithUploadImageUrl:_imageUrl 
                                                                                                    imageDescription:_description]];

    __block FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                    restMethod:@"photos.upload"
                                                    parameters:params
                                                    HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self _requestDidLoadResult:result];
    }];
    
}

/*
 * @上傳單張圖片
 *   _imageUrl    : 直接傳入圖片檔上傳
 *   _description : 圖片敍述，可用 \n 斷行
 */
-(void)uploadWithImage:(UIImage *)_image 
        andDescription:(NSString *)_description{
    self.executing  = @"upload.photos"; 
    self.processing = KRFacebookProcessForUploadPhoto;
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   _image, @"picture",
                                   _description, @"caption",
								   nil];
    __block FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                    restMethod:@"photos.upload"
                                                    parameters:params
                                                    HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self _requestDidLoadResult:result];
    }];
    
}

/*
 * @直接上傳影音
 *
 * @Sample : 
 *  [self uploadWithMediaPath:@"/Users/Tester/Desktop/sample.mp4" 
 *                   andTitle:@"測試標題 
 *             andDescription:@"測試說明"];
 */
-(void)uploadWithMediaPath:(NSString *)_filePath 
                  andTitle:(NSString *)_title 
            andDescription:(NSString *)_description{
    
    [self _uploadWithMediaConfigs:[self _setupParamsWithUploadMediaUrl:_filePath 
                                                             andTitle:_title 
                                                       andDescription:_description]];
}

/*
 * @上傳
 *   取得上傳限制大小
 */
-(void)getVideoUploadLimit{
    self.executing  = @"get.upload.limit.size"; //@"getVideoUploadLimit";
    self.processing = KRFacebookProcessForGetVideoUploadLimit;
    __block FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                    restMethod:@"video.getUploadLimits" 
                                                    parameters:nil
                                                    HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self _requestDidLoadResult:result];
    }];
    
}

#pragma Extra Methods
/*
 * @取得個人資訊
 *
 * @參數 _kindOf : 
 *
 *   傳入 photos      : 委派判斷 get.user.photos       :: 取得使用者相片
 *   傳入 permissions : 委派判斷 get.user.permissions  :: 取得認證類型資訊
 *   傳入 feed        : 委派判斷 get.user.feeds        :: 取得塗鴉牆資訊
 *   傳入 friends     : 委派判斷 get.user.friends      :: 取得朋友群資訊
 *   傳入 albums      : 委派判斷 get.user.albums       :: 取得相簿資訊
 *   傳入 me          : 委派判斷 get.user.informations :: 取得個人資訊
 *   傳入 groups      : 委派判斷 get.user.groups       :: 取得個人粉絲團
 *   傳入 uploads     : 委派判斷 get.user.uploads      :: 取得個人上傳過的影音資料
 *   傳入 home        : 委派判斷 get.user.homes        :: 取得個人首頁最新的塗鴉留言
 *   傳入 likes       : 委派判斷 get.user.links        :: 取得個人按過讚的粉絲團( 加入過的 )
 *   傳入 events      : 委派判斷 get.user.events       :: 取得個人正在進行的活動事件
 */
-(void)getUserInfoWithKindOf:(NSString *)_kindOf
{
    __block FBRequest *_fbRequest = nil;
    /*
     * @ 請求的 Graph API 方法
     */
    if( [_kindOf isEqualToString:@"photos"] )
    {
        //取得使用者相片
        self.executing  = @"get.user.photos";
        self.processing = KRFacebookProcessForGetUserPhotos;
        //這樣才能正確執行 ... 
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/photos"];
    }
    else if( [_kindOf isEqualToString:@"permissions"] )
    {
        //取得認證類型資訊 
        self.executing  = @"get.user.permissions";
        self.processing = KRFacebookProcessForGetUserPermissions;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/permissions"];
    }
    else if( [_kindOf isEqualToString:@"feed"] )
    {
        //取得塗鴉牆資訊
        self.executing  = @"get.user.feeds";
        self.processing = KRFacebookProcessForGetUserFeeds;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/feed"];
    }
    else if( [_kindOf isEqualToString:@"friends"] )
    {
        //取得朋友群資訊
        self.executing  = @"get.user.friends";
        self.processing = KRFacebookProcessForGetUserFriends;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/friends"];
    }
    else if( [_kindOf isEqualToString:@"albums"] )
    {
        //取得相簿資訊
        self.executing  = @"get.user.albums"; 
        self.processing = KRFacebookProcessForGetUserAlbums;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/permissions"];
    }
    else if( [_kindOf isEqualToString:@"uploads"] )
    {
        //取得個人上傳過的影音資料
        self.executing  = @"get.user.uploads";
        self.processing = KRFacebookProcessForGetUserUploads;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/videos/uploaded"];
    }
    else
    {
        //取得個人資訊
        self.executing  = @"get.user.informations";
        self.processing = KRFacebookProcessForGetUserInfo;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me"];
    }
    
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if( !error ){
            //NSLog(@"me %@", result);
            [self _requestDidLoadResult:result];
        }else{
            //NSLog(@"error : %@", error.description);
            [self _requestDidFailWithError:error];
        }

    }];
    
}

/*
 * @儲存離線 Access Token 值 ( 以便後續自動登入 )
 *   _saveOrClear = YES ; 儲存記錄
 *   _saveOrClear = NO  ; 刪除記錄
 */
-(void)saveAccessToken:(BOOL)_saveOrClear{
    //執行儲存
    if( _saveOrClear ){
        [self saveUserInfos:YES];
    }else{
        [self saveUserInfos:NO];
    }
}

/*
 * 儲存 User 資訊 ( 以便後續進行 User 資料處理 )
 *   _saveOrClear = YES ; 儲存記錄
 *   _saveOrClear = NO  ; 刪除記錄
 */
-(void)saveUserInfos:(BOOL)_saveOrClear{
    if( _saveOrClear ){
        self.saveUser = YES;
        [[NSUserDefaults standardUserDefaults] setObject:self.fbSession.accessToken forKey:FACEBOOK_ACCESS_TOKEN_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:self.fbSession.expirationDate forKey:FACEBOOK_EXPIRATION_DATE_KEY];
        [self getUserInfoWithKindOf:@"me"];
    }else{
        self.saveUser = NO;
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FACEBOOK_ACCESS_TOKEN_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FACEBOOK_EXPIRATION_DATE_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FACEBOOK_USER_ACCOUNT_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FACEBOOK_USER_ID_KEY];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/*
 * @登入
 *   permissions : 請求認證項目 ( Class 物件 ; 該物件的觸發方法 )
 * 
 * @附註
 *   如果沒有連網路，會無法出現 Facebook 的登入畫面
 *
 * @ FB API : V2.0 to V3.1 的差別 
 *   https://developers.facebook.com/docs/tutorial/iossdk/upgrading-from-2.0-to-3.1/#apichanges
 *
 */
-(void)loginWithPermissions:(NSArray *)permissions{
    /*
     * @ 這樣就能正確登入並取得 Token
     */
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.fbSession = appDelegate.session;
    //[self logout];
    //NSLog(@"appDelegate.session.isOpen %i", appDelegate.session.isOpen);
    if(!appDelegate.session.isOpen){
        //建立一個新的 FBSession
        if( [permissions count] > 0 ){
            self.fbPermissons = permissions;
        }
        appDelegate.session = [[FBSession alloc] initWithPermissions:self.fbPermissons];
        /*
         * @ Note 2013/02/11 23:00
         *   - 因為 In-App WebView 的方式突然被 Facebook 官方改掉，所以，就先改成跳出 App 的方式進行登入，
         *     因為只需要登入一次就夠了，這部份的 UXD 對使用者而言，不會造成什麼困擾。
         *     但是，Facebook SDK 3.x 的版本很常出錯，像今天測試就有出現好幾次「到 Safari 開啟時，是出現 Error 登入頁的窘況」。
         *
         *   - 如果要再改回 In-App WebView 的方式，就在這裡改回即可。但這還要看 FB 官方是否有開放 ... Orz
         *
         * @ Note 2013/02/12 10:00
         *
         *   - In-App WebView 的問題，官方似乎修正開放了，SDK 2.0 ~ 3.x 能正常執行中。( 但這裡還是要改成 SDK 3.1.1 的版本，以免官方又有問題 )
         *
         * @ Note 2013/03/12 AM 01:39
         *   
         *   - 應 Sky Lin 之要求，將登入方式從原先的 In-App WebView 的模式，改成使用專頁小助手的模式。
         *     也就是如果 User 有在 iPhone 的官方 Settings 裡設定 Facebook 帳號，
         *     或是 User 的 iPhone 裡有「Facebook 的官方 App」，
         *     則就能直接不輸入帳密登入，而如果以上都沒有設定，則會開啟 Safari 進行登入。
         *
         *   - FBSessionLoginBehaviorForcingWebView Changed to FBSessionLoginBehaviorUseSystemAccountIfPresent
         *
         */
        [appDelegate.session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            //NSLog(@"token : %@", session.accessToken);
            //NSLog(@"expirationDate : %@", session.expirationDate);
            //NSLog(@"permissions : %@", session.permissions);
            //
            self.fbSession = appDelegate.session;
            /* 
             * @ FBSession.activeSession.isOpen 同等 [facebook isSessionValid]
             */
            self.isLogged = self.fbSession.isOpen;
            if( self.fbSession.isOpen ){
                [self fbDidLogin];
            }else{
                [self fbDidNotLogin:YES];
            }
            if( status == FBSessionStateCreatedTokenLoaded ){
                //...
            }
            //NSLog(@"status : %i", status);
        }];
    }else{
        self.isLogged = self.fbSession.isOpen;
        [self fbDidLogin];
    }
}

/*
 * @直接使用預設的 Permissions 項目登入
 */
-(void)login
{
    [self loginWithPermissions:nil];
}

/*
 * 執行登出
 */
-(void)logout
{
    self.isLogged = NO;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.fbSession = appDelegate.session;
    [self.fbSession closeAndClearTokenInformation];
    [self fbDidLogout];
    self.fbSession = nil;
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* facebookCookies = [cookies cookiesForURL:
                                [NSURL URLWithString:@"http://login.facebook.com"]];
    
    for (NSHTTPCookie* cookie in facebookCookies) {
        [cookies deleteCookie:cookie];
    }
    /*
     * @加入下面這行就解決了登出異常的問題
     *
     *   原來是 Cookie 的暫存問題，造成了 Loging 會無限制的登入，
     *   即登出後，再按登入，會因為「清不乾淨」而再次直接性的登入，連帳密都不用打 ( XD )，
     *   所以才會有 Cookie 時效到了之後，突然登出「成功」的情況。
     */
    for (NSHTTPCookie *cookie in [cookies cookies]){
        NSString* domainName = [cookie domain];
        //NSLog(@"domainName 1 : %@", domainName);
        NSRange domainRange = [domainName rangeOfString:@"facebook"];
        if(domainRange.length > 0){
            [cookies deleteCookie:cookie];
        }
    }
}

/*
 * 取得 Facebook 影片的播放 URL
 */
-(NSString *)getVideoUrlWithId:(NSString *)_videoId{
    //EX: www.facebook.com/photo.php?v=316557165024694
    return [NSString stringWithFormat:@"http://www.facebook.com/photo.php?v=%@", _videoId];
}

/*
 * 取得檔案 MIME Type : 傳入副檔名
 */
-(NSString *)getFileMimeTypeWithExt:(NSString *)_fileExt{
    NSString *fileExt = [_fileExt lowercaseString];
    NSDictionary *extDicts = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"image/bmp",     @"bmp", 
                              @"image/cgm",     @"cgm",
                              @"image/gif",     @"gif",
                              @"image/ief",     @"ief",
                              @"image/jpeg",    @"jpeg",
                              @"image/jpeg",    @"jpg",
                              @"image/jpeg",    @"jpe",
                              @"image/png",     @"png",
                              @"image/svg+xml", @"svg",
                              @"image/tiff",    @"tiff",
                              @"image/tiff",    @"tif",
                              @"video/mpeg",    @"mpe",
                              @"video/mpeg",    @"mpeg",
                              @"video/mpeg",    @"mpg",
                              @"video/mpeg",    @"mpga",
                              @"audio/mpeg",    @"mp3",
                              @"video/mp4",     @"mp4",
                              @"video/quicktime", @"mov",
                              @"video/x-m4v",     @"m4v",
                              @"application/ogg", @"ogg",
                              @"audio/x-wav",   @"wav",
                              @"video/3gpp",    @"3gp",
                              @"application/vnd.ms-excel", @"xls",
                              @"application/vnd.ms-excel", @"xlsx",
                              @"application/xml", @"xml",
                              @"application/pdf", @"pdf",
                              @"application/zip", @"zip",
                              nil];
    return ( [[extDicts objectForKey:fileExt] length] > 0 ) ? [extDicts objectForKey:fileExt] : @"application/octet-stream";        
}

/*
 * @ 是否已登入
 *   如直接先執行這裡，則會將原先儲存的 FB TOKEN 值取出來認證
 *   這裡會執行 2 次 ( I don't know Why ?! )
 * 
 * @ 需注意這裡的 appDelegate.session 在登出時，
 *   如果 session 並沒有被完全的「正式啟動過」( 也就是沒有正式跑一輪「登入」的流程 )，就會操控失敗 ( 活化失敗 XD )。
 */
-(BOOL)alreadyLogged
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.fbSession = appDelegate.session;
    self.isLogged  = self.fbSession.isOpen;
    //self.isLogged = ( self.fbSession.isOpen || [self.fbSession.accessToken length] > 0 );
    return self.isLogged;
}

/*
 * @ 喚醒 Facebook Session
 */
+(BOOL)awakeSession
{
    return [[KRFacebook sharedManager] alreadyLogged];
}

-(BOOL)awakeSession
{
    return [self alreadyLogged];
}

/*
 * 清除已儲存的 FB 個人資訊
 */
-(void)clearSavedDatas{
    [self saveAccessToken:NO];
}

/*
 * @清除委派
 */
-(void)clearDelegates{
    self.delegate = nil;
}

/*
 * @取得 Token
 */
-(NSString *)getToken{
    return [[NSUserDefaults standardUserDefaults] objectForKey:FACEBOOK_ACCESS_TOKEN_KEY];
}

/*
 * @取得已儲存的個人資料
 */
-(NSDictionary *)getSavedDatas{
    return [self _getSavedDatas];
}


#pragma FacebookDelegate
/*
 * 成功登入 ( 因為 Login 會需要取得一些個人資訊，所以會再觸發 request:didLoad: ( 同時觸發 krFacebookDidFinishAllRequests ) 的委派 )
 */
-(void)fbDidLogin{
    if( self.fbSession.isOpen ){
        self.isLogged = YES;
        [self saveAccessToken:YES];
    }else{
        self.isLogged = NO;
    }
    self.executing  = @"login";
    self.processing = self.isLogged ? KRFacebookProcessForLogin : KRFacebookProcessForLoginFailed;
    if( [self.delegate respondsToSelector:@selector(krFacebook:didLogin:)] ){
        [self.delegate krFacebook:self didLogin:self.isLogged];
    }
    if( self.isLogged && [self.delegate respondsToSelector:@selector(krFacebookDidLogin)] ){
        [self.delegate krFacebookDidLogin];
    }
    if( !self.isLogged && [self.delegate respondsToSelector:@selector(krFacebookDidFailedLogin)] ){
        [self.delegate krFacebookDidFailedLogin];
    }
    
//    if( [self.delegate respondsToSelector:@selector(krFacebookDidFinishAllRequests)] ){
//        [self.delegate krFacebookDidFinishAllRequests];
//    }
    
}

/*
 * 取消登入
 */
-(void)fbDidNotLogin:(BOOL)cancelled{
    self.isLogged  = NO;
    self.executing = @"cancel";
    self.processing = KRFacebookProcessForCancell;
    if( [self.delegate respondsToSelector:@selector(krFacebook:didCancelLogin:)] ){
        [self.delegate krFacebook:self didCancelLogin:cancelled];
    }
    if( cancelled && [self.delegate respondsToSelector:@selector(krFacebookDidCancel)] ){
        [self.delegate krFacebookDidCancel];
    }
    if( [self.delegate respondsToSelector:@selector(krFacebookDidFinishAllRequests)] ){
        [self.delegate krFacebookDidFinishAllRequests];
    }
    //NSLog(@"fbDidNotLogin : %i", cancelled);
}

/*
 * 登出
 */
-(void)fbDidLogout{
    self.isLogged   = NO;
    self.executing  = @"logout";
    self.processing = KRFacebookProcessForLogout;
    //清除儲存的 Access Token 值
    [self saveAccessToken:NO];
    //觸發自訂義的 Delegate
    if( [self.delegate respondsToSelector:@selector(krFacebook:didLogout:)] ){
        [self.delegate krFacebook:self didLogout:self.isLogged];
    }
    if( !self.isLogged && [self.delegate respondsToSelector:@selector(krFacebookDidLogout)] ){
        [self.delegate krFacebookDidLogout];
    }
    if( [self.delegate respondsToSelector:@selector(krFacebookDidFinishAllRequests)] ){
        [self.delegate krFacebookDidFinishAllRequests];
    }
    //NSLog(@"fbDidLogout");
}





@end
