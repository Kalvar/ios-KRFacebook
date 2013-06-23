//
//  KRFacebook.m
//  V1.2
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 2013/01/20.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

/*
 * @self.requestStatus 參數說明 (後續會再增加) :
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

-(NSDictionary *)_getSavedPersonalInfo;

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
-(void)_saveOrClearAccessToken:(BOOL)_saveOrClear;
-(void)_saveOrClearUserInfo:(BOOL)_saveOrClear;

@end

@implementation KRFacebook (fixPrivate)

/*
 * @重要參數說明 : 
 *   self.needSavingUserInfo          = 登入後，儲存指定的使用者資訊
 *   self.devKey            = Facebook App 的 Developer Key
 *   self.requestPermissons = 登入後，要向 FB 請求的資料項目
 *   self.requestStatus         = 當前在執行的動作
 */
-(void)_initWithCommonVars:(NSString *)_devKeys andDelegate:(id<KRFacebookDelegate>)_delegate
{
    self.needSavingUserInfo     = NO;
    self.isLogged     = NO;
    self.delegate     = _delegate;
    self.devKey       = _devKeys;
    self.requestStatus = @"init";
    self.requestAction = KRFacebookRequestNothing;
    facebook           = nil; 
    jsonWriter         = [[FBSBJSON alloc] init];
    if( !self.requestPermissons )
    {
        self.requestPermissons = [NSArray arrayWithObjects:
                                  @"read_stream",
                                  @"publish_stream",
                                  @"offline_access",
                                  @"email",
                                  @"user_photos",
                                  @"user_events",
                                  @"user_checkins",
                                  nil];
    }
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.session.isOpen)
    {
        appDelegate.session = [[FBSession alloc] initWithPermissions:self.requestPermissons];
    }
    fbSession = appDelegate.session;
}

-(NSString *)_getSavedString:(NSString *)_nsdefaultKey
{
    return [NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:_nsdefaultKey]];
}

-(NSDictionary *)_getSavedPersonalInfo
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
    if( [self.delegate respondsToSelector:@selector(krFacebook:didSavedUserPrivateInfo:)] )
    {
        [self.delegate krFacebook:self didSavedUserPrivateInfo:[self _getSavedPersonalInfo]];
    }
}

/*
 * @上傳 : 
 *   取得上傳圖片所使用的參數(Params)
 */
-(NSDictionary *)_setupParamsWithUploadImageUrl:(id)_imageUrl 
                               imageDescription:(NSString *)_description{
    NSData *imageData;
    if( [_imageUrl isKindOfClass:[NSURL class]] )
    {
        imageData = [NSData dataWithContentsOfURL:(NSURL *)_imageUrl];
    }
    else
    {
        imageData = [NSData dataWithContentsOfFile:(NSString *)_imageUrl];
    }
    UIImage *image = [[UIImage alloc] initWithData:imageData];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   image,        @"picture",
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
    if( [mediaUrl isKindOfClass:[NSURL class]] )
    {
        mediaData = [NSData dataWithContentsOfURL:(NSURL *)mediaUrl];
    }
    else
    {
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
                                   mediaDesc,  @"description",
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
                                     message,             @"message",
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
                                       miniWordsJsonString,   @"action_links", 
                                       mediaAttachJsonString, @"attachment",
                                       message,               @"message",
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
                                                                miniHref,  @"href", 
                                                                nil], nil];    
    return miniWrodsConfigs;
}

/*
 * 上傳影片
 */
-(void)_uploadWithMediaConfigs:(NSDictionary *)_mediaConfigs{
    self.requestStatus  = @"upload.media";
    self.requestAction = KRFacebookRequestUploadMedia;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:_mediaConfigs];
    //Use Graph API
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
 *   - 原先是 request:(FBRequest *)request didLoad:(id)result
 */
