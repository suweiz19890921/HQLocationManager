//
//  HQGeocodeModel.h
//  HQLocationManagerDemo
//
//  Created by 杨洋 on 10/04/2017.
//  Copyright © 2017 solot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+HQDBDecode.h"

@interface HQGeocodeModel : NSObject

@property (nonatomic, copy) NSString *isoCountryCode;           //CN

@property (nonatomic, copy) NSString *geohash;

@property (nonatomic, copy) NSString *country;                  //国

@property (nonatomic, copy) NSString *subLocality;              //区

@property (nonatomic, copy) NSString *locality;                 //市

@property (nonatomic, copy) NSString *administrativeArea;       //省

@property (nonatomic, copy) NSString *formatAddressString;      //详细地址

@property (nonatomic, copy) NSString *name;

@end
