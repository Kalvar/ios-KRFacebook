//
//  ExtFacebook.m
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 12/6/11.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import "ExtFacebook.h"

@interface ExtFacebook (){
    Facebook *facebook;
}

@property (readonly) Facebook *facebook;
//回傳的資料是否為字串型態
@property (nonatomic, assign) BOOL isString;

@end

@interface ExtFacebook (fixPrivate)

-(void)_initWithCommonVars:(NSString *)_devKeys 
               andDelegate:(id<ExtFacebookDelegate>)_delegate;

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

@end

@implementation ExtFacebook (fixPrivate)

/*
 * @重要參數說明 : 
 *   self.saveUser     = 登入後，儲存指定的使用者資訊
 *   self.devKey       = Facebook App 的 Developer Key
 *   self.fbPermissons = 登入後，要向 FB 請求的資料項目
 *   self.executing    = 當前在執行的動作
 */
-(void)_initWithCommonVars:(NSString *)_devKeys 
               andDelegate:(id<ExtFacebookDelegate>)_delegate{
    self.saveUser     = NO;
    self.delegate     = _delegate;
    self.devKey       = _devKeys;     
    self.fbPermissons = [NSArray arrayWithObjects:
                         @"read_stream", 
                         @"publish_stream", 
                         @"offline_access", 
                         @"email",
                         @"user_photos",
                         @"friends_photos",
                         nil];     
    self.executing     = [NSString stringWithString:@"init"];
    self.processing    = ExtFacebookProcessForNothing;
    facebook           = [[Facebook alloc] initWithAppId:self.devKey andDelegate:self];
    jsonWriter         = [[SBJSON alloc] init];      
}

/*
 * 儲存 User 的私人資訊在 App 裡
 */
-(void)_savingPrivateInformationOfUserInApp:(NSDictionary *)_responses{
    [[NSUserDefaults standardUserDefaults] setObject:[_responses objectForKey:@"email"] forKey:FB_USER_ACCOUNT_KEY];
    [[NSUserDefaults standardUserDefaults] setObject:[_responses objectForKey:@"id"] forKey:FB_USER_ID_KEY];
    //同步更新儲存的內容
    [[NSUserDefaults standardUserDefaults] synchronize]; 
    //製作儲存的 Dicts
    NSString *savedAccessToken = [[NSString alloc] initWithFormat:@"%@", 
                                  [[NSUserDefaults standardUserDefaults] objectForKey:FB_ACCESS_TOKEN_KEY]];
    NSString *savedExpiratDate = [[NSString alloc] initWithFormat:@"%@", 
                                  [[NSUserDefaults standardUserDefaults] objectForKey:FB_EXPIRATION_DATE_KEY]];
    NSString *savedUserAccount = [[NSString alloc] initWithFormat:@"%@", 
                                  [[NSUserDefaults standardUserDefaults] objectForKey:FB_USER_ACCOUNT_KEY]];
    NSString *savedUserId      = [[NSString alloc] initWithFormat:@"%@", 
                                  [[NSUserDefaults standardUserDefaults] objectForKey:FB_USER_ID_KEY]];
    
    NSDictionary *savedDatas   = [NSDictionary dictionaryWithObjectsAndKeys:
                                  savedAccessToken, FB_ACCESS_TOKEN_KEY, 
                                  savedExpiratDate, FB_EXPIRATION_DATE_KEY, 
                                  savedUserAccount, FB_USER_ACCOUNT_KEY,
                                  savedUserId, FB_USER_ID_KEY, 
                                  nil];
    
    [savedAccessToken release];
    [savedExpiratDate release];
    [savedUserAccount release];
    [savedUserId release];
    
    if( [self.delegate respondsToSelector:@selector(extFacebook:didSavedUserPrivations:)] ){
        [self.delegate extFacebook:self didSavedUserPrivations:savedDatas];
    }
    
}

/*
 * @上傳 : 
 *   取得上傳圖片所使用的參數(Params)
 */
-(NSDictionary *)_setupParamsWithUploadImageUrl:(id)_imageUrl 
                               imageDescription:(NSString *)_description{
    //NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
    NSData *imageData;
    //是 NSURL 格式
    if( [_imageUrl isKindOfClass:[NSURL class]] ){
        imageData = [NSData dataWithContentsOfURL:(NSURL *)_imageUrl];
    }else{
        //是 NSString 格式
        imageData = [NSData dataWithContentsOfFile:(NSString *)_imageUrl];
    }
    UIImage *image    = [[UIImage alloc] initWithData:imageData];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   image, @"picture",
                                   _description, @"caption",
								   nil];
    [image release];
    return params;
}

