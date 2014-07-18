//
//  KRFacebook.h
//  V2.2
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 2013/01/20.
//  Copyright (c) 2012 - 2014年 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

typedef void (^KRFacebookCompletionHandler)(BOOL finished, id result);
typedef void (^KRFacebookErrorHandler)(NSError *error);

typedef enum _KRFacebookHttpMethods
{
    KRFacebookHttpMethodGet = 0,
    KRFacebookHttpMethodPost
}KRFacebookHttpMethods;

@interface KRFacebook : NSObject
{
    FBSession *fbSession;
    NSString *accessToken;
    NSArray *permissions;
    
}

@property (nonatomic, strong) FBSession *fbSession;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSArray *permissions;
@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *userEmail;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userGender;


+(KRFacebook *)sharedManager;
-(id)init;

#pragma --mark FacebookSDK & Information
-(void)login;
-(void)loginWithCompletion:( void(^)(BOOL success, NSDictionary *userInfo) )_completion;
-(void)logout;
-(void)awakeFBSession;
-(BOOL)isFBSessionOpen;
-(FBSession *)getActiveFBSession;

#pragma --mark Getters
-(NSString *)accessToken;

#pragma --mark Publishing News Feed (發佈各式留言)
-(void)publishNewsFeedWallWithTitle:(NSString *)_title
                           titleURL:(NSString *)_titleURL
                            message:(NSString *)_message
                       errorHandler:(KRFacebookErrorHandler)_errorHandler
                  completionHandler:(KRFacebookCompletionHandler)_completionHandler;

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
                 completionHandler:(KRFacebookCompletionHandler)_completionHandler;

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
                  completionHandler:(KRFacebookCompletionHandler)_completionHandler;

-(void)publishNewsFeedWithVideoURL:(NSString *)_viedoURL
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
                 completionHandler:(KRFacebookCompletionHandler)_completionHandler;

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
                       completionHandler:(KRFacebookCompletionHandler)_completionHandler;

#pragma Uploading Photos
-(void)uploadPhotoHttpURL:(NSURL *)_photoURL
              description:(NSString *)_description
             errorHandler:(KRFacebookErrorHandler)_errorHandler
        completionHandler:(KRFacebookCompletionHandler)_completionHandler;
-(void)uploadPhotoLocalPath:(NSString *)_photoPath
                description:(NSString *)_description
               errorHandler:(KRFacebookErrorHandler)_errorHandler
          completionHandler:(KRFacebookCompletionHandler)_completionHandler;
-(void)uploadImage:(UIImage *)_image description:(NSString *)_description errorHandler:(KRFacebookErrorHandler)_errorHandler
     completionHandler:(KRFacebookCompletionHandler)_completionHandler;

#pragma --mark Uploading Video Methods
-(void)uploadVideoLocalPath:(NSString *)_videoPath
                      title:(NSString *)_title
                description:(NSString *)_description
               errorHandler:(KRFacebookErrorHandler)_errorHandler
          completionHandler:(KRFacebookCompletionHandler)_completionHandler;
-(void)getUploadVideoLimitSizeWithCompletion:(KRFacebookCompletionHandler)_completionHandler;

#pragma --mark GraphAPI Calls
-(void)requestGraphApiPath:(NSString *)_graphPath completionHandler:(KRFacebookCompletionHandler)_completionHandler;
-(void)requestGraphApiPath:(NSString *)_graphPath parameters:(NSDictionary *)_parameters httpMethod:(KRFacebookHttpMethods)_httpMethod completionHandler:(KRFacebookCompletionHandler)_completionHandler;


@end
