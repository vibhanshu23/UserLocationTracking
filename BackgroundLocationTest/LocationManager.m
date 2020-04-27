//
//  LocationManager.m
//  BackgroundLocationTest
//
//  Created by Vibhanshu Jain on 21/04/20.
//  Copyright © 2020 Vibhanshu Jain. All rights reserved.
//

#import "LocationManager.h"

#define KEY_LAT @"LAT"
#define KEY_LONG @"LONG"
#define KEY_RADIUS @"RAD"

#define KEY_SAVED_LOCATION_ARRAY @"LocationArray"
#define KEY_SAVED_LOCATION_TIMESTAMP_ARRAY @"LocationTimeStampArray"
#define KEY_LOCATION_TRACKING_INTERVAL 100 //in meters
@import UserNotifications;

@interface LocationManager () <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSDate *lastTimestamp;

@end

@implementation LocationManager{
    BOOL previousState;
}



+(instancetype)sharedInstance{
    
    static id sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        LocationManager *instance = sharedInstance;
        [instance instantiateCurrentInstanceWithValues];
        
    });

    return sharedInstance;
}

-(void)instantiateCurrentInstanceWithValues{
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation; // you can use kCLLocationAccuracyHundredMeters to get better battery life
    self.locationManager.activityType = CLActivityTypeOtherNavigation;

    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    [self.locationManager startUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
    NSMutableDictionary *dict1 = [[NSMutableDictionary alloc] init];
    [dict1 setObject:@"28.60922025446421" forKey:KEY_LAT];
    [dict1 setObject:@"77.21193435728939" forKey:KEY_LONG];
    [dict1 setObject:@"0.7" forKey:KEY_RADIUS];
    
    NSMutableDictionary *dict2 = [[NSMutableDictionary alloc] init];
    [dict2 setObject:@"28.62263806150531" forKey:KEY_LAT];
    [dict2 setObject:@"77.21427605402764" forKey:KEY_LONG];
    [dict2 setObject:@"0.3" forKey:KEY_RADIUS];
    
    NSMutableDictionary *dict3 = [[NSMutableDictionary alloc] init];
    [dict3 setObject:@"26.838859" forKey:KEY_LAT];
    [dict3 setObject:@"75.793782" forKey:KEY_LONG];
    [dict3 setObject:@"0.2" forKey:KEY_RADIUS];
    
    self.arrHotspot = [[NSMutableArray alloc] init];
    [self.arrHotspot addObject:dict1];
    [self.arrHotspot addObject:dict2];
    [self.arrHotspot addObject:dict3];
}

+(NSDictionary *)createDictForLocation:(CLLocation *)location andRadius:(NSString *)strRadius{

    NSMutableDictionary *dict1 = [[NSMutableDictionary alloc] init];
    [dict1 setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude] forKey:KEY_LAT];
    [dict1 setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude] forKey:KEY_LONG];
    [dict1 setObject:strRadius forKey:KEY_RADIUS];
    return dict1;
}


-(void)startUpdatingUserLocation{
 
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
       [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert)
                             completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                 if (!error) {
                                     NSLog(@"request authorization succeeded!");
                                 }
                             }];
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

    if (status == kCLAuthorizationStatusDenied){
        NSLog(@"Location services are disabled in settings.");
    }
    else{
        // for iOS 8
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]){
            [self.locationManager requestAlwaysAuthorization];
        }
        // for iOS 9
        if ([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]){
            [self.locationManager setAllowsBackgroundLocationUpdates:YES];
        }

        [self.locationManager startUpdatingLocation];
    }
}

//- (void)setUpGeofences {
//    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(55.73599490252123,
//                                                               37.61229749323032);
//    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:center
//                                                        radius:100.0
//                                                    identifier:@"hotspot area1"];
//    [self.locationManager startMonitoringForRegion:region];
//    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
//    self.locationManager.allowsBackgroundLocationUpdates = YES;
//}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{

    CLLocation *mostRecentLocation = locations.lastObject;
    NSLog(@"Current location: %@ %@", @(mostRecentLocation.coordinate.latitude), @(mostRecentLocation.coordinate.longitude));
    
    [self addLocationToPList:mostRecentLocation];
    
//    NSDate *now = [NSDate date];
//    NSTimeInterval interval = self.lastTimestamp ? [now timeIntervalSinceDate:self.lastTimestamp] : 0;

    
    BOOL currentState = [self isLocationInHotspotArea:mostRecentLocation];
    
    if(currentState && currentState != previousState){
        [self displayNotif:@"*UNSAFE*  You entered hotspot" withBody:[NSString stringWithFormat:@"Current location: %@ %@", @(mostRecentLocation.coordinate.latitude), @(mostRecentLocation.coordinate.longitude)]];
    }
    else if(!currentState && currentState != previousState){
        [self displayNotif:@"*SAFE* You Are safe" withBody:[NSString stringWithFormat:@"Current location: %@ %@", @(mostRecentLocation.coordinate.latitude), @(mostRecentLocation.coordinate.longitude)]];
    }
    previousState = currentState;

}


