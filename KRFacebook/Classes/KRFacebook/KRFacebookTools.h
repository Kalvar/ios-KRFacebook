//
//  KRFacebookTools.h
//  KRFacebook
//
//  Created by Kalvar on 13/9/19.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@class AppDelegate;

@interface KRFacebookTools : NSObject
{
    
}

#pragma --mark Mains
+(AppDelegate *)getAppDelegate;

#pragma --mark Judges
+(BOOL)isNull:(id)_object;
+(NSString *)getFileMimeTypeWithExt:(NSString *)_fileExt;

#pragma --mark NSDefaults
+(id)getDefaultValueForKey:(NSString *)_key;
+(NSString *)getDefaultStringValueForKey:(NSString *)_key;
+(BOOL)getDefaultBoolValueForKey:(NSString *)_key;
+(void)setDefaultValue:(id)_value forKey:(NSString *)_key;
+(void)setDefaultStringValue:(NSString *)_value forKey:(NSString *)_key;
+(void)setDefaultBoolValue:(BOOL)_value forKey:(NSString *)_key;
+(void)removeDefaultValueForKey:(NSString *)_key;

#pragma --mark UIImageVIew
+(UIImage *)imageNoCacheWithName:(NSString *)_imageName;

@end
