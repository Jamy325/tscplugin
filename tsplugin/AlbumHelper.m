//
//  AlbueHelper.m
//  hongbao
//
//  Created by Jamy on 16-4-26.
//  Copyright (c) 2016年 Jamy. All rights reserved.
//

#import "AlbumHelper.h"
#import <UIKit/UIKit.h>
#import <AssetsLibrary/ALAsset.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <AssetsLibrary/ALAssetsGroup.h>
#import <AssetsLibrary/ALAssetRepresentation.h>

#define SCREEN [UIScreen mainScreen].bounds.size



@implementation AlbumHelper

#pragma mark - 创建相册

+ (void)saveToAlbumWithMetadata:(NSDictionary *)metadata
                      imageData:(NSData *)imageData
                customAlbumName:(NSString *)customAlbumName
                completionBlock:(void (^)(void))completionBlock
                   failureBlock:(void (^)(NSError *error))failureBlock
{
    
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    ALAssetsLibrary *weakSelf = assetsLibrary;
    void (^AddAsset)(ALAssetsLibrary *, NSURL *) = ^(ALAssetsLibrary *assetsLibrary, NSURL *assetURL) {
        [assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                
                if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:customAlbumName]) {
                    [group addAsset:asset];
                    if (completionBlock) {
                        completionBlock();
                    }
                }
            } failureBlock:^(NSError *error) {
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        } failureBlock:^(NSError *error) {
            if (failureBlock) {
                failureBlock(error);
            }
        }];
    };
    [assetsLibrary writeImageDataToSavedPhotosAlbum:imageData metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
        if (customAlbumName) {
            [assetsLibrary addAssetsGroupAlbumWithName:customAlbumName resultBlock:^(ALAssetsGroup *group) {
                if (group) {
                    [weakSelf assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                        [group addAsset:asset];
                        if (completionBlock) {
                            completionBlock();
                        }
                    } failureBlock:^(NSError *error) {
                        if (failureBlock) {
                            failureBlock(error);
                        }
                    }];
                } else {
                    AddAsset(weakSelf, assetURL);
                }
            } failureBlock:^(NSError *error) {
                AddAsset(weakSelf, assetURL);
            }];
        } else {
            if (completionBlock) {
                completionBlock();
            }
        }
    }];
}


+ (void)createAlbum:(NSString*) albueName
{
    /**阻塞线程*/
    // 创建一个信号量，值为0
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    // 在一个操作结束后发信号，这会使得信号量+1

    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary retain];
    NSMutableArray *groups=[[NSMutableArray alloc] init];
    [groups retain];
    
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop)
    {
        if (group)
        {
            [groups addObject:group];
        }
        
        else
        {
            BOOL haveHDRGroup = NO;
            
            for (ALAssetsGroup *gp in groups)
            {
                NSString *name =[gp valueForProperty:ALAssetsGroupPropertyName];
                
                if ([name isEqualToString:albueName])
                {
                    haveHDRGroup = YES;
                }
            }
            
            if (!haveHDRGroup)
            {
                //do add a group named "XXXX"
                [assetsLibrary addAssetsGroupAlbumWithName:albueName
                                               resultBlock:^(ALAssetsGroup *g)
                 {
                     if (g){
                         [groups addObject:g];
                     }
                     
                      dispatch_semaphore_signal(sema);
                 }
                                              failureBlock:^(NSError* err){
                                                  NSLog(@"error:%@", err);
                                                  dispatch_semaphore_signal(sema);
                                              }];
                haveHDRGroup = YES;
            }
        }
    };
    
    
    //创建相簿
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:listGroupBlock failureBlock:^(NSError *error) {
        //失败
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"创建相册失败"
                                                       message:@"请打开 设置-隐私-照片 来进行设置"
                                                      delegate:nil
                                             cancelButtonTitle:@"确定"
                                             otherButtonTitles:nil, nil];
        [alert show];
          dispatch_semaphore_signal(sema);
    }];
    
    // 一开始执行到这里信号量为0，线程被阻塞，直到上述操作完成使信号量+1,线程解除阻塞
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    [assetsLibrary release];
    [groups release];
    
}


+(void) saveImageToCustomeAlbume:(NSString*) imagePath albume:(NSString*)albueName{
    UIImage* img = [UIImage imageWithContentsOfFile:imagePath];
    if (img == nil){
        return;
    }
   [img retain];
  //  dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    NSString* low = [imagePath lowercaseString];
    NSData* d = nil;
    
    if ([low rangeOfString:@".jpg"].length > 0){
        d = UIImageJPEGRepresentation(img, 1);
    }
    
    if ([low rangeOfString:@".png"].length > 0){
        d = UIImagePNGRepresentation(img);
    }
    if (d == nil){
        return;
    }
    
    
    [AlbumHelper saveToAlbumWithMetadata:nil imageData:d customAlbumName:albueName completionBlock:^
     {
         //这里可以创建添加成功的方法
          [img release];
    //     dispatch_semaphore_signal(sema);
     }
                     failureBlock:^(NSError *error)
     {
         [img release];
         //处理添加失败的方法显示alert让它回到主线程执行，不然那个框框死活不肯弹出来
         dispatch_async(dispatch_get_main_queue(), ^{
             
             //添加失败一般是由用户不允许应用访问相册造成的，这边可以取出这种情况加以判断一下
             if([error.localizedDescription rangeOfString:@"User denied access"].location != NSNotFound ||[error.localizedDescription rangeOfString:@"用户拒绝访问"].location!=NSNotFound){
                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:error.localizedDescription message:error.localizedFailureReason delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles: nil];
                 
                 [alert show];
             }
             
          //    dispatch_semaphore_signal(sema);
         });
     }];
    
    //    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
      //  [img release];
}



+(void) removeAllImageInAblume:(NSString*)albumname
{
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    // 在一个操作结束后发信号，这会使得信号量+1
    
    ALAssetsLibrary *lib = [[ALAssetsLibrary alloc]init];
    [lib retain];
    [lib enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        NSString *name =[group valueForProperty:ALAssetsGroupPropertyName];
        if ([name isEqualToString:albumname])
        {
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (result.isEditable) {
                    //在这里imageData 和 metaData设为nil，就可以将相册中的照片删除
                    [result setImageData:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                        NSLog(@"asset url(%@) should be delete . Error:%@ ", assetURL, error);
                    }];
                }
            }];
        }
        if (*stop){
            dispatch_semaphore_signal(sema);
        }
        
    } failureBlock:^(NSError *error) {
        NSLog(@"Error:%@ ", error);
        dispatch_semaphore_signal(sema);
    }];
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    [lib release];
    
    /**
     ios 8 以上用这个
     PHFetchResult *collectonResuts = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:[PHFetchOptions new]] ;
     [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
     PHAssetCollection *assetCollection = obj;
     if ([assetCollection.localizedTitle isEqualToString:@"Camera Roll"])  {
     PHFetchResult *assetResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:[PHFetchOptions new]];
     [assetResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
     [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
     //获取相册的最后一张照片
     if (idx == [assetResult count] - 1) {
     [PHAssetChangeRequest deleteAssets:@[obj]];
     }
     } completionHandler:^(BOOL success, NSError *error) {
     NSLog(@"Error: %@", error);
     }];
     }];
     }
     }];
     
     */
    
}

@end
