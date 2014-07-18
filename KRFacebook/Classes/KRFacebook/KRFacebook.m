//
//  KRFacebook.m
//  V2.2
//
//  Created by Kalvar on 13/9/19.
//  Copyright (c) 2012 - 2014年 Kuo-Ming Lin. All rights reserved.
//

#import "KRFacebook.h"
#import "KRFacebookTools.h"
#import "FBSBJSON.h"

//Facebooks
static NSString *_kKRFacebookUserInfoKey     = @"_kKRFacebookUserInfoKey";
static NSString *_kKRFacebookUserIdKey       = @"_kKRFacebookUserIdKey";
static NSString *_kKRFacebookEmailKey        = @"_kKRFacebookEmailKey";
static NSString *_kKRFacebookNameKey         = @"_kKRFacebookNameKey";
static NSString *_kKRFacebookGenderKey       = @"_kKRFacebookGenderKey";
static NSString *_kKRFacebookAccessTokenKey  = @"_kKRFacebookAccessTokenKey";

@interface KRFacebook ()
{
    FBSBJSON *_jsonWriter;
}

@property (nonatomic, strong) FBSBJSON *_jsonWriter;

@end

@implementation KRFacebook (fixPrivate)

-(void)_initWithVars
{
    self.accessToken = nil;
    self.permissions = @[//@"read_mailbox",
                         //@"manage_notifications",
                         //@"user_photos",
                         //@"user_events",
                         //@"user_checkins",
                         @"user_birthday",
                         @"read_stream",
                         @"email",
                         @"publish_stream"];
    _jsonWriter      = [[FBSBJSON alloc] init];
    
}

@end

@implementation KRFacebook (fixSessions)

#pragma --mark Getters
-(FBSession *)_getActiveFBSession
{
    return [KRFacebookTools getAppDelegate].session;
}

-(NSDictionary *)_getUserInfo
{
    return [KRFacebookTools getDefaultValueForKey:_kKRFacebookUserInfoKey];
}

-(NSString *)_getUserId
{
    return [KRFacebookTools getDefaultStringValueForKey:_kKRFacebookUserIdKey];
}

-(NSString *)_getName
{
    return [KRFacebookTools getDefaultStringValueForKey:_kKRFacebookNameKey];
}

-(NSString *)_getEmail
{
    return [KRFacebookTools getDefaultStringValueForKey:_kKRFacebookEmailKey];
}

-(NSString *)_getGender
{
    return [KRFacebookTools getDefaultStringValueForKey:_kKRFacebookGenderKey];
}

-(NSString *)_getAccessToken
{
    return [KRFacebookTools getDefaultStringValueForKey:_kKRFacebookAccessTokenKey];
}

#pragma --mark Setters
-(void)_saveUserInfo:(NSDictionary *)_facebookUserInfo
{
    [KRFacebookTools setDefaultValue:_facebookUserInfo forKey:_kKRFacebookUserInfoKey];
}

-(void)_saveUserId:(NSString *)_facebookId
{
    [KRFacebookTools setDefaultStringValue:_facebookId forKey:_kKRFacebookUserIdKey];
}

-(void)_saveEmail:(NSString *)_facebookEmail
{
    [KRFacebookTools setDefaultStringValue:_facebookEmail forKey:_kKRFacebookEmailKey];
}

-(void)_saveName:(NSString *)_facebookName
{
    [KRFacebookTools setDefaultStringValue:_facebookName forKey:_kKRFacebookNameKey];
}

-(void)_saveGender:(NSString *)_facebookGender
{
    [KRFacebookTools setDefaultStringValue:_facebookGender forKey:_kKRFacebookGenderKey];
}

-(void)_saveAccessToken:(NSString *)_facebookAccessToken
{
    [KRFacebookTools setDefaultStringValue:_facebookAccessToken forKey:_kKRFacebookAccessTokenKey];
}

