//
//  ViewController.m
//  HQLocationManagerDemo
//
//  Created by 杨洋 on 10/04/2017.
//  Copyright © 2017 solot. All rights reserved.
//

#import "ViewController.h"
#import "HQLocationManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[HQLocationManager sharedInstance]startUpdatingLocationWithCallback:^(CLLocation *location, HQLocationServicesState status) {
        [HQLocationManager reverseGeocodeLocation:location completion:^(HQGeocodeModel *geocode) {
            
        }];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
