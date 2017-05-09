//
//  HQLocationManager.m
//  CameraRuler
//
//  Created by LiuHuanQing on 15/3/31.
//  Copyright (c) 2015年 HQ_L. All rights reserved.
//

#import "HQLocationManager.h"
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import <CoreLocation/CLError.h>
#import "GeoHash.h"
#import "PositionDecode.h"
#import <CoreLocation/CLGeocoder.h>
#import <CoreLocation/CLPlacemark.h>
#import <AFNetworking/AFNetworking.h>

#define HQLAST_LOCATION @"HQLAST_LOCATION"
@interface HQLocationManager()<CLLocationManagerDelegate>
{
    CLLocation *_lastLocation;
}

@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic,strong) NSMutableArray *locationResponses;
@property (nonatomic,assign) BOOL uploadError;
@property (nonatomic,strong) NSCache *reverseGeocodeCache;
@property (nonatomic,strong) NSMutableArray *locations;
@end

@implementation HQLocationManager
+ (instancetype)sharedInstance
{
    static HQLocationManager *_sharedInstance;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

+ (HQLocationServicesState)locationServicesState
{
    if ([CLLocationManager locationServicesEnabled] == NO)
    {
        return HQLocationServicesStateDisabled;
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        return HQLocationServicesStateNotDetermined;
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
    {
        return HQLocationServicesStateDenied;
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
    {
        return HQLocationServicesStateRestricted;
    }
    
    return HQLocationServicesStateAvailable;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _locationManager                 = [[CLLocationManager alloc] init];
        _locationManager.delegate        = self;
        _locationManager.distanceFilter  = kCLDistanceFilterNone;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationResponses               = [NSMutableArray array];
        _locations                       = [NSMutableArray array];
        //启动时主动更新
        //            [self autoUpdateLocation];
        //主动更新位置
        [NSTimer scheduledTimerWithTimeInterval:3*60 target:self selector:@selector(autoUpdateLocation) userInfo:nil repeats:YES];
    }
    return self;
}

- (NSCache *)reverseGeocodeCache
{
    if(_reverseGeocodeCache == nil)
    {
        _reverseGeocodeCache = [[NSCache alloc] init];
//        NSArray *geocodes = [HQGeocodeModel all];
//        for (HQGeocodeModel *g in geocodes) {
//            [_reverseGeocodeCache setObject:g forKey:g.geohash];
//        }
    }
    return _reverseGeocodeCache;
}

- (void)startUpdatingLocationWithCallback:(locationResponseBlock)loctaionResponse
{
    if(loctaionResponse != NULL)
        [self.locationResponses addObject:loctaionResponse];
    [self startUpdatingLocation];
}

- (void)startUpdatingLocation
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        BOOL hasAlwaysKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] != nil;
        BOOL hasWhenInUseKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] != nil;
        if (hasAlwaysKey)
        {
            [self.locationManager requestAlwaysAuthorization];
        } else if (hasWhenInUseKey)
        {
            [self.locationManager requestWhenInUseAuthorization];
        } else
        {
            NSAssert(hasAlwaysKey || hasWhenInUseKey, @"在IOS 8+使用定位服务,你需要在Info.plist 添加NSLocationWhenInUseUsageDescription 或 NSLocationAlwaysUsageDescription.");
        }
    }
#endif
    [self.locationManager startUpdatingLocation];
}


- (void)stopUpdatingLocation
{
    [self completeAllLocationResponses];
    [self.locationManager stopUpdatingLocation];
}

- (void)completeAllLocationResponses
{
    HQLocationServicesState status = [HQLocationManager locationServicesState];
    NSArray *array = [NSArray arrayWithArray:self.locationResponses];
    for (locationResponseBlock loctaionResponse in array)
    {
        loctaionResponse(self.lastLocation,status);
        [self.locationResponses removeObject:loctaionResponse];
    }
    [self.locationManager stopUpdatingLocation];
}

- (void)processLocationResponses
{
    [self completeAllLocationResponses];
    
    
}

+ (NSString *)geohash:(CLLocation *)location
{
    if(location)
        return [GeoHash hashForLatitude:location.coordinate.latitude longitude:location.coordinate.longitude length:9];
    return nil;
}

- (NSString *)lastGeoHash
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:HQLAST_LOCATION];
}