-(void)_requestDidLoadResult:(id)result
{
	if ( [result isKindOfClass:[NSArray class]] )
    {
		result = [result objectAtIndex:0];
	}
    if( [result isKindOfClass:[NSData class]] )
    {
        NSString *_tempResult = [[NSString alloc] initWithData:(NSData *)result encoding:NSUTF8StringEncoding];
        result = [NSString stringWithString:_tempResult];
    }
    self.isString = [result isKindOfClass:[NSString class]] ? YES : NO;
    
    if( self.delegate )
    {
        if( [self.delegate respondsToSelector:@selector(krFacebookDidLoadWithResponses:)] )
        {
            [self.delegate krFacebookDidLoadWithResponses:result];
        }
        if( [self.delegate respondsToSelector:@selector(krFacebook:didLoadWithResponses:andKindOf:)] )
        {
            [self.delegate krFacebook:self didLoadWithResponses:result andKindOf:self.requestStatus];
        }
        if( self.isString && [self.delegate respondsToSelector:@selector(krFacebook:didLoadWithStringTypeResponse:andKindOf:)] )
        {
            [self.delegate krFacebook:self didLoadWithStringTypeResponse:result andKindOf:self.requestStatus];
        }
        else
        {
            if( self.needSavingUserInfo )
            {
                self.needSavingUserInfo = NO;
                [self _savingPrivateInformationOfUserInApp:result];
            }
            if([result isKindOfClass:[NSDictionary class]] && [self.delegate respondsToSelector:@selector(krFacebook:didLoadWithDictionaryTypeResponses:andKindOf:)])
            {
                [self.delegate krFacebook:self didLoadWithDictionaryTypeResponses:result andKindOf:self.requestStatus];
            }
        }
        if( [self.delegate respondsToSelector:@selector(krFacebookDidFinishAllRequests)] )
        {
            [self.delegate krFacebookDidFinishAllRequests];
        }
    }
    
}

-(void)_requestDidFailWithError:(NSError *)error
{
    if( [self.delegate respondsToSelector:@selector(krFacebook:didFailWithResponses:andKindOf:)] )
    {
        [self.delegate krFacebook:self didFailWithResponses:error andKindOf:self.requestStatus];
    }
}

/*
 * @儲存離線 Access Token 值 ( 以便後續自動登入 )
 *   _saveOrClear = YES ; 儲存記錄
 *   _saveOrClear = NO  ; 刪除記錄
 */
-(void)_saveOrClearAccessToken:(BOOL)_saveOrClear
{
    [self _saveOrClearUserInfo:_saveOrClear];
}

/*
 * 儲存 User 資訊 ( 以便後續進行 User 資料處理 )
 *   _saveOrClear = YES ; 儲存記錄
 *   _saveOrClear = NO  ; 刪除記錄
 */
-(void)_saveOrClearUserInfo:(BOOL)_saveOrClear
{
    if( _saveOrClear )
    {
        self.needSavingUserInfo = YES;
        [[NSUserDefaults standardUserDefaults] setObject:self.fbSession.accessToken forKey:FACEBOOK_ACCESS_TOKEN_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:self.fbSession.expirationDate forKey:FACEBOOK_EXPIRATION_DATE_KEY];
        [self getUserInfoWithKindOf:@"me"];
    }
    else
    {
        self.needSavingUserInfo = NO;
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FACEBOOK_ACCESS_TOKEN_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FACEBOOK_EXPIRATION_DATE_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FACEBOOK_USER_ACCOUNT_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FACEBOOK_USER_ID_KEY];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end

@implementation KRFacebook

@synthesize jsonWriter,
            facebook,
            devKey,
            delegate,
            isLogged,
            isString,
            requestStatus,
            needSavingUserInfo,
            requestPermissons;
@synthesize requestAction;
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
    if( self )
    {
        [self _initWithCommonVars:FACEBOOK_DEVELOPER_KEY andDelegate:_sdkDelegate];
    }
    return self;
}

-(KRFacebook *)initWithDevKey:(NSString *)_devKey delegate:(id<KRFacebookDelegate>)_sdkDelegate
{
    self = [super init];
    if( self )
    {
        NSString *_tempDevKeys = ( [_devKey length] > 0 )? _devKey : FACEBOOK_DEVELOPER_KEY;
        [self _initWithCommonVars:_tempDevKeys andDelegate:_sdkDelegate];
    }
    return self;
}

-(KRFacebook *)initWithPermissions:(NSArray *)_permissions delegate:(id<KRFacebookDelegate>)_sdkDelegate
{
    self = [super init];
    if( self )
    {
        self.requestPermissons = _permissions;
        [self _initWithCommonVars:FACEBOOK_DEVELOPER_KEY andDelegate:_sdkDelegate];
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
                                                            @"flash",       @"type",
                                                            videoSrc,       @"swfsrc",
                                                            imageSrc,       @"imgsrc",
                                                            imageWidth,     @"width", 
                                                            imageHeight,    @"height", 
                                                            expandedWidth,  @"expanded_width",
                                                            expandedHeight, @"expanded_height",
                                                            nil], nil];
    return mediaConfigs;
    
    
}

