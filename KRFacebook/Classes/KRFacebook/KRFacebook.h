//
//  KRFacebook.h
//  V1.2
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 2013/01/20.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

/*
 * 1). Integrated Facebook SDK 3.1 ( that you can change to high version of sdk. )
 * 2). Waiting for integrate Open Graph API
 */

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import "FBSBJSON.h"
#define FACEBOOK_ACCESS_TOKEN_KEY    @"FBAccessToken"
#define FACEBOOK_EXPIRATION_DATE_KEY @"FBExpirationDate"
#define FACEBOOK_USER_ACCOUNT_KEY    @"FBUserAccount"
#define FACEBOOK_USER_ID_KEY         @"FBUserId"
#define FACEBOOK_USER_NAME_KEY       @"FBUserName"
#define FACEBOOK_DEVELOPER_KEY       @"Your Facebook App Developer Key"

/*
 * 當前的執行動作集合
 */
typedef enum _KRFacebookRequests
{
    //Nothing
    KRFacebookRequestNothing = 0,
    //Publish to Feeds
    KRFacebookRequestPublishToFeeds,
    //Publish to Photo Album
    KRFacebookRequestPublishToPhoto,
    //Publish to Media
    KRFacebookRequestPublishToMedia,
    //Login OK
    KRFacebookRequestLogin,
    //Logout OK
    KRFacebookRequestLogout,
    //Login is Cancelled
    KRFacebookRequestCancel,
    //Login is Failed
    KRFacebookRequestLoginFailed,
    //Uploading Photos to Someone's Album
    KRFacebookRequestUploadPhotos,
    //Uploading a Photo to Someone's Album
    KRFacebookRequestUploadPhoto,
    //Uploading a Media ( Video, Music ) to Facebook Walls
    KRFacebookRequestUploadMedia,
    //Gets User's Photos
    KRFacebookRequestGetUserPhotos,
    //Get User Accepted Permissions
    KRFacebookRequestGetUserAcceptedPermissions,
    //Get User Published Feeds
    KRFacebookRequestGetUserFeeds,
    //Get User Friends
    KRFacebookRequestGetUserFriends,
    //Get User Albums
    KRFacebookRequestGetUserAlbums,
    //Get User Uploaded
    KRFacebookRequestGetUserAllUploaded,
    //Get User Personal Info
    KRFacebookRequestGetUserPersonalInfo,
    //Get Video Upload Limit Size
    KRFacebookRequestGetVideoUploadLimitSize
} KRFacebookRequests;

@protocol KRFacebookDelegate;

@class FBSBJSON;
@class Facebook;

@interface KRFacebook : NSObject
{
    id<KRFacebookDelegate> __weak delegate;
    FBSBJSON *jsonWriter;
    NSString *devKey;
    BOOL isLogged;    
    BOOL needSavingUserInfo;
    NSArray *requestPermissons;
    KRFacebookRequests requestAction;
    NSString *requestStatus;
    FBSession *fbSession;
}

@property (nonatomic, weak) id<KRFacebookDelegate> delegate;
@property (nonatomic, strong) FBSBJSON *jsonWriter;
@property (nonatomic, strong) NSString *devKey;
@property (nonatomic, assign) BOOL isLogged;
@property (nonatomic, assign) BOOL needSavingUserInfo;
@property (nonatomic, strong) NSArray *requestPermissons;
@property (nonatomic, assign) KRFacebookRequests requestAction;
@property (nonatomic, strong) NSString *requestStatus;
@property (nonatomic, strong) FBSession *fbSession;

/*
 * initialize
 */
+(KRFacebook *)sharedManager;
-(KRFacebook *)initWithDelegate:(id<KRFacebookDelegate>)_sdkDelegate;
-(KRFacebook *)initWithDevKey:(NSString *)_devKey delegate:(id<KRFacebookDelegate>)_sdkDelegate;
-(KRFacebook *)initWithPermissions:(NSArray *)_permissions delegate:(id<KRFacebookDelegate>)_sdkDelegate;