- (void)setLastLocation:(CLLocation *)lastLocation
{
    _lastLocation = lastLocation;
    NSString *geohash = [HQLocationManager geohash:lastLocation];
    [[NSUserDefaults standardUserDefaults] setObject:geohash forKey:HQLAST_LOCATION];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (CLLocation *)lastLocation
{
    if(_lastLocation == nil)
    {
        NSString *geohash = [self lastGeoHash];;
        if(geohash)
        {
            GHArea *geo = [GeoHash areaForHash:geohash];
            _lastLocation = [[CLLocation alloc] initWithLatitude:geo.latitude.min.doubleValue longitude:geo.longitude.min.doubleValue];
        }
    }
    return _lastLocation;
}

+ (CLLocation *)geohast2location:(NSString *)geohash
{
    if (geohash)
    {
        GHArea *geo = [GeoHash areaForHash:geohash];
        if (geo)
        {
            CLLocation  *loc = [[CLLocation alloc] initWithLatitude:geo.latitude.min.doubleValue longitude:geo.longitude.min.doubleValue];
            return loc;
        }

    }
    return nil;
}

- (void)autoUpdateLocation
{
    [self startUpdatingLocationWithCallback:nil];
}

+ (void)reverseGeocodeLocation:(CLLocation *)loacation completion:(void(^)(HQGeocodeModel *geocode))completion
{
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    NSString *geohash = [self geohash:loacation];
    HQGeocodeModel *g = [[HQLocationManager sharedInstance].reverseGeocodeCache objectForKey:geohash];
    if(g)
    {
        if(completion)completion(g);
    }
    else
    {
        if (geohash) {
            g = [[HQGeocodeModel hq_selectByColumns:@{@"geohash":geohash}] firstObject];
        }
        if (g)
        {
            [[HQLocationManager sharedInstance].reverseGeocodeCache setObject:g forKey:g.geohash];
            if(completion)completion(g);
        }
        else
        {
            [geocoder reverseGeocodeLocation:loacation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                if(placemarks.count > 0)
                {
                    CLPlacemark *placemark = [placemarks firstObject];
                    
                    HQGeocodeModel *geo = [HQGeocodeModel new];
                    geo.geohash = geohash;
                    geo.country = placemark.country;
                    geo.locality = placemark.locality;
                    geo.administrativeArea = placemark.administrativeArea;
                    geo.isoCountryCode = placemark.ISOcountryCode;
                    geo.name = placemark.name;
                    NSDictionary *dict = placemark.addressDictionary;
                    NSArray *arr = [dict objectForKey:@"FormattedAddressLines"];
                    if (arr.count > 0) {
                        NSString *str = [arr firstObject];
                        geo.formatAddressString = str;
                    }

                    
//                    NSLog(@"name %@",placemark.name);
//                    NSLog(@"placemark.thoroughfare %@",placemark.thoroughfare);
//                    NSLog(@"subThoroughfare %@",placemark.subThoroughfare);
//                    NSLog(@"locality %@",placemark.locality);
//                    NSLog(@"subLocality %@",placemark.subLocality);
//                    NSLog(@"administrativeArea %@",placemark.administrativeArea);
//                    NSLog(@"subAdministrativeArea %@",placemark.subAdministrativeArea);
//                    NSLog(@"postalCode %@",placemark.postalCode);
//                    NSLog(@"ISOcountryCode %@",placemark.ISOcountryCode);
//                    NSLog(@"country %@",placemark.country);
//                    NSLog(@"inlandWater %@",placemark.inlandWater);
//                    NSLog(@"ocean %@",placemark.ocean);
                    [geo hq_insert];
                    [[HQLocationManager sharedInstance].reverseGeocodeCache setObject:geo forKey:geo.geohash];
                    if(completion)
                    {
                        completion(geo);
                    }
                }
                else
                {

                    [self reverseGoogleGeocodeLocation:loacation completion:^(HQGeocodeModel *HQGeocodeModel)
                    {
                        if(HQGeocodeModel)
                        {
                            if (completion)
                            {
                                completion(HQGeocodeModel);
                            }
                        }
                        else
                        {
//                            HQGeocodeModel *geo = [HQGeocodeModel new];
//                            geo.geohash = (NSString<PrimaryKey> *)geohash;
//                            geo.country = Locale(@"location.weizhiweizhi");
//                            [[HQLocationManager sharedInstance].reverseGeocodeCache setObject:geo forKey:geo.geohash];
                            if (completion)
                            {
                                completion(nil);
                            }
                        }
                    }];
                }
            }];
        }
    }
}