- (void)addLocationToPList:(CLLocation *)location{
    
    
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    float batteryLevel = [[UIDevice currentDevice] batteryLevel];
    
    
    NSString *plistName = [NSString stringWithFormat:@"LocationArray.plist"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@", docDir, plistName];
    
    NSMutableDictionary *savedProfile = [[NSMutableDictionary alloc] initWithContentsOfFile:fullPath];
    
    NSMutableArray *savedUserLocationArray;
    NSMutableArray *savedUserLocationTimeStampArray;
    NSMutableArray *savedUserAppStateArray;
    NSMutableArray *savedUserBatteryLevelArray;

    if (!savedProfile) {
        savedProfile = [[NSMutableDictionary alloc] init];
        savedUserLocationArray =[[NSMutableArray alloc] init];
        savedUserLocationTimeStampArray = [[NSMutableArray alloc] init];
        savedUserAppStateArray = [[NSMutableArray alloc] init];
        savedUserBatteryLevelArray = [[NSMutableArray alloc] init];
    } else{

        savedUserLocationArray = [savedProfile objectForKey:KEY_SAVED_LOCATION_ARRAY];
        savedUserLocationTimeStampArray = [savedProfile objectForKey:KEY_SAVED_LOCATION_TIMESTAMP_ARRAY];
        savedUserAppStateArray =[savedProfile objectForKey:@"app"];
        savedUserBatteryLevelArray =[savedProfile objectForKey:@"battery"];
    }
    
    NSDictionary *dictLastLocation = [savedUserLocationArray lastObject];
    CLLocation *userLastLocation;
    if(dictLastLocation){
         userLastLocation = [[CLLocation alloc] initWithLatitude:[[dictLastLocation objectForKey:KEY_LAT] doubleValue] longitude:[[dictLastLocation objectForKey:KEY_LONG] doubleValue]];
    }
    
    if([userLastLocation distanceFromLocation:location] > KEY_LOCATION_TRACKING_INTERVAL || !userLastLocation){

        NSMutableDictionary *dictLocation = [[NSMutableDictionary alloc]init];
        [dictLocation setObject:[NSNumber numberWithDouble:location.coordinate.latitude]  forKey:KEY_LAT];
        [dictLocation setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:KEY_LONG];
        
        [savedUserLocationArray addObject:dictLocation];
        [savedUserLocationTimeStampArray addObject:location.timestamp];
        [savedUserAppStateArray addObject:[self appState]];
        [savedUserBatteryLevelArray addObject:[NSNumber numberWithFloat:batteryLevel]];
        
        [savedProfile setObject:savedUserLocationArray forKey:KEY_SAVED_LOCATION_ARRAY];
        [savedProfile setObject:savedUserLocationTimeStampArray forKey:KEY_SAVED_LOCATION_TIMESTAMP_ARRAY];
        [savedProfile setObject:savedUserAppStateArray forKey:@"app"];
        [savedProfile setObject:savedUserBatteryLevelArray forKey:@"battery"];
        
        if ([savedProfile writeToFile:fullPath atomically:true]) {
            NSLog(@"Data saved successfully" );
        }else{
            NSLog(@"Data couldn't saved" );
        }
    }
}

- (NSString *)appState {
    UIApplication* application = [UIApplication sharedApplication];

    NSString * appState;
    if([application applicationState]==UIApplicationStateActive)
        appState = @"UIApplicationStateActive";
    if([application applicationState]==UIApplicationStateBackground)
        appState = @"UIApplicationStateBackground";
    if([application applicationState]==UIApplicationStateInactive)
        appState = @"UIApplicationStateInactive";
    
    return appState;
}

- (void)displayNotif:(NSString *)title withBody:(NSString *)body {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = [NSString localizedUserNotificationStringForKey:title arguments:nil];
    content.body = [NSString localizedUserNotificationStringForKey:body
                                                         arguments:nil];
    content.sound = [UNNotificationSound defaultSound];

    /// 4. update application icon badge number
//    content.badge = @([[UIApplication sharedApplication] applicationIconBadgeNumber] + 1);
    // Deliver the notification in five seconds.
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger
                                                  triggerWithTimeInterval:1.f repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"OneSecond"
                                                                          content:content trigger:trigger];
    /// 3. schedule localNotification
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"add NotificationRequest succeeded!");
        }
    }];
}

-(BOOL)isLocationInHotspotArea:(CLLocation *)userLocation{
    
    BOOL toReturn = NO;
    
    for(NSDictionary *dictData in self.arrHotspot){
        
//        CLLocationCoordinate2D locationHotspotCenterCoordinate = CLLocationCoordinate2DMake([[dictData objectForKey:KEY_LAT] doubleValue], [[dictData objectForKey:KEY_LONG] doubleValue]);
        
        CLLocation *locationHotspot = [[CLLocation alloc] initWithLatitude:[[dictData objectForKey:KEY_LAT] doubleValue] longitude:[[dictData objectForKey:KEY_LONG] doubleValue]];
        
//        CLLocationCoordinate2D userLocationCoordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
        
        
        double hotspotRadius = [[dictData objectForKey:KEY_RADIUS] doubleValue];
        
        
        
        
        CLLocationDistance distanceInMeters = [locationHotspot distanceFromLocation:userLocation];

        NSLog(@"aaaa distance %f",distanceInMeters);
        if(distanceInMeters < hotspotRadius*1000){
            toReturn = YES;
            break;
        }
        
    }
    
    if([self.delegate respondsToSelector:@selector(didEnterHotspot:)]){
        [self.delegate didEnterHotspot:toReturn];
    }
    return toReturn;
}


@end