/*
 * @上傳 : 
 *   取得上傳影音所使用的參數(Params)
 */
-(NSDictionary *)_setupParamsWithUploadMediaUrl:(id)mediaUrl 
                                       andTitle:(NSString *)mediaTitle 
                                 andDescription:(NSString *)mediaDesc{
    
    NSData *mediaData;
    
    //NSURL 格式
    if( [mediaUrl isKindOfClass:[NSURL class]] ){
        mediaData = [NSData dataWithContentsOfURL:(NSURL *)mediaUrl];
    }else{
        //NSString 格式
        mediaData = [NSData dataWithContentsOfFile:(NSString *)mediaUrl];
    }
    
    //用 / 切割
    NSArray *urlArray  = [(NSString *)mediaUrl componentsSeparatedByString:@"/"];
    
    //取得檔名 : 並去除字串前後空白
    NSString *fileName = [[urlArray objectAtIndex:(int)( [urlArray count] - 1 )] 
                          stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];  
    
    //取出副檔名
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
                                   andMessage:(NSString *)message{
    
    //將基本迷你標題 Dictionary 陣列製作成 JSON 字串
    NSString *miniWordsJsonString = [jsonWriter stringWithObject:miniWordsConfigs error:nil];
    
    //給合 PO 文參數陣列
    NSMutableDictionary *params   = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     //@"PO 文提示文字", @"user_message_prompt",
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
                                       andMessage:(NSString *)message{
    
    //JSON : 迷你文字標題
    NSString *miniWordsJsonString   = [jsonWriter stringWithObject:miniWordsConfigs];
    //JSON : 多媒體留言附件
    NSString *mediaAttachJsonString = [jsonWriter stringWithObject:mediaAttachConfigs];
    //給合 PO 文參數陣列
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
                              andMiniHref:(NSString *)miniHref{
    
    //留言迷你標題( 按讚旁邊的小文字 )，迷你標題的超連結
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
    self.executing  = @"uploadMedia"; 
    self.processing = ExtFacebookProcessForUploadMedia;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:_mediaConfigs];
    [facebook requestWithGraphPath:@"me/videos"
                         andParams:params 
                     andHttpMethod:@"POST"
                       andDelegate:self];     
    
}

@end

@implementation ExtFacebook

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

#pragma Construct
-(ExtFacebook *)initWithDelegate:(id<ExtFacebookDelegate>)_sdkDelegate{
    self = [super init];
    if( self ){
        [self _initWithCommonVars:FB_DEVELOPER_KEY andDelegate:_sdkDelegate];
    }
    return self;
}

-(ExtFacebook *)initWithDevKey:(NSString *)_devKey delegate:(id<ExtFacebookDelegate>)_sdkDelegate{
    self = [super init];
    if( self ){       
        NSString *_tempDevKeys = ( [_devKey length] > 0 )? _devKey : FB_DEVELOPER_KEY;
        [self _initWithCommonVars:_tempDevKeys andDelegate:_sdkDelegate];
    }
    return self;
}

-(void)dealloc{
    [jsonWriter release];
    [facebook release];
    [devKey release];
    [executing release];
    [fbPermissons release];
    
    [super dealloc];
}

#pragma Settup Attach Configs
//[附件設定] : 影片
-(NSDictionary *)setConfigsOfVideoUrl:(NSString *)videoSrc 
                          andImageSrc:(NSString *)imageSrc 
                        andImageWidth:(NSString *)imageWidth 
                       andImageHeight:(NSString *)imageHeight 
                         andPlayWidth:(NSString *)expandedWidth 
                        andPlayHeight:(NSString *)expandedHeight{
    
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

//[附件設定] : 單張圖片
-(NSDictionary *)setConfigsOfImageUrl:(NSString *)imageSrc 
                              andHref:(NSString *)imageHref{
    
    NSDictionary *mediaConfigs = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"image", @"type",
                                                            imageSrc, @"src",
                                                            imageHref, @"href",
                                                            nil], nil];    
    return mediaConfigs;
    
}

//[附件設定] : 多張圖片
-(NSDictionary *)setConfigsOfImagesUrlObjects:(NSArray *)imageSrcArray 
                               andHrefObjects:(NSArray *)imageHrefArray{
    //暫存陣列
    NSMutableArray *tempMediaConfigs = [[NSMutableArray alloc] initWithCapacity:0];
    for( id key in imageSrcArray ){
        //加入至暫存陣列
        [tempMediaConfigs insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                        @"image", @"type",
                                        [imageSrcArray objectAtIndex:[key intValue]], @"src",
                                        [imageHrefArray objectAtIndex:[key intValue]], @"href", 
                                        nil] 
                               atIndex:[key intValue]];
        //[mediaConfigs addEntriesFromDictionary:tempMediaConfigs];
    }
    
    //將暫存陣列寫入至辭典陣列裡
    NSDictionary *mediaConfigs = [NSArray arrayWithObject:tempMediaConfigs];
    [tempMediaConfigs release];
    //回傳
    return mediaConfigs;
}