#pragma --mark Login, Logout, Wakeup
-(void)_updateSession
{
    AppDelegate *appDelegate = [KRFacebookTools getAppDelegate];
    if (!appDelegate.session.isOpen)
    {
        appDelegate.session = [[FBSession alloc] init];
        if (appDelegate.session.state == FBSessionStateCreatedTokenLoaded)
        {
            [appDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                             FBSessionState status,
                                                             NSError *error) {
                //...
                self.fbSession = session;
            }];
        }
    }
}

-(void)_loginFacebookWithCompletion:( void(^)(BOOL success, NSDictionary *userInfo) )_completion
{
    AppDelegate *appDelegate = [KRFacebookTools getAppDelegate];
    if (appDelegate.session.state != FBSessionStateCreated)
    {
        appDelegate.session = [[FBSession alloc] initWithPermissions:permissions];
    }
    [appDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                     FBSessionState status,
                                                     NSError *error)
     {
         //檢查是否未存有 Facebook User ID
         NSString *_savedUserId = [self _getUserId];
         if( [_savedUserId length] < 1 || [_savedUserId isEqualToString:@"(null)"] || !_savedUserId )
         {
             //取出使用者的 facebook id 存起來備用
             FBRequest *_fbRequest = [FBRequest requestForMe];
             [_fbRequest setSession:session];
             [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
              {
                  NSMutableDictionary *_userInfo = nil;
                  if( [result isKindOfClass:[NSDictionary class]] )
                  {
                      _userInfo = (NSMutableDictionary *)result;
                      //NSLog(@"_userInfo : %@", _userInfo);
                      if( [_userInfo count] > 0 )
                      {
                          //Save Facebook Infomation.
                          NSString *_accessToken = session.accessTokenData.accessToken;
                          [_userInfo setObject:_accessToken forKey:@"access_token"];
                          self.accessToken = _accessToken;
                          [self _saveUserInfo:_userInfo];
                          [self _saveUserId:[_userInfo objectForKey:@"id"]];
                          [self _saveEmail:[_userInfo objectForKey:@"email"]];
                          [self _saveName:[_userInfo objectForKey:@"name"]];
                          [self _saveGender:[_userInfo objectForKey:@"gender"]];
                          [self _saveAccessToken:_accessToken];
                      }
                  }
                  if( _completion )
                  {
                      _completion( !( error ), _userInfo );
                  }
              }];
         }
         else
         {
             //有 User Id 就直接更新
             if( _completion )
             {
                 _completion( !( error ), [self _getUserInfo] );
             }
         }
     }];
}

-(void)_logoutFacebook
{
    [KRFacebookTools removeDefaultValueForKey:_kKRFacebookUserInfoKey];
    [KRFacebookTools removeDefaultValueForKey:_kKRFacebookUserIdKey];
    [KRFacebookTools removeDefaultValueForKey:_kKRFacebookEmailKey];
    [KRFacebookTools removeDefaultValueForKey:_kKRFacebookNameKey];
    [KRFacebookTools removeDefaultValueForKey:_kKRFacebookGenderKey];
    [KRFacebookTools removeDefaultValueForKey:_kKRFacebookAccessTokenKey];
    [[KRFacebookTools getAppDelegate].session closeAndClearTokenInformation];
}

-(BOOL)_sessionIsOpen
{
    return [KRFacebookTools getAppDelegate].session.isOpen;
}

-(NSString *)_convertHttpMethod:(KRFacebookHttpMethods)_httpMethod
{
    NSString *_httpMethodString = @"GET";
    switch (_httpMethod)
    {
        case KRFacebookHttpMethodPost:
            _httpMethodString = @"POST";
            break;
        case KRFacebookHttpMethodGet:
        default:
            break;
    }
    return _httpMethodString;
}

@end

@implementation KRFacebook (fixRequests)

#pragma --mark Uploading Methods
/*
 * @ Get params up with uploading a photo.
 *   - 設定上傳圖片所使用的參數
 */
-(NSDictionary *)_getUploadParamsWithImage:(UIImage *)_image description:(NSString *)_description
{
    NSDictionary *_params = nil;
    if( _image )
    {
        _params = [NSDictionary dictionaryWithObjectsAndKeys:
                   _image,       @"picture",
                   _description, @"caption",
                   nil];
    }
    return _params;
}

