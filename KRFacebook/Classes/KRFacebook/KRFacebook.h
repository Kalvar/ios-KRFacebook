//
//  KRFacebook.h
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 2012/10/20.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

/*
 * 1). 已整合 Facebook SDK 3.0
 * 2). 待整合 Open Graph API
 */

#import <Foundation/Foundation.h>
#import "FBConnect.h"
#import "FBLoginButton.h"

#define FACEBOOK_ACCESS_TOKEN_KEY    @"FBAccessToken"
#define FACEBOOK_EXPIRATION_DATE_KEY @"FBExpirationDate"
#define FACEBOOK_USER_ACCOUNT_KEY    @"FBUserAccount"
#define FACEBOOK_USER_ID_KEY         @"FBUserId"
#define FACEBOOK_USER_NAME_KEY       @"FBUserName"
#define FACEBOOK_DEVELOPER_KEY       @"Your Facebook App Developer Key"

/*
 * 當前的執行動作集合
 */
typedef enum _KRFacebookProcess{
    KRFacebookProcessForNothing = 0,
    KRFacebookProcessForPublishOnFeeds,
    KRFacebookProcessForPublishOnPhoto,
    KRFacebookProcessForPublishOnMedia,
    KRFacebookProcessForLogin,
    KRFacebookProcessForLogout,
    KRFacebookProcessForCancell,
    KRFacebookProcessForLoginFailed,
    KRFacebookProcessForUploadPhotos,
    KRFacebookProcessForUploadPhoto,
    KRFacebookProcessForUploadMedia,
    KRFacebookProcessForGetUserPhotos,
    KRFacebookProcessForGetUserPermissions,
    KRFacebookProcessForGetUserFeeds,
    KRFacebookProcessForGetUserFriends,
    KRFacebookProcessForGetUserAlbums,
    KRFacebookProcessForGetUserUploads,
    KRFacebookProcessForGetUserInfo,
    KRFacebookProcessForGetVideoUploadLimit
    // ... 
} KRFacebookProcess;

@protocol KRFacebookDelegate;
//@class Facebook;
@class FBSBJSON;

@interface KRFacebook : NSObject <FBRequestDelegate, FBDialogDelegate, FBSessionDelegate>{
    id<KRFacebookDelegate> delegate;
    FBSBJSON *jsonWriter;
    NSString *devKey;
    BOOL isLogged;    
    BOOL saveUser;
    NSArray *fbPermissons;   
    int processing;
    NSString *executing;
}

@property (nonatomic, assign) id<KRFacebookDelegate> delegate;
@property (nonatomic, retain) FBSBJSON *jsonWriter;
@property (nonatomic, retain) NSString *devKey;
@property (nonatomic, assign) BOOL isLogged;
@property (nonatomic, assign) BOOL saveUser;
@property (nonatomic, retain) NSArray *fbPermissons;
@property (nonatomic, assign) int processing;
@property (nonatomic, retain) NSString *executing;

/*
 * initialize
 */
-(KRFacebook *)initWithDelegate:(id<KRFacebookDelegate>)_sdkDelegate;
-(KRFacebook *)initWithDevKey:(NSString *)_devKey
                      delegate:(id<KRFacebookDelegate>)_sdkDelegate;

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
 *   _imageUrl    = 輸入圖片的 URL 進行上傳
 *   _description = 圖片說明
 */
-(void)uploadWithPhotoUrl:(id)_imageUrl 
           andDescription:(NSString *)_description; 

/* 
 * @上傳圖片 :
 *   _image       = 直接傳入圖片上傳
 *   _description = 圖片說明
 */
-(void)uploadWithImage:(UIImage *)_image
        andDescription:(NSString *)_description;

/*
 * @直接上傳影音至塗鴉牆
 *   _filePath    = 影音檔案的路徑
 *   _title       = PO 文的標題
 *   _description = PO 文的內文
 */