-(NSDictionary *)setConfigsOfImageUrl:(NSString *)imageSrc 
                              andHref:(NSString *)imageHref
{
    NSDictionary *mediaConfigs = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"image",  @"type",
                                                            imageSrc,  @"src",
                                                            imageHref, @"href",
                                                            nil], nil];    
    return mediaConfigs;
    
}

-(NSArray *)setConfigsOfImagesUrlObjects:(NSArray *)imageSrcArray
                          andHrefObjects:(NSArray *)imageHrefArray
{
    NSMutableArray *tempMediaConfigs = [[NSMutableArray alloc] initWithCapacity:0];
    int _count = [imageSrcArray count];
    for( int i=0; i<_count; i++ )
    {
        [tempMediaConfigs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     @"image",                         @"type",
                                     [imageSrcArray objectAtIndex:i],  @"src",
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
                                                            @"music",   @"type",
                                                            musicSrc,   @"src",
                                                            songName,   @"title",
                                                            singerName, @"artist", 
                                                            albumName,  @"album", 
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
    self.requestStatus  = @"post.feeds.word";
    self.requestAction = KRFacebookRequestPublishToFeeds;
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
    self.requestStatus  = @"post.feeds.media"; 
    self.requestAction = KRFacebookRequestPublishToMedia;
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
 *   NSArray *imagesUrls  = [NSArray arrayWithObjects:@"http://www.test.com/images/poster/fb_poster.png", 
 *                                                    @"http://www.test.com/images/poster/test_about_poster.png", 
 *                                                    nil];
 *   //點選圖片時，要導向的 URL
 *   NSArray *imageJumps = [NSArray arrayWithObjects:@"http://www.test.com/?menu=fb", 
 *                                                   @"http://www.test.com/?menu=test_about", 
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

#pragma Uploading Photos
-(void)uploadWithPhotoURL:(NSURL *)_photoURL description:(NSString *)_description
{
    self.requestStatus = @"upload.photos"; 
    self.requestAction = KRFacebookRequestUploadPhoto;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self _setupParamsWithUploadImageUrl:_photoURL 
                                                                                                    imageDescription:_description]];

    __block FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                    restMethod:@"photos.upload"
                                                    parameters:params
                                                    HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self _requestDidLoadResult:result];
    }];
}

-(void)uploadWithPhotoPath:(NSString *)_photoPath description:(NSString *)_description
{
    self.requestStatus = @"upload.photos";
    self.requestAction = KRFacebookRequestUploadPhoto;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self _setupParamsWithUploadImageUrl:_photoPath
                                                                                                    imageDescription:_description]];
    
    __block FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                            restMethod:@"photos.upload"
                                                            parameters:params
                                                            HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self _requestDidLoadResult:result];
    }];
}