//For an image from http.
-(NSDictionary *)_getUploadParamsWithPhotoHttpURL:(NSURL *)_imageURL description:(NSString *)_description
{
    NSDictionary *_params = nil;
    if( [_imageURL isKindOfClass:[NSURL class]] )
    {
        _params = [self _getUploadParamsWithImage:[[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:_imageURL]]
                                      description:_description];
    }
    return _params;
}

//For an image from local path.
-(NSDictionary *)_getUploadParamsWithPhotoLocalPath:(NSString *)_imagePath description:(NSString *)_description
{
    NSDictionary *_params = nil;
    if( _imagePath )
    {
        _params = [self _getUploadParamsWithImage:[[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:_imagePath]]
                                      description:_description];
    }
    return _params;
}

/*
 * @ Get params up with uploading a video.
 *   - 取得上傳影音所使用的參數
 */
-(NSDictionary *)_getUploadParamsWithVideoData:(NSData *)_videoData videoURL:(NSString *)_videoURL title:(NSString *)_videoTitle description:(NSString *)_videoDescription
{
    NSDictionary *_params = nil;
    if( _videoData )
    {
        NSArray *_urls       = [_videoURL componentsSeparatedByString:@"/"];
        NSString *_videoName = [[_urls lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *_names      = [_videoName componentsSeparatedByString:@"."];
        NSString *_videoExt  = [[_names lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        _params = [NSDictionary dictionaryWithObjectsAndKeys:
                   _videoData,        _videoName,
                   [KRFacebookTools getFileMimeTypeWithExt:_videoExt], @"contentType",
                   _videoTitle,        @"title",
                   _videoDescription,  @"description",
                   nil];
    }
    return _params;
}

//For a Http video.
-(NSDictionary *)_getUploadParamsWithVideoHttpURL:(NSURL *)_videoURL title:(NSString *)_videoTitle description:(NSString *)_videoDescription
{
    NSDictionary *_params = nil;
    if( [_videoURL isKindOfClass:[NSURL class]] )
    {
        _params = [self _getUploadParamsWithVideoData:[NSData dataWithContentsOfURL:_videoURL]
                                             videoURL:(NSString *)_videoURL
                                                title:_videoTitle
                                          description:_videoDescription];
    }
    return _params;
}

//For a Locale path video.
-(NSDictionary *)_getUploadParamsWithVideoLocalPath:(NSString *)_videoPath title:(NSString *)_videoTitle description:(NSString *)_videoDescription
{
    NSDictionary *_params = nil;
    if( _videoPath )
    {
        _params = [self _getUploadParamsWithVideoData:[NSData dataWithContentsOfFile:_videoPath]
                                             videoURL:_videoPath
                                                title:_videoTitle
                                          description:_videoDescription];
    }
    return _params;
}

#pragma --mark Publish to the Wall of News Feed.
/*
 * @ Set pure publish to the news feed talking info.
 *   - 設定純文字留言使用的參數字串
 */
-(NSDictionary *)_getPublishParamsWithBottomWordsInfo:(NSDictionary *)_bottomWords talkMessage:(NSString *)_talkMessage
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [_jsonWriter stringWithObject:_bottomWords error:nil], @"action_links",
            _talkMessage, @"message",
            nil];
}

/*
 * @ Set media ( video, music ) publish to the news feed talking info.
 *   - 設定多媒體留言使用的參數字串
 */
-(NSDictionary *)_getPublishParamsWithVideoInfo:(NSDictionary *)_videoInfo bottomWordsInfo:(NSDictionary *)_bottomWordsInfo talkMessage:(NSString *)_talkMessage
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [_jsonWriter stringWithObject:_videoInfo],       @"action_links",
            [_jsonWriter stringWithObject:_bottomWordsInfo], @"attachment",
            _talkMessage,                                    @"message",
            nil];
}

