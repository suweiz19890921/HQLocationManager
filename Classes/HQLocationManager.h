//
//  HQLocationManager.h
//  CameraRuler
//
//  Created by LiuHuanQing on 15/3/31.
//  Copyright (c) 2015年 HQ_L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import "HQGeocodeModel.h"
typedef NS_ENUM(NSInteger, HQLocationServicesState)
{
    
    HQLocationServicesStateAvailable,
    HQLocationServicesStateNotDetermined,
    HQLocationServicesStateDenied,
    HQLocationServicesStateRestricted,
    HQLocationServicesStateDisabled,
    HQLocationStatusError
};

typedef void (^locationResponseBlock)(CLLocation *location,HQLocationServicesState status);

@interface HQLocationManager : NSObject

@property (strong, nonatomic) CLLocation *standardLocation;//标准坐标
@property (strong, nonatomic) CLLocation *lastLocation;//最有所在位置

/**
 *  获取最后定位的坐标geohash值
 *
 *  @return geohash
 */
- (NSString *)lastGeoHash;

/**
 *  获得位置管理员单单例
 *
 *  @return HQLocationManager 单例
 */
+ (instancetype)sharedInstance;

/**
 *  获取位置服务状态
 *
 *  @return HQLocationServicesState类型的标识符
 */
+ (HQLocationServicesState)locationServicesState;

/**
 *  启动位置更新且添加一个响应位置更新的方法
 *  收到响应后关闭位置服务
 *  lastLocation 数据会得到更新
 *  @param loctaionResponse 处理收到的位置信息
 */
- (void)startUpdatingLocationWithCallback:(locationResponseBlock)loctaionResponse;

/**
 *  启动位置服务
 *  lastLocation 数据会得到更新
 */
- (void)startUpdatingLocation;

/**
 *  停止位置服务
 */
- (void)stopUpdatingLocation;

/**
 *  CLLocation 转GEOHASH
 *
 *  @param location CLLocation
 *
 *  @return GEOHASH
 */
+ (NSString *)geohash:(CLLocation *)location;

/**
 *  geohash转CLLocation
 *
 *  @param geohash geohash
 *
 *  @return CLLocation
 */
+ (CLLocation *)geohast2location:(NSString *)geohash;

/**
 通过位置获取详细位置信息

 @param loacation location
 @param completion completion
 */
+ (void)reverseGeocodeLocation:(CLLocation *)loacation completion:(void(^)(HQGeocodeModel *geocode))completion;

@end