//[附件設定] : 音樂
-(NSDictionary *)setConfigsOfMusicUrl:(NSString *)musicSrc 
                             andTitle:(NSString *)songName 
                            andSinger:(NSString *)singerName 
                             andAlbum:(NSString *)albumName{
    
    NSDictionary *mediaConfigs = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"music", @"type",
                                                            musicSrc, @"src",
                                                            songName, @"title",
                                                            singerName, @"artist", 
                                                            albumName, @"album", 
                                                            nil], nil];
    return mediaConfigs;
    
}

//[多媒體留言附件設定] 
-(NSDictionary *)setMediaAttachConfigsWithTitle:(NSString *)title 
                                    andSubtitle:(NSString *)subtitle 
                                 andDescription:(NSString *)description 
                                   andTitleHref:(NSString *)titleHref 
                                andMediaConfigs:(NSDictionary *)mediaConfigs{
    
    
    //[留言附件] : name(名字) / caption(子標題), description(說明內容), href(連結網址), media(多媒體) flash / image / music
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
                        andMessage:(NSString *)_message{ 
    
    //將基本迷你標題 Dictionary 陣列製作成 JSON 字串
    NSString *miniWordsJsonString = [jsonWriter stringWithObject:[self _setupConfigsOfMiniTitle:_title andMiniHref:_titleHref]  
                                                           error:nil];
    //給合 PO 文參數陣列
    NSMutableDictionary *params   = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     //@"PO 文提示文字", @"user_message_prompt",
                                     miniWordsJsonString, @"action_links", 
                                     _message, @"message",
                                     nil];    
    self.executing  = @"postWordsFeed";
    self.processing = ExtFacebookProcessForPublishOnFeeds;
    //使用 REST API : stream.publish 方法發送至塗鴉牆
    [facebook requestWithMethodName:@"stream.publish" 
                          andParams:params 
                      andHttpMethod:@"POST" 
                        andDelegate:self];
}

/*
 * @Post 影音留言的正確流程 : 
 *  1). 使用 [self setConfigsOfVideoUrl::::::] 設定影片的 URL、影片縮圖 Src、未播放時呈現的影片縮圖寬高、播放時呈現的影片寬高 ; 回傳字典陣列
 *  2). 使用 [self _setupConfigsOfMiniTitle::] 設定留言最下面的迷你小標題與點小標題時要導向的超連結 ; 回傳字典陣列
 *  3). 使用 [self setMediaAttachConfigsWithTitle:::::] 設定影音留言的大標題、副標題、大標題的超連結、說明以及第 1 點設定的參數陣列
 *  4). 設定 message 參數，會出現在大標題底下的那一空白區塊
 *  5). 使用 [self publishOnMediaConfigs:::] 將上述的參數都放入即可發佈留言
 *
 * @Post 圖片留言的正確流程 : 
 *  1). 使用 [self setConfigsOfImageUrl::] 設定圖片的 Src、點圖片時要導向的超連結 ; 回傳字典陣列
 *  2). 使用 [self _setupConfigsOfMiniTitle::] 設定留言最下面的迷你小標題與點小標題時要導向的超連結 ; 回傳字典陣列
 *  3). 使用 [self setMediaAttachConfigsWithTitle:::::] 設定圖片留言的大標題、副標題、大標題的超連結、說明以及第 1 點設定的參數陣列
 *  4). 設定 message 參數，會出現在大標題底下的那一空白區塊 
 *  5). 使用 [self publishOnMediaConfigs:::] 將上述的參數都放入即可發佈留言
 *
 */
