//
//  AlbueHelper.h
//  hongbao
//
//  Created by Jamy on 16-4-26.
//  Copyright (c) 2016年 Jamy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlbumHelper : NSObject
//创建自定义相册
+ (void)createAlbum:(NSString*) albueName;

//保持图片到自定义相册
+(void) saveImageToCustomeAlbume:(NSString*) imagePath albume:(NSString*)albueName;

//清空相册
+(void) removeAllImageInAblume:(NSString*)albumname;
@end