/*
 * @ Set the mini-topic at the each feed wall bottom.
 *   - 設定迷你文字標題留言
 */
-(NSDictionary *)_getPublishParamsWithBottomTitle:(NSString *)_bottomTitle titleURL:(NSString *)_titleURL
{
    return (NSDictionary *)[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      _bottomTitle, @"text",
                                                      _titleURL,    @"href",
                                                      nil], nil];
}

#pragma --mark Errors
-(NSError *)_errorWithNotLogin
{
    return [NSError errorWithDomain:@"facebook.handler"
                               code:101 //It's not login code.
                           userInfo:nil];
}

-(NSError *)_errorWithNoParams
{
    return [NSError errorWithDomain:@"facebook.handler.no.params"
                               code:102 //It's not params.
                           userInfo:nil];
}

#pragma --mark Judeges
-(void)_judgeFBSessionStatus
{
    if( !fbSession )
    {
        [self awakeFBSession];
    }
}

@end

@implementation KRFacebook (fixSettings)

#pragma --mark Settup Attach Configs
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
                                       subtitle:(NSString *)subtitle
                                    description:(NSString *)description
                                       titleURL:(NSString *)titleURL
                                   mediaConfigs:(NSDictionary *)mediaConfigs
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            title,        @"name",
            subtitle,     @"caption",
            description,  @"description",
            mediaConfigs, @"media",
            titleURL,     @"href",
            nil];
}

#pragma --mark 多媒體留言的共用方法
/*
 * @ 多媒體留言
 * @ Publish media message to the news feed wall.
 *   - This method can send types :
 *     - Words + Youtube Video
 *     - Words + Photo
 *     - Words + Music
 */
-(void)publishWithMediaAttachs:(NSDictionary *)_attachs
                       configs:(NSDictionary *)_configs
                       message:(NSString *)message
                  errorHandler:(KRFacebookErrorHandler)_errorHandler
             completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    NSDictionary *_params = [NSDictionary dictionaryWithObjectsAndKeys:
                             [_jsonWriter stringWithObject:_attachs], @"attachment",
                             [_jsonWriter stringWithObject:_configs], @"action_links",
                             message, @"message",
                             nil];
    FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                    restMethod:@"stream.publish"
                                                    parameters:_params
                                                    HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if( error )
        {
            if( _errorHandler )
            {
                _errorHandler(error);
            }
        }
        if( _completionHandler )
        {
            _completionHandler( !(error) , result);
        }
    }];
}

@end


@implementation KRFacebook

@synthesize fbSession   = _fbSession;
@synthesize accessToken = _accessToken;
@synthesize permissions = _permissions;
@synthesize _jsonWriter;

+(KRFacebook *)sharedManager
{
    static dispatch_once_t pred;
    static KRFacebook *_object = nil;
    dispatch_once(&pred, ^{
        _object = [[KRFacebook alloc] init];
        //[_object _initWithVars];
    });
    return _object;
}

-(id)init
{
    self = [super init];
    if( self )
    {
        [self _initWithVars];
    }
    return self;
}

#pragma --mark FacebookSDK & Information
/*
 * @ 登出入 Facebook
 */
-(void)login
{
    [self _loginFacebookWithCompletion:nil];
}

-(void)loginWithCompletion:( void(^)(BOOL success, NSDictionary *userInfo) )_completion
{
    [self _loginFacebookWithCompletion:_completion];
}

-(void)logout
{
    [self _logoutFacebook];
}

/*
 * @ 喚醒 FacebookSDK 的 FBSession 並進行驗證
 */
-(void)awakeFBSession
{
    [self _updateSession];
}

/*
 * @ FacebookSDK 的 FBSession 是否已喚醒並可使用
 */
-(BOOL)isFBSessionOpen
{
    return [self _sessionIsOpen];
}

/*
 * @ 取得 FBSession
 */
-(FBSession *)getActiveFBSession
{
    return [self _getActiveFBSession];
}