-(void)uploadWithMediaPath:(NSString *)_filePath 
                  andTitle:(NSString *)_title 
            andDescription:(NSString *)_description;

/*
 * @取得要上傳至 Facebook 的官方限制大小
 */
-(void)getVideoUploadLimit;

/*
 * @儲存離線 Access Token 值 : 以便後續自動登入
 */
-(void)saveAccessToken:(BOOL)_saveOrClear;

/*
 * @儲存 User 資訊 : 以便後續處理
 */
-(void)saveUserInfos:(BOOL)_saveOrClear;

/*
 * @取得檔案 MIME Type : 傳入副檔名
 */
-(NSString *)getFileMimeTypeWithExt:(NSString *)_fileExt;

/*
 * @取得在 Facebook 上播放的影片 URL
 */
-(NSString *)getVideoUrlWithId:(NSString *)_videoId;

/*
 * @登入 :
 *   請求認證項目 ( Class 物件 :: 該物件的觸發方法 )
 */
-(void)loginWithPermissions:(NSArray *)permissions;

/*
 * @直接使用預設的 Permissions 項目登入
 */
-(void)login;

/*
 * @登出
 */
-(void)logout;

/*
 * @取得個人資訊
 */
-(void)getUserInfoWithKindOf:(NSString *)_kindOf;

/*
 * @是否已登入 ?
 *   如直接先執行這裡，則會將原先儲存的 FB TOKEN 值取出來認證
 */
-(BOOL)alreadyLogged;

/*
 * @清除已儲存的 FB 個人資訊
 */
-(void)clearSavedDatas;

/*
 * @清除委派 ( 好像沒用 = = )
 */
-(void)clearDelegates;

/*
 * @取得 Token
 */
-(NSString *)getToken;

/*
 * @取得已儲存的個人資料
 */
-(NSDictionary *)getSavedDatas;

@end


@protocol KRFacebookDelegate <NSObject>

@optional

//Errors
-(void)krFacebook:(KRFacebook *)_krFacebook didLoadWithErrors:(NSError *)errors;
//已儲存 User 的私人資訊
-(void)krFacebook:(KRFacebook *)_krFacebook didSavedUserPrivations:(NSDictionary *)_savedDatas;
//是否成功登入
-(void)krFacebook:(KRFacebook *)_krFacebook didLogin:(BOOL)_isLogin;
//是否成功登出
-(void)krFacebook:(KRFacebook *)_krFacebook didLogout:(BOOL)_isLogout;
//是否取消登入
-(void)krFacebook:(KRFacebook *)_krFacebook didCancelLogin:(BOOL)_isCancel;
//成功登入
-(void)krFacebookDidLogin;
//成功登出
-(void)krFacebookDidLogout;
//取消登入
-(void)krFacebookDidCancel;
//登入失敗
-(void)krFacebookDidFailedLogin;
//請求完畢 : 取得 Facebook 回傳的萬用型態
-(void)krFacebook:(KRFacebook *)_krFacebook didLoadWithResponses:(id)_results andKindOf:(NSString *)_perform;
//請求完畢 : 取得 Facebook 回傳的陣列型態值 : andKinfOf 執行什麼動作 ( Ex: get.user.infos )
-(void)krFacebook:(KRFacebook *)_krFacebook didLoadWithResponsesOfDictionary:(NSDictionary *)_results andKindOf:(NSString *)_perform;
//請求完畢 : 取得 Facebook 回傳的字串型態值 : andKinfOf 執行什麼動作 ( Ex: upload.photos )
-(void)krFacebook:(KRFacebook *)_krFacebook didLoadWithResponseOfString:(NSString *)_result andKindOf:(NSString *)_perform;
//請求失敗
-(void)krFacebook:(KRFacebook *)_krFacebook didFailWithResponses:(NSError *)_errors andKindOf:(NSString *)_perform;
//已完成所有請求
-(void)krFacebookDidFinishAllRequests;

@end
