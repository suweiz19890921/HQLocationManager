//
//  HQGeocodeModel.h
//  HQLocationManagerDemo
//
//  Created by 杨洋 on 10/04/2017.
//  Copyright © 2017 solot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HQGeocodeModel : NSObject

@property (nonatomic, copy) NSString *isoCountryCode;

@property (nonatomic, copy) NSString *geohash;

@property (nonatomic, copy) NSString *country;

@property (nonatomic, copy) NSString *locality;

@property (nonatomic, copy) NSString *administrativeArea;

@property (nonatomic, copy) NSString *formatAddressString;

@property (nonatomic, copy) NSString *lastName;

@end