#pragma --mark Getters
-(NSString *)accessToken
{
    NSString *_token = nil;
    _fbSession = [self getActiveFBSession];
    if( _fbSession )
    {
        _token = _fbSession.accessTokenData.accessToken;
    }
    return _token;
    //return [self _getAccessToken];
}

-(FBSession *)fbSession
{
    if( !_fbSession )
    {
        _fbSession = [self getActiveFBSession];
    }
    return _fbSession;
}

/*
 * @ 取得儲存的 Facebook 資料
 */
-(NSDictionary *)userInfo
{
    return [self _getUserInfo];
}

-(NSString *)userId
{
    return [self _getUserId];
}

-(NSString *)userEmail
{
    return [self _getEmail];
}

-(NSString *)userName
{
    return [self _getName];
}

-(NSString *)userGender
{
    return [self _getGender];
}

#pragma --mark Publishing News Feed (發佈各式留言)
/*
 * @ Publish pure message to the news feed wall.
 *
 * @ 發佈純文字留言 :
 *
 *   _title     : 留言最下面的迷你小標題
 *   _titleURL  : 點小標題時要導向的超連結
 *   _message   : 留言主內容
 *
 */
-(void)publishNewsFeedWallWithTitle:(NSString *)_title
                           titleURL:(NSString *)_titleURL
                            message:(NSString *)_message
                       errorHandler:(KRFacebookErrorHandler)_errorHandler
                  completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    if( !self.fbSession )
    {
        return;
    }
    //Use REST API
    NSString *_jsonString = [_jsonWriter stringWithObject:[self _getPublishParamsWithBottomTitle:_title titleURL:_titleURL] error:nil];
    NSDictionary *_params = [NSDictionary dictionaryWithObjectsAndKeys:
                             _jsonString, @"action_links",
                             _message,    @"message",
                             nil];
    FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:_fbSession
                                                    restMethod:@"stream.publish"
                                                    parameters:_params
                                                    HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if( error )
        {
            if( _errorHandler )
            {
                _errorHandler(error);
            }
        }
        if( _completionHandler )
        {
            _completionHandler( !(error) , result);
        }
    }];
    
}

/*
 * @ 一次性設定發表單張圖片留言 : MiniMessage 會出現在 Title 下面那一區
 *
 * @ Post 單張圖片留言的正確設定流程
 *
 * @ Publish a Photo to News Feed Wall.
 *
 *   - _photoURL        : 設定圖片的 URL
 *   - _photoTurnURL    : 點選圖片時，要導向的網址
 *   - _title           : 設定圖片留言的大標題
 *   - _subtitle        : 副標題
 *   - _description     : 說明內容
 *   - _titleURL        : 大標題的超連結
 *   - _bottomTitle     : 迷你標題
 *   - _bottomTitleURL  : 點選迷你標題時，要導向的網址
 *   - _bottomMessage   : 設定 MiniMessage 參數，會出現在大標題底下的那一空白區塊
 *
 */
-(void)publishNewsFeedWithPhotoURL:(NSString *)_photoURL
                 clickPhotoTurnURL:(NSString *)_photoTurnURL
                             title:(NSString *)_title
                          subtitle:(NSString *)_subtitle
                       description:(NSString *)_description
                          titleURL:(NSString *)_titleURL
                       bottomTitle:(NSString *)_bottomTitle
                    bottomTitleURL:(NSString *)_bottomTitleURL
                     bottomMessage:(NSString *)_bottomMessage
                   errorHandler:(KRFacebookErrorHandler)_errorHandler
              completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    if( !self.fbSession )
    {
        return;
    }
    NSDictionary *_attachs = [self setMediaAttachConfigsWithTitle:_title
                                                         subtitle:_subtitle
                                                      description:_description
                                                         titleURL:_titleURL
                                                     mediaConfigs:[self setConfigsOfImageUrl:_photoURL andHref:_photoTurnURL]];
    NSDictionary *_configs = [self _getPublishParamsWithBottomTitle:_bottomTitle titleURL:_bottomTitleURL];
    [self publishWithMediaAttachs:_attachs
                          configs:_configs
                          message:_bottomMessage
                     errorHandler:_errorHandler
                completionHandler:_completionHandler];
}