-(void)uploadWithImage:(UIImage *)_image description:(NSString *)_description
{
    self.requestStatus = @"upload.photos";
    self.requestAction = KRFacebookRequestUploadPhoto;
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   _image,       @"picture",
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

#pragma Uploading Media
-(void)uploadWithMediaPath:(NSString *)_filePath title:(NSString *)_title description:(NSString *)_description
{    
    [self _uploadWithMediaConfigs:[self _setupParamsWithUploadMediaUrl:_filePath 
                                                              andTitle:_title 
                                                        andDescription:_description]];
}

-(void)getVideoUploadLimitSize
{
    self.requestStatus  = @"get.upload.limit.size";
    self.requestAction = KRFacebookRequestGetVideoUploadLimitSize;
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
        self.requestStatus  = @"get.user.photos";
        self.requestAction = KRFacebookRequestGetUserPhotos;
        //這樣才能正確執行 ... 
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/photos"];
    }
    else if( [_kindOf isEqualToString:@"permissions"] )
    {
        //取得認證類型資訊 
        self.requestStatus  = @"get.user.permissions";
        self.requestAction = KRFacebookRequestGetUserAcceptedPermissions;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/permissions"];
    }
    else if( [_kindOf isEqualToString:@"feed"] )
    {
        //取得塗鴉牆資訊
        self.requestStatus  = @"get.user.feeds";
        self.requestAction = KRFacebookRequestGetUserFeeds;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/feed"];
    }
    else if( [_kindOf isEqualToString:@"friends"] )
    {
        //取得朋友群資訊
        self.requestStatus  = @"get.user.friends";
        self.requestAction = KRFacebookRequestGetUserFriends;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/friends"];
    }
    else if( [_kindOf isEqualToString:@"albums"] )
    {
        //取得相簿資訊
        self.requestStatus  = @"get.user.albums"; 
        self.requestAction = KRFacebookRequestGetUserAlbums;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/permissions"];
    }
    else if( [_kindOf isEqualToString:@"uploads"] )
    {
        //取得個人上傳過的影音資料
        self.requestStatus  = @"get.user.uploads";
        self.requestAction = KRFacebookRequestGetUserAllUploaded;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me/videos/uploaded"];
    }
    else
    {
        //取得個人資訊
        self.requestStatus  = @"get.user.informations";
        self.requestAction = KRFacebookRequestGetUserPersonalInfo;
        _fbRequest = [[FBRequest alloc] initWithSession:self.fbSession graphPath:@"me"];
    }
    
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if( !error )
        {
            //NSLog(@"me %@", result);
            [self _requestDidLoadResult:result];
        }
        else
        {
            //NSLog(@"error : %@", error.description);
            [self _requestDidFailWithError:error];
        }

    }];
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
-(void)loginWithPermissions:(NSArray *)permissions
{
    /*
     * @ 這樣就能正確登入並取得 Token
     */
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.fbSession = appDelegate.session;
    //[self logout];
    //NSLog(@"appDelegate.session.isOpen %i", appDelegate.session.isOpen);
    if(!appDelegate.session.isOpen)
    {
        //建立一個新的 FBSession
        if( [permissions count] > 0 )
        {
            self.requestPermissons = permissions;
        }
        appDelegate.session = [[FBSession alloc] initWithPermissions:self.requestPermissons];
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
         *   - 將登入方式從原先的 In-App WebView 的模式，改成使用專頁小助手的模式。
         *     也就是如果 User 有在 iPhone 的官方 Settings 裡設定 Facebook 帳號，
         *     或是 User 的 iPhone 裡有「Facebook 的官方 App」，
         *     則就能直接不輸入帳密登入，而如果以上都沒有設定，則會開啟 Safari 進行登入。
         *
         *   - FBSessionLoginBehaviorForcingWebView Changed to FBSessionLoginBehaviorUseSystemAccountIfPresent
         *   - FBSessionLoginBehaviorUseSystemAccountIfPresent Changed to FBSessionLoginBehaviorWithNoFallbackToWebView 
         *     ( 這樣才能避免 Apple Settings 裡有綁定 Facebook Account 時，登入失效的問題。 )
         *
         */
        [appDelegate.session openWithBehavior:FBSessionLoginBehaviorWithNoFallbackToWebView completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            //NSLog(@"token : %@", session.accessToken);
            //NSLog(@"expirationDate : %@", session.expirationDate);
            //NSLog(@"permissions : %@", session.permissions);
            self.fbSession = appDelegate.session;
            //FBSession.activeSession.isOpen 同等 [facebook isSessionValid]
            self.isLogged = self.fbSession.isOpen;
            if( self.fbSession.isOpen )
            {
                [self fbDidLogin];
            }
            else
            {
                [self fbDidNotLogin:YES];
            }
            if( status == FBSessionStateCreatedTokenLoaded )
            {
                //...
            }
            //NSLog(@"status : %i", status);
        }];
    }
    else
    {
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
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* facebookCookies     = [cookies cookiesForURL:[NSURL URLWithString:@"http://login.facebook.com"]];
    
    for (NSHTTPCookie* cookie in facebookCookies)
    {
        [cookies deleteCookie:cookie];
    }
    /*
     * @加入下面這行就解決了登出異常的問題
     *
     *   原來是 Cookie 的暫存問題，造成了 Loging 會無限制的登入，
     *   即登出後，再按登入，會因為「清不乾淨」而再次直接性的登入，連帳密都不用打 ( XD )，
     *   所以才會有 Cookie 時效到了之後，突然登出「成功」的情況。
     */
    for (NSHTTPCookie *cookie in [cookies cookies])
    {
        NSString* domainName = [cookie domain];
        NSRange domainRange  = [domainName rangeOfString:@"facebook"];
        if(domainRange.length > 0)
        {
            [cookies deleteCookie:cookie];
        }
    }
}