/*
 * @附件設定
 */
//影片
-(NSDictionary *)setConfigsOfVideoUrl:(NSString *)videoSrc 
                          andImageSrc:(NSString *)imageSrc 
                        andImageWidth:(NSString *)imageWidth 
                       andImageHeight:(NSString *)imageHeight 
                         andPlayWidth:(NSString *)expandedWidth 
                        andPlayHeight:(NSString *)expandedHeight;

//單張圖片 
-(NSDictionary *)setConfigsOfImageUrl:(NSString *)imageSrc 
                              andHref:(NSString *)imageHref;

//多張圖片 :: 陣列( imageSrc / imageHref 需為互相對應的陣列 )
-(NSArray *)setConfigsOfImagesUrlObjects:(NSArray *)imageSrcArray
                               andHrefObjects:(NSArray *)imageHrefArray;

//音樂
-(NSDictionary *)setConfigsOfMusicUrl:(NSString *)musicSrc 
                             andTitle:(NSString *)songName 
                            andSinger:(NSString *)singerName 
                             andAlbum:(NSString *)albumName;

/*
 * 多媒體留言附件設定
 */
//附加 Flash / Image / Music
-(NSDictionary *)setMediaAttachConfigsWithTitle:(NSString *)title 
                                    andSubtitle:(NSString *)subtitle 
                                 andDescription:(NSString *)description 
                                   andTitleHref:(NSString *)titleHref
                                andMediaConfigs:(NSDictionary *)mediaConfigs;

/*
 * @多媒體留言
 *  1). 可 Viedo 留言
 *  2). 可 Photo 留言
 *
 * @參數
 *  mediaAttachConfigs = 多媒體留言附件設定
 *  miniWordsConfigs   = 迷你文字標題留言設定
 *  message            = 主要內文
 */
-(void)publishOnMediaConfigs:(NSDictionary *)mediaAttachConfigs 
         andMiniWordsConfigs:(NSDictionary *)miniWordsConfigs 
                  andMessage:(NSString *)message;

/*
 * @一次性設定並發佈單張圖片留言 : 
 *   1). _miniMessage 會出現在 Title 下面那一區
 *   2). imageJump : 點選圖片後要導向的網址
 */
-(void)publishFeedsWithImageSrc:(NSString *)_imageSrc 
                      imageJump:(NSString *)_imageHref
                          title:(NSString *)_title
                       subtitle:(NSString *)_subtitle
                    description:(NSString *)_description
                      titleHref:(NSString *)_titleHref
                      miniTitle:(NSString *)_miniTitle
                  miniTitleHref:(NSString *)_miniTitleHref
                    miniMessage:(NSString *)_miniMessage;

/*
 * @一次性設定並發佈多張圖片留言
 *   圖片陣列 : _imageSrcArray / _imageHrefArray 需為互相對應的 Key / Value 陣列
 */
-(void)publishFeedsWithImageUrls:(NSArray *)_imageSrcArray
                      imageJumps:(NSArray *)_imageHrefArray
                           title:(NSString *)_title
                        subtitle:(NSString *)_subtitle
                     description:(NSString *)_description
                       titleHref:(NSString *)_titleHref
                       miniTitle:(NSString *)_miniTitle
                   miniTitleHref:(NSString *)_miniTitleHref
                     miniMessage:(NSString *)_miniMessag;

/*
 * 一次性設定並發佈影音留言
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
                    miniMessage:(NSString *)_miniMessage;

/*
 * 發佈純文字留言( Feeds )
 */
-(void)publishOnFeedsWallWithTitle:(NSString *)_title 
                      andTitleHref:(NSString *)_titleHref 
                        andMessage:(NSString *)_message;

/*
 * @上傳圖片 : 
 *   _photoURL    = 圖片的 HTTP NSURL
 *   _photoPath   = 圖片的 Local Path
 *   _description = 圖片說明
 */