/*
 * @ 發佈多張圖片至塗鴉牆
 *   - Publish several photos to the news feed.
 *
 * @ Sample Params :
 *
 *   //It's a photo Http URL sets.
 *   NSArray *photoURLs     = [NSArray arrayWithObjects:@"http://test.com/1.png",
 *                                                      @"http://test.com/2.png",
 *                                                      nil];
 *
 *   //It will turn to the URL when clicks the photo. ( 點選圖片時，要導向的 URL )
 *   NSArray *photoTurnURLs = [NSArray arrayWithObjects:@"http://www.test.com/?menu=fb",
 *                                                      @"http://www.test.com/?menu=test_about",
 *                                                      nil];
 *
 */
-(void)publishNewsFeedWithPhotoURLs:(NSArray *)_photoURLs
                      photoTurnURLs:(NSArray *)_photoTurnURLs
                              title:(NSString *)_title
                           subtitle:(NSString *)_subtitle
                        description:(NSString *)_description
                           titleURL:(NSString *)_titleURL
                        bottomTitle:(NSString *)_bottomTitle
                     bottomTitleURL:(NSString *)_bottomTitleURL
                      bottomMessage:(NSString *)_bottomMessage
                       errorHandler:(KRFacebookErrorHandler)_errorHandler
                  completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    if( !self.fbSession )
    {
        return;
    }
    NSDictionary *_attachs = [self setMediaAttachConfigsWithTitle:_title
                                                         subtitle:_subtitle
                                                      description:_description
                                                         titleURL:_titleURL
                                                     mediaConfigs:(NSDictionary *)[self setConfigsOfImagesUrlObjects:_photoURLs
                                                                                                      andHrefObjects:_photoTurnURLs]];
    
    
    NSDictionary *_configs = [self _getPublishParamsWithBottomTitle:_bottomTitle titleURL:_bottomTitleURL];
    [self publishWithMediaAttachs:_attachs
                          configs:_configs
                          message:_bottomMessage
                     errorHandler:_errorHandler
                completionHandler:_completionHandler];
}

/*
 * @ Publish Media Feed on the news feed wall. 發表影音文章
 *
 * @ Params :
 *
 *   - _videoURL          : 設定影片的 URL
 *   - _viewoThumbnailURL : 影片縮圖 Src
 *   - _thumbnailSize     : 未播放時呈現的影片縮圖寬高
 *   - _playSize          : 播放時呈現的影片寬高
 *   - _title             : 影音留言的大標題
 *   - _subtitle          : 副標題
 *   - _description       : 說明內容
 *   - _titleURL          : 大標題的超連結
 *   - _bottomTitle       : 留言最下面的迷你小標題
 *   - _bottomTitleURL    : 點選迷你小標題時，要導向的網址
 *   - _bottomMessage     : 設定 MiniMessage 參數，會出現在大標題底下的那一空白區塊
 */
