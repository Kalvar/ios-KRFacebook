//
//  KRFacebookTools.m
//  KRFacebook
//
//  Created by Kalvar on 13/9/19.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

#import "KRFacebookTools.h"


@implementation KRFacebookTools (fixDefaults)

#pragma --mark Gets NSDefault Values
/*
 * @ 取出萬用型態
 */
+(id)_defaultValueForKey:(NSString *)_key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:_key];
}

/*
 * @ 取出 String
 */
+(NSString *)_defaultStringValueForKey:(NSString *)_key
{
    return [NSString stringWithFormat:@"%@", [self _defaultValueForKey:_key]];
}

/*
 * @ 取出 BOOL
 */
+(BOOL)_defaultBoolValueForKey:(NSString *)_key
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:_key];
}

#pragma --mark Saves NSDefault Values
/*
 * @ 儲存萬用型態
 */
+(void)_saveDefaultValue:(id)_value forKey:(NSString *)_forKey
{
    [[NSUserDefaults standardUserDefaults] setObject:_value forKey:_forKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/*
 * @ 儲存 String
 */
+(void)_saveDefaultValueForString:(NSString *)_value forKey:(NSString *)_forKey
{
    [self _saveDefaultValue:_value forKey:_forKey];
}

/*
 * @ 儲存 BOOL
 */
+(void)_saveDefaultValueForBool:(BOOL)_value forKey:(NSString *)_forKey
{
    [self _saveDefaultValue:[NSNumber numberWithBool:_value] forKey:_forKey];
}

#pragma --mark Removes NSDefault Values
+(void)_removeDefaultValueForKey:(NSString *)_key
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

@implementation KRFacebookTools (fixTools)



@end

@implementation KRFacebookTools

+(AppDelegate *)getAppDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma --mark Judges
+(BOOL)isNull:(id)_object
{
    return [_object isKindOfClass:[NSNull class]];
}

+(NSString *)getFileMimeTypeWithExt:(NSString *)_fileExt
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

#pragma --mark NSDefaults
/*
 * @ Getters
 */
+(id)getDefaultValueForKey:(NSString *)_key
{
    return [self _defaultValueForKey:_key];
}

+(NSString *)getDefaultStringValueForKey:(NSString *)_key
{
    return [self _defaultStringValueForKey:_key];
}

+(BOOL)getDefaultBoolValueForKey:(NSString *)_key
{
    return [self _defaultBoolValueForKey:_key];
}

/*
 * @ Setters
 */
+(void)setDefaultValue:(id)_value forKey:(NSString *)_key
{
    [self _saveDefaultValue:_value forKey:_key];
}

+(void)setDefaultStringValue:(NSString *)_value forKey:(NSString *)_key
{
    [self _saveDefaultValueForString:_value forKey:_key];
}

+(void)setDefaultBoolValue:(BOOL)_value forKey:(NSString *)_key
{
    [self _saveDefaultValueForBool:_value forKey:_key];
}

/*
 * @ Removers
 */
+(void)removeDefaultValueForKey:(NSString *)_key
{
    [self _removeDefaultValueForKey:_key];
}

#pragma --mark UIImageVIew
+(UIImage *)imageNoCacheWithName:(NSString *)_imageName
{
    return [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], _imageName]];
}

@end