-(void)uploadWithPhotoURL:(NSURL *)_photoURL description:(NSString *)_description;
-(void)uploadWithPhotoPath:(NSString *)_photoPath description:(NSString *)_description;
-(void)uploadWithImage:(UIImage *)_image description:(NSString *)_description;

/*
 * @直接上傳影音至塗鴉牆
 *   _filePath    = 影音檔案的 Local File Path
 *   _title       = PO 文的標題
 *   _description = PO 文的內文
 */
-(void)uploadWithMediaPath:(NSString *)_filePath title:(NSString *)_title description:(NSString *)_description;

/*
 * @取得要上傳至 Facebook 的官方限制大小
 */
-(void)getVideoUploadLimitSize;

/*
 * @ 取得檔案的 MIME Type : 傳入副檔名
 */
-(NSString *)getFileMimeTypeWithExt:(NSString *)_fileExt;

/*
 * @ 取得在 Facebook 上播放的影片 URL
 */
-(NSString *)getVideoURLWithId:(NSString *)_videoId;

/*
 * @ 登入 :
 *   - 請求認證項目 ( Class 物件 :: 該物件的觸發方法 )
 */
-(void)loginWithPermissions:(NSArray *)permissions;

/*
 * @ 直接使用預設的 Permissions 項目登入
 */
-(void)login;

/*
 * @ 登出
 */
-(void)logout;

/*
 * @ 取得個人資訊
 */
-(void)getUserInfoWithKindOf:(NSString *)_kindOf;

/*
 * @ 是否已登入 ?
 *   - 如直接先執行這裡，則會將原先儲存的 FB TOKEN 值取出來認證
 */
-(BOOL)alreadyLogged;

/*
 * @ 喚醒 Facebook Session
 */
+(BOOL)awakeSession;
-(BOOL)awakeSession;

/*
 * @ 清除或儲存 FB AccessToken 與個人資訊
 */
-(void)saveAccessToken;
-(void)clearAccessToken;
-(void)savePersonalInfo;
-(void)clearSavedPersonalInfo;
-(void)clearDelegates;

-(NSString *)getSavedAccessToken;

@end


@protocol KRFacebookDelegate <NSObject>

@optional

//Errors
-(void)krFacebook:(KRFacebook *)_krFacebook didLoadWithErrors:(NSError *)errors;
//已儲存 User 的私人資訊
-(void)krFacebook:(KRFacebook *)_krFacebook didSavedUserPrivateInfo:(NSDictionary *)_userInfo;
//成功登入
-(void)krFacebookDidLogin;
//成功登出
-(void)krFacebookDidLogout;
//取消登入
-(void)krFacebookDidCancel;
//登入失敗
-(void)krFacebookDidFailedLogin;
//請求完畢 : 取得 Facebook 回傳的萬用型態
-(void)krFacebookDidLoadWithResponses:(id)_results;
//請求完畢 : 取得 Facebook 回傳的萬用型態
-(void)krFacebook:(KRFacebook *)_krFacebook didLoadWithResponses:(id)_results andKindOf:(NSString *)_perform;
//請求完畢 : 取得 Facebook 回傳的陣列型態值 : andKinfOf 執行什麼動作 ( Ex: get.user.infos )
-(void)krFacebook:(KRFacebook *)_krFacebook didLoadWithDictionaryTypeResponses:(NSDictionary *)_results andKindOf:(NSString *)_perform;
//請求完畢 : 取得 Facebook 回傳的字串型態值 : andKinfOf 執行什麼動作 ( Ex: upload.photos )
-(void)krFacebook:(KRFacebook *)_krFacebook didLoadWithStringTypeResponse:(NSString *)_result andKindOf:(NSString *)_perform;
//請求失敗
-(void)krFacebook:(KRFacebook *)_krFacebook didFailWithResponses:(NSError *)_errors andKindOf:(NSString *)_perform;
//已完成所有請求
-(void)krFacebookDidFinishAllRequests;

@end