-(void)publishNewsFeedWithVideoURL:(NSString *)_videoURL
                 viewoThumbnailURL:(NSString *)_viewoThumbnailURL
                     thumbnailSize:(CGSize)_thumbnailSize
                          playSize:(CGSize)_playSize
                             title:(NSString *)_title
                          subtitle:(NSString *)_subtitle
                       description:(NSString *)_description
                          titleURL:(NSString *)_titleURL
                       bottomTitle:(NSString *)_bottomTitle
                    bottomTitleURL:(NSString *)_bottomTitleURL
                     bottomMessage:(NSString *)_bottomMessage
                      errorHandler:(KRFacebookErrorHandler)_errorHandler
                 completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    if( !self.fbSession )
    {
        return;
    }
    NSString *_thumbnailWidth  = [NSString stringWithFormat:@"%i", (int)_thumbnailSize.width];
    NSString *_thumbnailHeight = [NSString stringWithFormat:@"%i", (int)_thumbnailSize.height];
    NSString *_playWidth       = [NSString stringWithFormat:@"%i", (int)_playSize.width];
    NSString *_playHeight      = [NSString stringWithFormat:@"%i", (int)_playSize.height];
    NSDictionary *_attachs = [self setMediaAttachConfigsWithTitle:_title
                                                         subtitle:_subtitle
                                                      description:_description
                                                         titleURL:_titleURL
                                                     mediaConfigs:[self setConfigsOfVideoUrl:_videoURL
                                                                                 andImageSrc:_viewoThumbnailURL
                                                                               andImageWidth:_thumbnailWidth
                                                                              andImageHeight:_thumbnailHeight
                                                                                andPlayWidth:_playWidth
                                                                               andPlayHeight:_playHeight]];
    
    
    NSDictionary *_configs = [self _getPublishParamsWithBottomTitle:_bottomTitle titleURL:_bottomTitleURL];
    [self publishWithMediaAttachs:_attachs
                          configs:_configs
                          message:_bottomMessage
                     errorHandler:_errorHandler
                completionHandler:_completionHandler];
}

-(void)publishNewsFeedWithYoutubeVideoId:(NSString *)_youtubeVideoId
                       viewoThumbnailURL:(NSString *)_viewoThumbnailURL
                           thumbnailSize:(CGSize)_thumbnailSize
                                playSize:(CGSize)_playSize
                                   title:(NSString *)_title
                                subtitle:(NSString *)_subtitle
                             description:(NSString *)_description
                                titleURL:(NSString *)_titleURL
                             bottomTitle:(NSString *)_bottomTitle
                          bottomTitleURL:(NSString *)_bottomTitleURL
                           bottomMessage:(NSString *)_bottomMessage
                            errorHandler:(KRFacebookErrorHandler)_errorHandler
                       completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    if( !self.fbSession )
    {
        return;
    }
    //https://youtube.googleapis.com/v/Q9uTyjJQ0VU
    NSString *_videoURL        = [NSString stringWithFormat:@"https://youtube.googleapis.com/v/%@", _youtubeVideoId];
    NSString *_thumbnailWidth  = [NSString stringWithFormat:@"%i", (int)_thumbnailSize.width];
    NSString *_thumbnailHeight = [NSString stringWithFormat:@"%i", (int)_thumbnailSize.height];
    NSString *_playWidth       = [NSString stringWithFormat:@"%i", (int)_playSize.width];
    NSString *_playHeight      = [NSString stringWithFormat:@"%i", (int)_playSize.height];
    NSDictionary *_attachs = [self setMediaAttachConfigsWithTitle:_title
                                                         subtitle:_subtitle
                                                      description:_description
                                                         titleURL:_titleURL
                                                     mediaConfigs:[self setConfigsOfVideoUrl:_videoURL
                                                                                 andImageSrc:_viewoThumbnailURL
                                                                               andImageWidth:_thumbnailWidth
                                                                              andImageHeight:_thumbnailHeight
                                                                                andPlayWidth:_playWidth
                                                                               andPlayHeight:_playHeight]];
    
    
    NSDictionary *_configs = [self _getPublishParamsWithBottomTitle:_bottomTitle titleURL:_bottomTitleURL];
    [self publishWithMediaAttachs:_attachs
                          configs:_configs
                          message:_bottomMessage
                     errorHandler:_errorHandler
                completionHandler:_completionHandler];
}

#pragma Uploading Photos
-(void)uploadPhotoHttpURL:(NSURL *)_photoURL
              description:(NSString *)_description
             errorHandler:(KRFacebookErrorHandler)_errorHandler
        completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    //Use REST API.
    [self _judgeFBSessionStatus];
    NSDictionary *_params = [self _getUploadParamsWithPhotoHttpURL:_photoURL description:_description];
    if( !_params )
    {
        return;
    }
    FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                    restMethod:@"photos.upload"
                                                    parameters:_params
                                                    HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error){
        if( error )
        {
            if( _errorHandler )
            {
                _errorHandler(error);
            }
        }
        if( _completionHandler )
        {
            _completionHandler( !(error) , result);
        }
    }];
}