//[多媒體留言] : 文字 + Youtube Flash 影片 / 圖片 / 音樂
-(void)publishOnMediaConfigs:(NSDictionary *)mediaAttachConfigs 
         andMiniWordsConfigs:(NSDictionary *)miniWordsConfigs 
                  andMessage:(NSString *)message{
    
    //JSON : 迷你文字標題
    NSString *miniWordsJsonString   = [jsonWriter stringWithObject:miniWordsConfigs];
    //JSON : 多媒體留言附件
    NSString *mediaAttachJsonString = [jsonWriter stringWithObject:mediaAttachConfigs];
    //給合 PO 文參數陣列
    NSMutableDictionary *params     = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       miniWordsJsonString, @"action_links", 
                                       mediaAttachJsonString, @"attachment",
                                       message, @"message",
                                       nil];
    
    self.executing  = @"postMediaFeed";
    self.processing = ExtFacebookProcessForPublishOnMedia;
    //使用 REST API : stream.publish 方法發送至塗鴉牆
    [facebook requestWithMethodName:@"stream.publish" 
                          andParams:params 
                      andHttpMethod:@"POST" 
                        andDelegate:self];    
    
    /*
     * 使用 FB PO 文小視窗 ( dialogs ) 寫文字 PO 文分享
     */
    //[Fb dialog:@"feed" andParams:params andDelegate:self];    
    
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
                   andImageHref:(NSString *)_imageHref 
                   andTitle:(NSString *)_title 
                    andSubtitle:(NSString *)_subtitle 
                 andDescription:(NSString *)_description 
                   andTitleHref:(NSString *)_titleHref
                   andMiniTitle:(NSString *)_miniTitle
               andMiniTitleHref:(NSString *)_miniTitleHref
                 andMiniMessage:(NSString *)_miniMessage{
    
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
 *   NSArray *imagesSrcArray  = [NSArray arrayWithObjects:@"http://www.flashaim.tv/images/poster/fb_poster.png", 
 *                                                        @"http://www.flashaim.tv/images/poster/flashaim_about_poster.png", 
 *                                                        nil];
 *   //點選圖片時，要導向的 URL
 *   NSArray *imagesHrefArray = [NSArray arrayWithObjects:@"http://www.flashaim.tv/?menu=fb", 
 *                                                        @"http://www.flashaim.tv/?menu=flashaim_about", 
 *                                                         nil]; 
 */
-(void)publishFeedsWithImageSrcArray:(NSArray *)_imageSrcArray 
                   andImageHrefArray:(NSArray *)_imageHrefArray 
                            andTitle:(NSString *)_title 
                         andSubtitle:(NSString *)_subtitle 
                      andDescription:(NSString *)_description 
                        andTitleHref:(NSString *)_titleHref
                        andMiniTitle:(NSString *)_miniTitle
                    andMiniTitleHref:(NSString *)_miniTitleHref
                      andMiniMessage:(NSString *)_miniMessage{
    //設定多張圖片附件
    NSDictionary *miniWordsArray    = [self _setupConfigsOfMiniTitle:_miniTitle 
                                                         andMiniHref:_miniTitleHref];
    NSDictionary *mediaMessageArray = [self setMediaAttachConfigsWithTitle:_title 
                                                               andSubtitle:_subtitle
                                                            andDescription:_description
                                                              andTitleHref:_titleHref
                                                           andMediaConfigs:[self setConfigsOfImagesUrlObjects:_imageSrcArray 
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
                    andImageSrc:(NSString *)_imageSrc
                  andImageWidth:(NSString *)_imageWidth
                 andImageHeight:(NSString *)_imageHeight
                   andPlayWidth:(NSString *)_playWidth
                  andPlayHeight:(NSString *)_playHeight
                       andTitle:(NSString *)_title 
                    andSubtitle:(NSString *)_subtitle 
                 andDescription:(NSString *)_description 
                   andTitleHref:(NSString *)_titleHref
                   andMiniTitle:(NSString *)_miniTitle
               andMiniTitleHref:(NSString *)_miniTitleHref
                 andMiniMessage:(NSString *)_miniMessage{
    
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
    self.executing  = @"uploadPhotos";    
    self.processing = ExtFacebookProcessForUploadPhoto;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self _setupParamsWithUploadImageUrl:_imageUrl 
                                                                                                    imageDescription:_description]];
    [facebook requestWithMethodName:@"photos.upload"
                          andParams:params
                      andHttpMethod:@"POST"
                        andDelegate:self];    
}

/*
 * @上傳單張圖片
 *   _imageUrl    : 直接傳入圖片檔上傳
 *   _description : 圖片敍述，可用 \n 斷行
 */
-(void)uploadWithImage:(UIImage *)_image 
        andDescription:(NSString *)_description{
    self.executing  = @"uploadPhotos"; 
    self.processing = ExtFacebookProcessForUploadPhoto;
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   _image, @"picture",
                                   _description, @"caption",
								   nil];
    [facebook requestWithMethodName:@"photos.upload"
                          andParams:params
                      andHttpMethod:@"POST"
                        andDelegate:self]; 
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
    self.executing  = @"getVideoUploadLimit";
    self.processing = ExtFacebookProcessForGetVideoUploadLimit;
    [facebook requestWithMethodName:@"video.getUploadLimits" 
                          andParams:nil 
                      andHttpMethod:@"POST" 
                        andDelegate:self];
}

#pragma Extra Methods
/*
 * @取得個人資訊
 *
 * @參數 _kindOf : 
 *
 *   傳入 photos      : 委派判斷 getUserPhotos      :: 取得使用者相片
 *   傳入 permissions : 委派判斷 getUserPermissions :: 取得認證類型資訊    
 *   傳入 feed        : 委派判斷 getUserFeed        :: 取得塗鴉牆資訊    
 *   傳入 friends     : 委派判斷 getUserFriends     :: 取得朋友群資訊    
 *   傳入 albums      : 委派判斷 getUserAlbums      :: 取得相簿資訊     
 *   傳入 me          : 委派判斷 getUserInfos       :: 取得個人資訊 
 *   傳入 groups      : 委派判斷 getUserGroups      :: 取得個人粉絲團
 *   傳入 uploads     : 委派判斷 getUserUploads     :: 取得個人上傳過的影音資料
 *   傳入 home        : 委派判斷 getUserHomes       :: 取得個人首頁最新的塗鴉留言
 *   傳入 likes       : 委派判斷 getUserLinks       :: 取得個人按過讚的粉絲團( 加入過的 )
 *   傳入 events      : 委派判斷 getUserEvents      :: 取得個人正在進行的活動事件
 */
-(void)getUserInfoWithKindOf:(NSString *)_kindOf{
    //請求的 Graph API 方法
    if( [_kindOf isEqualToString:@"photos"] ){
        self.executing  = @"getUserPhotos";
        self.processing = ExtFacebookProcessForGetUserPhotos;
        //取得使用者相片
        [facebook requestWithGraphPath:@"me/photos" andDelegate:self];
    }else if( [_kindOf isEqualToString:@"permissions"] ){
        self.executing  = @"getUserPermissions";
        self.processing = ExtFacebookProcessForGetUserPermissions;
        //取得認證類型資訊 
        [facebook requestWithGraphPath:@"me/permissions" andDelegate:self];
    }else if( [_kindOf isEqualToString:@"feed"] ){
        self.executing  = @"getUserFeed";
        self.processing = ExtFacebookProcessForGetUserFeeds;
        //取得塗鴉牆資訊
        [facebook requestWithGraphPath:@"me/feed" andDelegate:self];    
    }else if( [_kindOf isEqualToString:@"friends"] ){
        self.executing  = @"getUserFriends";
        self.processing = ExtFacebookProcessForGetUserFriends;
        //取得朋友群資訊
        [facebook requestWithGraphPath:@"me/friends" andDelegate:self];
    }else if( [_kindOf isEqualToString:@"albums"] ){
        self.executing  = @"getUserAlbums";
        self.processing = ExtFacebookProcessForGetUserAlbums;
        //取得相簿資訊
        [facebook requestWithGraphPath:@"me/albums" andDelegate:self];
    }else if( [_kindOf isEqualToString:@"uploads"] ){
        self.executing  = @"getUserUploads";
        self.processing = ExtFacebookProcessForGetUserUploads;
        //取得個人上傳過的影音資料
        [facebook requestWithGraphPath:@"me/videos/uploaded" andDelegate:self];
    }else{
        self.executing  = @"getUserInfos";
        self.processing = ExtFacebookProcessForGetUserInfo;
        //取得個人資訊
        [facebook requestWithGraphPath:@"me" andDelegate:self];
    }
    
}

/*
 * @儲存離線 Access Token 值 ( 以便後續自動登入 )
 *   _saveOrClear = YES ; 儲存記錄
 *   _saveOrClear = NO  ; 刪除記錄
 */
-(void)saveAccessToken:(BOOL)_saveOrClear{
    //執行儲存
    if( _saveOrClear ){
        //登入後儲存 Access Token ( 認證值 ; 記得要在請求項目裡加上 offline_access 請求離線認證值 )
        [[NSUserDefaults standardUserDefaults] setObject:facebook.accessToken forKey:FB_ACCESS_TOKEN_KEY];
        //儲存 Expiration Date ( 期限 ; 時效至 4001/1/1 )
        [[NSUserDefaults standardUserDefaults] setObject:facebook.expirationDate forKey:FB_EXPIRATION_DATE_KEY];
        //儲存 User 資訊
        [self saveUserInfos:YES];
    }else{
        //是刪除
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FB_ACCESS_TOKEN_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FB_EXPIRATION_DATE_KEY];  
        [self saveUserInfos:NO];
    }
    //同步更新儲存的內容
    [[NSUserDefaults standardUserDefaults] synchronize]; 
}


