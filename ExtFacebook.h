//
//  ExtFacebook.h
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 12/6/11.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"
#import "FBLoginButton.h"

#define FB_ACCESS_TOKEN_KEY    @"FBAccessToken"
#define FB_EXPIRATION_DATE_KEY @"FBExpirationDate"
#define FB_USER_ACCOUNT_KEY    @"FBUserAccount"
#define FB_USER_ID_KEY         @"FBUserId"
//Facebook Developer Key of App
#define FB_DEVELOPER_KEY       @""

/*
 * 當前的執行動作集合
 */
typedef enum _ExtFacebookProcess{
    ExtFacebookProcessForNothing,
    ExtFacebookProcessForPublishOnFeeds,
    ExtFacebookProcessForPublishOnPhoto,
    ExtFacebookProcessForPublishOnMedia,
    ExtFacebookProcessForLogin,
    ExtFacebookProcessForLogout,
    ExtFacebookProcessForCancell,
    ExtFacebookProcessForLoginFailed,
    ExtFacebookProcessForUploadPhotos,
    ExtFacebookProcessForUploadPhoto,
    ExtFacebookProcessForUploadMedia,
    ExtFacebookProcessForGetUserPhotos,
    ExtFacebookProcessForGetUserPermissions,
    ExtFacebookProcessForGetUserFeeds,
    ExtFacebookProcessForGetUserFriends,
    ExtFacebookProcessForGetUserAlbums,
    ExtFacebookProcessForGetUserUploads,
    ExtFacebookProcessForGetUserInfo,
    ExtFacebookProcessForGetVideoUploadLimit
    // ... 
} ExtFacebookProcess;

@protocol ExtFacebookDelegate;
@class Facebook;
@class SBJSON;

@interface ExtFacebook : NSObject <FBRequestDelegate, FBDialogDelegate, FBSessionDelegate>{
    id<ExtFacebookDelegate> delegate;
    SBJSON *jsonWriter;
    NSString *devKey;
    BOOL isLogged;    
    BOOL saveUser;
    NSArray *fbPermissons;   
    int processing;
    NSString *executing;
}

@property (nonatomic, assign) id<ExtFacebookDelegate> delegate;
//宣告 JSON 製作物件
@property (nonatomic, retain) SBJSON *jsonWriter;
//Facebook API Key
@property (nonatomic, retain) NSString *devKey;
//是否己登入
@property (nonatomic, assign) BOOL isLogged;
//是否正在進行儲存使用者資訊的動作 ?
@property (nonatomic, assign) BOOL saveUser;
//宣告向 FB 請求的認證資料項目 
@property (nonatomic, retain) NSArray *fbPermissons;
//目前正在執行的動作
@property (nonatomic, assign) int processing;
@property (nonatomic, retain) NSString *executing;

/*
 * initialize
 */
-(ExtFacebook *)initWithDelegate:(id<ExtFacebookDelegate>)_sdkDelegate;
-(ExtFacebook *)initWithDevKey:(NSString *)_devKey 
                      delegate:(id<ExtFacebookDelegate>)_sdkDelegate;

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
-(NSDictionary *)setConfigsOfImagesUrlObjects:(NSArray *)imageSrcArray 
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
 *   _miniMessage 會出現在 Title 下面那一區
 */
-(void)publishFeedsWithImageSrc:(NSString *)_imageSrc 
                   andImageHref:(NSString *)_imageHref 
                       andTitle:(NSString *)_title 
                    andSubtitle:(NSString *)_subtitle 
                 andDescription:(NSString *)_description 
                   andTitleHref:(NSString *)_titleHref
                   andMiniTitle:(NSString *)_miniTitle
               andMiniTitleHref:(NSString *)_miniTitleHref
                 andMiniMessage:(NSString *)_miniMessage;

/*
 * @一次性設定並發佈多張圖片留言
 *   圖片陣列 : _imageSrcArray / _imageHrefArray 需為互相對應的 Key / Value 陣列
 */
-(void)publishFeedsWithImageSrcArray:(NSArray *)_imageSrcArray 
                   andImageHrefArray:(NSArray *)_imageHrefArray 
                            andTitle:(NSString *)_title 
                         andSubtitle:(NSString *)_subtitle 
                      andDescription:(NSString *)_description 
                        andTitleHref:(NSString *)_titleHref
                        andMiniTitle:(NSString *)_miniTitle
                    andMiniTitleHref:(NSString *)_miniTitleHref
                      andMiniMessage:(NSString *)_miniMessage;

/*
 * 一次性設定並發佈影音留言
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
                 andMiniMessage:(NSString *)_miniMessage;

/*
 * 發佈純文字留言( Feeds )
 */
-(void)publishOnFeedsWallWithTitle:(NSString *)_title 
                      andTitleHref:(NSString *)_titleHref 
                        andMessage:(NSString *)_message;



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
 //使用 REST API
 //[取得個人相簿] : 相簿(aid) / 使用者(uid) :: 取得指定相簿或使用者全部的相簿
 -(void)getAlbumsWithId:(NSString *)_id andKindOf:(NSString *)_kindOf;
 */

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
 * @是否已登入 ?
 *   如直接先執行這裡，則會將原先儲存的 FB TOKEN 值取出來認證
 */
-(BOOL)alreadyLogged;

/*
 * @清除已儲存的 FB 個人資訊
 */
-(void)clearSavedDatas;

@end


@protocol ExtFacebookDelegate <NSObject> 

@optional

//Errors
-(void)extFacebook:(ExtFacebook *)_extFacebook didLoadWithErrors:(NSError *)errors;
//已儲存 User 的私人資訊
-(void)extFacebook:(ExtFacebook *)_extFacebook didSavedUserPrivations:(NSDictionary *)_savedDatas;
//成功登入
-(void)extFacebook:(ExtFacebook *)_extFacebook didLogin:(BOOL)_isLogin;
//成功登出
-(void)extFacebook:(ExtFacebook *)_extFacebook didLogout:(BOOL)_isLogout;
//取消登入
-(void)extFacebook:(ExtFacebook *)_extFacebook didCancelLogin:(BOOL)_isCancel;
//請求完畢 : 取得 Facebook 回傳的萬用型態
-(void)extFacebook:(ExtFacebook *)_extFacebook didLoadWithResponses:(id)_results andKindOf:(NSString *)_perform;
//請求完畢 : 取得 Facebook 回傳的陣列型態值 : andKinfOf 執行什麼動作 ( Ex: getUserInfos )
-(void)extFacebook:(ExtFacebook *)_extFacebook didLoadWithResponsesOfDictionary:(NSDictionary *)_results andKindOf:(NSString *)_perform;
//請求完畢 : 取得 Facebook 回傳的字串型態值 : andKinfOf 執行什麼動作 ( Ex: uploadPhotos )
-(void)extFacebook:(ExtFacebook *)_extFacebook didLoadWithResponseOfString:(NSString *)_result andKindOf:(NSString *)_perform;
//請求失敗
-(void)extFacebook:(ExtFacebook *)_extFacebook didFailWithResponses:(NSError *)_errors andKindOf:(NSString *)_perform;

@end
