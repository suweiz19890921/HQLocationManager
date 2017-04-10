//
//  PositionDecode.h
//  seafishing2
//
//  Created by mac on 14-9-25.
//  Copyright (c) 2014年 Szfusion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PositionDecode : NSObject
int outOfChina(double lat, double lng);
void wgs2gcj(double wgsLat, double wgsLng, double *gcjLat, double *gcjLng);
void gcj2wgs(double gcjLat, double gcjLng, double *wgsLat, double *wgsLnt);
void gcj2wgs_exact(double gcjLat, double gcjLng, double *wgsLat, double *wgsLnt);
double distance(double latA, double lngA, double latB, double lngB);
@end