/*
 * 儲存 User 資訊 ( 以便後續進行 User 資料處理 )
 */
-(void)saveUserInfos:(BOOL)_saveOrClear{
    if( _saveOrClear ){
        //取得 User 資訊
        self.saveUser = YES;
        [self getUserInfoWithKindOf:@"me"];
    }else{
        self.saveUser = NO;
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FB_USER_ACCOUNT_KEY];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:FB_USER_ID_KEY];
    }
}

/*
 * @登入
 *   permissions : 請求認證項目 ( Class 物件 ; 該物件的觸發方法 )
 * 
 * @附註
 *   如果沒有連網路，會無法出現 Facebook 的登入畫面
 */
-(void)loginWithPermissions:(NSArray *)permissions{
    //讀出之前儲存的 Access Token / Expiration Date ( 時效至 4001/1/1 )
    self.isLogged = [self alreadyLogged];
    //把之前存的 Access Token 跟 Expiration Date 給 facebook 認證 : 如果證認失敗
    if( !isLogged ){
        //設定認證請求項目
        if( [permissions count] > 0 ){
            self.fbPermissons = permissions;
        }        
        //重新請求使用者登入
        [facebook authorize:self.fbPermissons]; 
    }else{
        //認證成功 : 直接導到登入成功函式
        [self fbDidLogin];
    }
}