/*
 * 取得 Facebook 影片的播放 URL
 */
-(NSString *)getVideoURLWithId:(NSString *)_videoId
{
    //EX: www.facebook.com/photo.php?v=316557165024694
    return [NSString stringWithFormat:@"http://www.facebook.com/photo.php?v=%@", _videoId];
}

-(NSString *)getFileMimeTypeWithExt:(NSString *)_fileExt
{
    NSString *fileExt      = [_fileExt lowercaseString];
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
    if( [appDelegate.session.accessToken length] > 0 )
    {
        if( !appDelegate.session.isOpen )
        {
            //這裡重複呼叫是會 Crash 的，要小心使用
            [appDelegate.session openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                //...
            }];
        }
    }
    self.fbSession = appDelegate.session;
    self.isLogged  = self.fbSession.isOpen;
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

-(void)saveAccessToken
{
    [self _saveOrClearAccessToken:YES];
}

-(void)clearAccessToken
{
    [self _saveOrClearAccessToken:NO];
}

-(void)savePersonalInfo
{
    [self _saveOrClearUserInfo:YES];
}

-(void)clearSavedPersonalInfo
{
    [self _saveOrClearUserInfo:NO];
}

-(void)clearDelegates
{
    self.delegate = nil;
}

/*
 * @ 取得儲存的 AccessToken
 */
-(NSString *)getSavedAccessToken
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:FACEBOOK_ACCESS_TOKEN_KEY];
}

/*
 * @ 取得已儲存的個人資料
 */
-(NSDictionary *)getSavedPersonalInfo
{
    return [self _getSavedPersonalInfo];
}

#pragma FacebookDelegate
/*
 * @ 成功登入 
 *   - 因為 Login 會需要取得一些個人資訊，所以會再觸發 request:didLoad: ( 同時觸發 krFacebookDidFinishAllRequests ) 的委派
 */
-(void)fbDidLogin
{
    if( self.fbSession.isOpen )
    {
        self.isLogged = YES;
        [self _saveOrClearAccessToken:YES];
    }
    else
    {
        self.isLogged = NO;
    }
    self.requestStatus  = @"login";
    self.requestAction = self.isLogged ? KRFacebookRequestLogin : KRFacebookRequestLoginFailed;
    if( self.delegate )
    {
        //OK
        if( self.isLogged && [self.delegate respondsToSelector:@selector(krFacebookDidLogin)] )
        {
            [self.delegate krFacebookDidLogin];
        }
        //Failed
        if( !self.isLogged && [self.delegate respondsToSelector:@selector(krFacebookDidFailedLogin)] )
        {
            [self.delegate krFacebookDidFailedLogin];
        }
    }
}

/*
 * @ 取消登入
 */
-(void)fbDidNotLogin:(BOOL)cancelled
{
    self.isLogged      = NO;
    self.requestStatus = @"cancel";
    self.requestAction = KRFacebookRequestCancel;
    if( self.delegate )
    {
        if( cancelled && [self.delegate respondsToSelector:@selector(krFacebookDidCancel)] )
        {
            [self.delegate krFacebookDidCancel];
        }
        if( [self.delegate respondsToSelector:@selector(krFacebookDidFinishAllRequests)] )
        {
            [self.delegate krFacebookDidFinishAllRequests];
        }
    }
}

/*
 * @ 登出
 */
-(void)fbDidLogout
{
    self.isLogged       = NO;
    self.requestStatus  = @"logout";
    self.requestAction  = KRFacebookRequestLogout;
    [self _saveOrClearAccessToken:NO];
    if( self.delegate )
    {
        if( !self.isLogged && [self.delegate respondsToSelector:@selector(krFacebookDidLogout)] )
        {
            [self.delegate krFacebookDidLogout];
        }
        if( [self.delegate respondsToSelector:@selector(krFacebookDidFinishAllRequests)] )
        {
            [self.delegate krFacebookDidFinishAllRequests];
        }
    }
}

@end
