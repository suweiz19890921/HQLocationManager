//
//  HQGeocodeModel.m
//  HQLocationManagerDemo
//
//  Created by 杨洋 on 10/04/2017.
//  Copyright © 2017 solot. All rights reserved.
//

#import "HQGeocodeModel.h"

@implementation HQGeocodeModel

//** 主键列表*/
+ (nullable NSArray<NSString *> *)hq_propertyPrimarykeyList {
    return @[@"geohash"];
}

//** 所属库名称/
+ (nonnull NSString *)hq_dbName {
    return @"location.db";
}

@end