-(void)uploadPhotoLocalPath:(NSString *)_photoPath
                description:(NSString *)_description
               errorHandler:(KRFacebookErrorHandler)_errorHandler
          completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    //Use REST API.
    [self _judgeFBSessionStatus];
    NSDictionary *_params = [self _getUploadParamsWithPhotoLocalPath:_photoPath description:_description];
    if( !_params )
    {
        return;
    }
    FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                    restMethod:@"photos.upload"
                                                    parameters:_params
                                                    HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error){
        if( error )
        {
            if( _errorHandler )
            {
                _errorHandler(error);
            }
        }
        if( _completionHandler )
        {
            _completionHandler( !(error) , result);
        }
    }];
}

-(void)uploadImage:(UIImage *)_image description:(NSString *)_description errorHandler:(KRFacebookErrorHandler)_errorHandler
     completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    if( !_image )
    {
        return;
    }
    [self _judgeFBSessionStatus];
	NSDictionary *_params = [NSDictionary dictionaryWithObjectsAndKeys:
                            _image,       @"picture",
                            _description, @"caption",
                            nil];
    FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                    restMethod:@"photos.upload"
                                                    parameters:_params
                                                    HTTPMethod:@"POST"];
    [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if( error )
        {
            if( _errorHandler )
            {
                _errorHandler(error);
            }
        }
        if( _completionHandler )
        {
            _completionHandler( !(error) , result);
        }
    }];
}

#pragma --mark Uploading Video Methods
-(void)uploadVideoLocalPath:(NSString *)_videoPath
                      title:(NSString *)_title
                description:(NSString *)_description
               errorHandler:(KRFacebookErrorHandler)_errorHandler
          completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    //Use Graph API
    [self _judgeFBSessionStatus];
    if( self.fbSession )
    {
        NSDictionary *_params = [self _getUploadParamsWithVideoLocalPath:_videoPath title:_title description:_description];
        if( _params )
        {
            FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                             graphPath:@"me/videos"
                                                            parameters:_params
                                                            HTTPMethod:@"POST"];
            [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
            {
                if( error )
                {
                    if( _errorHandler )
                    {
                        _errorHandler(error);
                    }
                }
                if( _completionHandler )
                {
                    _completionHandler( !(error) , result);
                }
             }];
        }
        else
        {
            if( _errorHandler )
            {
                _errorHandler( [self _errorWithNoParams] );
            }
        }
    }
}

-(void)getUploadVideoLimitSizeWithCompletion:(KRFacebookCompletionHandler)_completionHandler
{
    [self _judgeFBSessionStatus];
    if( self.fbSession )
    {
        FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:self.fbSession
                                                        restMethod:@"video.getUploadLimits"
                                                        parameters:nil
                                                        HTTPMethod:@"POST"];
        [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
        {
            if( _completionHandler )
            {
                _completionHandler( !(error), result );
            }
        }];
    }
}

#pragma --mark GraphAPI Calls
-(void)requestGraphApiPath:(NSString *)_graphPath completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    if( self.fbSession )
    {
        FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:_fbSession graphPath:_graphPath];
        [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
         {
             if( _completionHandler )
             {
                 _completionHandler( !(error), result );
             }
         }];
    }
}

-(void)requestGraphApiPath:(NSString *)_graphPath parameters:(NSDictionary *)_parameters httpMethod:(KRFacebookHttpMethods)_httpMethod completionHandler:(KRFacebookCompletionHandler)_completionHandler
{
    if( self.fbSession )
    {
        FBRequest *_fbRequest = [[FBRequest alloc] initWithSession:_fbSession
                                                         graphPath:_graphPath
                                                        parameters:_parameters
                                                        HTTPMethod:[self _convertHttpMethod:_httpMethod]];
        [_fbRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
        {
            if( _completionHandler )
            {
                _completionHandler( !(error), result );
            }
        }];
    }
}

@end
