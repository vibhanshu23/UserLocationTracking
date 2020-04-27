//
//  LocationManager.h
//  BackgroundLocationTest
//
//  Created by Vibhanshu Jain on 21/04/20.
//  Copyright © 2020 Vibhanshu Jain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "UIKit/UIKit.h"

#define KEY_LAT @"LAT"
#define KEY_LONG @"LONG"
#define KEY_RADIUS @"RAD"

NS_ASSUME_NONNULL_BEGIN

@protocol LocationManagerDelegate <NSObject>
@optional
- (void)didEnterHotspot:(BOOL)didEnter;

@end

@interface LocationManager : NSObject
+(instancetype)sharedInstance;
-(void)startUpdatingUserLocation;
+(NSDictionary *)createDictForLocation:(CLLocation *)location andRadius:(NSString *)strRadius;
@property (strong, nonatomic) NSMutableArray *arrHotspot;
@property (strong, nonatomic) id <LocationManagerDelegate> delegate;
-(void)instantiateCurrentInstanceWithValues;

@end

NS_ASSUME_NONNULL_END