+ (void)reverseGoogleGeocodeLocation:(CLLocation *)loacation completion:(void(^)(HQGeocodeModel *HQGeocodeModel))completion
{
    double lat = loacation.coordinate.latitude;
    double lng = loacation.coordinate.longitude;
//    NSString *langua = [GlobalConfig useLanguage];
//    if ([langua isEqualToString:@"zh_Hans"]) {        // 简体中文
//        langua = @"zh_CN";
//    }
//    else if ([langua hasPrefix:@"zh_Hant"]){     // 繁体中文
//        langua = @"zh_TW";
//    }

    NSString *urlHost,*langua;
//    if([GlobalConfig isChina])
//    {
//        urlHost = @"http://ditu.google.cn";
//    }
//    else
//    {
        urlHost = @"http://maps.googleapis.com";
//    }

    NSString *urlStr = [NSString stringWithFormat:@"%@/maps/api/geocode/json?latlng=%f,%f&language=%@&sensor=false",urlHost,lat,lng,langua];
    
    AFHTTPSessionManager *manger = [AFHTTPSessionManager manager];
    manger.requestSerializer.timeoutInterval = 15;
    
    [manger POST:urlStr parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable dict) {
                if(dict)
                {
                    NSArray *results = [dict objectForKey:@"results"];
                    if(results.count > 0)
                    {
                        NSString *geohash = [self geohash:loacation];
        
                        HQGeocodeModel *geo = [HQGeocodeModel new];
                        geo.geohash = geohash;
        
                        NSArray *address_components = [[results firstObject] objectForKey:@"address_components"];
                        for (NSDictionary *address in address_components) {
                            if([[[address objectForKey:@"types"] firstObject] isEqualToString:@"country"])
                            {
                                geo.country = [address objectForKey:@"long_name"];
                            }
                            else if([[[address objectForKey:@"types"] firstObject] isEqualToString:@"administrative_area_level_1"])
                            {
                                geo.administrativeArea = [address objectForKey:@"long_name"];
                            }
                            else if([[[address objectForKey:@"types"] firstObject] isEqualToString:@"locality"])
                            {
                                geo.locality = [address objectForKey:@"long_name"];
                            }
                        }
                        [geo hq_insert];
                        if (completion) {
                            completion(geo);
                        }
                    }
                    else
                    {
                        if (completion) {
                            completion(nil);
                        }
                    }
                }
                else
                {
                    if (completion) {
                        completion(nil);
                    }
                }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion) {
            completion(nil);
        }
    }];
}

- (void)updateLocation
{
    double lon;
    double lat;
    CLLocation *location;
    CLLocationAccuracy minAccuracy = 9999999999;
    for (CLLocation *loc in _locations)
    {
       CLLocationAccuracy accuracy = MAX(loc.horizontalAccuracy, loc.verticalAccuracy);
        if(minAccuracy > accuracy)
        {
            minAccuracy = accuracy;
            location = loc;
        }
    }
    self.standardLocation = location;
    wgs2gcj(location.coordinate.latitude,location.coordinate.longitude,&lat,&lon);
    location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lon) altitude:location.altitude horizontalAccuracy:kCLLocationAccuracyBest verticalAccuracy:kCLLocationAccuracyBest timestamp:location.timestamp];
    self.lastLocation = location;
    self.uploadError = NO;
    [_locations removeAllObjects];
    [self processLocationResponses];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    if(location)
    {
        [_locations addObject:location];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(updateLocation) withObject:nil afterDelay:1.0];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"位置更新错误: %@", [error localizedDescription]);
    self.uploadError = YES;
    [self processLocationResponses];
//    NSString *errorString;
    switch([error code]) {
        case kCLErrorDenied:
            //Access denied by user
//            errorString = Locale(@"general.dakaidingwei");
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:HQLAST_LOCATION];
            //Access to Location Services denied by user
            //Do something...
            break;
        case kCLErrorLocationUnknown:
            //Probably temporary...
//            errorString = Locale(@"general.locationbukeyong");
            //Location data unavailable
            //Do something else...
            break;
        default:
//            errorString = Locale(@"general.locationweizhicuowu") ;
            //An unknown error has occurred
            break;
    }
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:Locale(@"general.note") message:errorString delegate:self cancelButtonTitle:Locale(@"general.OK") otherButtonTitles:nil, nil];
//    [alert show];
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted)
    {
//        HQLogError(@"定位服务受限");
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    else if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
#else
    else if (status == kCLAuthorizationStatusAuthorized)
    {
#endif /* __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1 */
    }
        
}
    
@end