/*
 * @直接使用預設的 Permissions 項目登入
 */
-(void)login{
    [self loginWithPermissions:nil];
}

/*
 * 執行登出
 */
-(void)logout{
    [facebook logout:self];
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
    //轉小寫 lowercaseString :: 轉大寫 uppercaseString
    NSString *fileExt = [_fileExt lowercaseString];
    //副檔名字典陣列
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
    //? 有找到相對應的 KEY : 回傳萬用 MIME Content-Type
    return ( [[extDicts objectForKey:fileExt] length] > 0 ) ? [extDicts objectForKey:fileExt] : @"application/octet-stream";        
    
}

/*
 * @是否已登入
 *  如直接先執行這裡，則會將原先儲存的 FB TOKEN 值取出來認證
 */
-(BOOL)alreadyLogged{
    facebook.accessToken    = [[NSUserDefaults standardUserDefaults] objectForKey:FB_ACCESS_TOKEN_KEY];
    facebook.expirationDate = [[NSUserDefaults standardUserDefaults] objectForKey:FB_EXPIRATION_DATE_KEY];
    return [facebook isSessionValid];
}

/*
 * 清除已儲存的 FB 個人資訊
 */
-(void)clearSavedDatas{
    [self saveAccessToken:NO];
}

#pragma FacebookDelegate
/*
 * 成功登入
 */
-(void)fbDidLogin{
    if( [facebook isSessionValid] ){
        self.isLogged = YES;
        //儲存 Offline Access Token
        [self saveAccessToken:YES];
    }else{
        self.isLogged = NO;
    }
    
    self.executing  = @"login";
    self.processing = self.isLogged ? ExtFacebookProcessForLogin : ExtFacebookProcessForLoginFailed;  
    
    if( [self.delegate respondsToSelector:@selector(extFacebook:didLogin:)] ){
        [self.delegate extFacebook:self didLogin:self.isLogged];    
    }
    
}

