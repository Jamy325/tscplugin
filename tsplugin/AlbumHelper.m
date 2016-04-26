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
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    NSMutableArray *groups=[[NSMutableArray alloc]init];
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
                                               resultBlock:^(ALAssetsGroup *group)
                 {
                     [groups addObject:group];
                     
                 }
                                              failureBlock:nil];
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
    }];
}


+(void) saveImageToCustomeAlbume:(NSString*) imagePath albume:(NSString*)albueName{
    UIImage* img = [UIImage imageNamed:imagePath];
    if (img == nil){
        return;
    }
//    [img retain];
    
    [AlbumHelper saveToAlbumWithMetadata:nil imageData:UIImagePNGRepresentation(img) customAlbumName:albueName completionBlock:^
     {
         //这里可以创建添加成功的方法
    //     [img release];
     }
                     failureBlock:^(NSError *error)
     {
     //    [img release];
         //处理添加失败的方法显示alert让它回到主线程执行，不然那个框框死活不肯弹出来
         dispatch_async(dispatch_get_main_queue(), ^{
             
             //添加失败一般是由用户不允许应用访问相册造成的，这边可以取出这种情况加以判断一下
             if([error.localizedDescription rangeOfString:@"User denied access"].location != NSNotFound ||[error.localizedDescription rangeOfString:@"用户拒绝访问"].location!=NSNotFound){
                 UIAlertView *alert=[[UIAlertView alloc]initWithTitle:error.localizedDescription message:error.localizedFailureReason delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles: nil];
                 
                 [alert show];
             }
         });
     }];
}



+(void) removeAllImageInAblume:(NSString*)albumname
{
    ALAssetsLibrary *lib = [[ALAssetsLibrary alloc]init];
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
    } failureBlock:^(NSError *error) {
        NSLog(@"Error:%@ ", error);
    }];
    
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