/*
 * 取消登入
 */
-(void)fbDidNotLogin:(BOOL)cancelled{
    self.isLogged  = NO;
    self.executing = @"cancel";
    self.processing = ExtFacebookProcessForCancell;
    if( [self.delegate respondsToSelector:@selector(extFacebook:didCancelLogin:)] ){
        [self.delegate extFacebook:self didCancelLogin:cancelled];
    }
}

/*
 * 登出
 */
-(void)fbDidLogout{
    self.isLogged   = NO;
    self.executing  = @"logout";
    self.processing = ExtFacebookProcessForLogout;
    //清除儲存的 Access Token 值
    [self saveAccessToken:NO];
    //觸發自訂義的 Delegate
    if( [self.delegate respondsToSelector:@selector(extFacebook:didLogout:)] ){
        [self.delegate extFacebook:self didLogout:YES];
    }
}

#pragma FBRequestDelegate + FBSessionDelegate
/*
 * 送出方法請求至 Facebook 官方
 */
-(void)requestLoading:(FBRequest *)request{
    //NSLog(@"Facebook goes requesting : %@", self.executing);
}

/*
 * 送出方法請求後的回應接收
 */
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
    //資料一律會送到下方的函式( request:didLoad: )
	//NSLog(@"Facebook Response : %@ \n", response);
}

/*
 * @回應接收完畢，進行解析作業
 *   Facebook 針對 Request 並不一定會回傳 Array，有時也會視 API 方法回傳字串，
 *   故，故這裡才有「萬用型態」( 不論是字串或陣列的回傳值，都一定會執行該方法 )，
 *   而陣列就會傳到字典陣列型態的方法裡，字串則會再另傳入字串型態方法裡。
 */
-(void)request:(FBRequest *)request didLoad:(id)result{
    //是否為 NSArray 物件型態
	if ( [result isKindOfClass:[NSArray class]] ) {        
		result = [result objectAtIndex:0];
	}
    
    if( [result isKindOfClass:[NSData class]] ){
        //會被轉成 NSCFString 格式
        NSString *_tempResult = [[NSString alloc] initWithData:(NSData *)result encoding:NSUTF8StringEncoding];
        result = [NSString stringWithString:_tempResult];
        [_tempResult release];
    }
    
    //回傳為字串 ? FB 預設為解析成 Dictionary 回傳到這裡 
    self.isString = [result isKindOfClass:[NSString class]] ? YES : NO;
    
    //萬用型態
    if( [self.delegate respondsToSelector:@selector(extFacebook:didLoadWithResponses:andKindOf:)] ){
        [self.delegate extFacebook:self didLoadWithResponses:result andKindOf:self.executing];
    }
    
    //是字串型態 && 對象物件有存在字串委派
    if( self.isString && [self.delegate respondsToSelector:@selector(extFacebook:didLoadWithResponseOfString:andKindOf:)] ){
        [self.delegate extFacebook:self didLoadWithResponseOfString:result andKindOf:self.executing];
    }else{
        //儲存 User 資訊
        if( self.saveUser ){
            self.saveUser = NO;
            [self _savingPrivateInformationOfUserInApp:result];
        }
        //是字典陣列型態 && 有存在陣列委派
        if( [result isKindOfClass:[NSDictionary class]] &&
            [self.delegate respondsToSelector:@selector(extFacebook:didLoadWithResponsesOfDictionary:andKindOf:)]){
            [self.delegate extFacebook:self didLoadWithResponsesOfDictionary:result andKindOf:self.executing];
        }
    }
    
}

/*
 * @送出方法請求失敗
 *   在地化說明 : [error localizedDescription]
 *   原文說明   : [error description]
 *   使用者資訊 : [error userInfo]
 *   
 */
-(void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    if( [self.delegate respondsToSelector:@selector(extFacebook:didFailWithResponses:andKindOf:)] ){
        [self.delegate extFacebook:self didFailWithResponses:error andKindOf:self.executing];
    }
}

/*
 * 使用 Facebook Dialog 進行 Post 文章、其他動作後的完成處理動作
 */
-(void)dialogDidComplete:(FBDialog *)dialog {
	//NSLog(@"Publish Successfully! \n");
}

@end
