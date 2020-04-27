//
//  ViewController.m
//  BackgroundLocationTest
//
//  Created by Vibhanshu Jain on 21/04/20.
//  Copyright © 2020 Vibhanshu Jain. All rights reserved.
//

#import "ViewController.h"
#import "LocationManager.h"
#import <MapKit/MapKit.h>


@interface ViewController ()<LocationManagerDelegate,MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *lblStaus;
@property (weak, nonatomic) IBOutlet MKMapView *vwMKMap;

@end

@implementation ViewController{
    CLLocation *currentUserLocation;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    LocationManager *mngr = [LocationManager sharedInstance];
    mngr.delegate = self;
    [mngr startUpdatingUserLocation];
    
    self.vwMKMap.showsUserLocation = YES;
    self.vwMKMap.delegate = self;
    
    [self markHotspotAreasWithArr:mngr.arrHotspot];

}
-(void)didEnterHotspot:(BOOL)didEnter{
    NSLog(@"aaaaa didEnterHotspot %d",didEnter);
    
    
    if(didEnter){
        self.lblStaus.text = @"*UNSAFE* \nDid Enter Hotspot";
        self.lblStaus.textColor = [UIColor redColor];
    }
    else{
        self.lblStaus.text = @"*SAFE* \nDid Exit Hotspot";
        self.lblStaus.textColor = [UIColor blackColor];

    }
}

-(void)markHotspotAreasWithArr:(NSArray*) arrHotspot{
    
    [self.vwMKMap removeOverlays:self.vwMKMap.overlays];
    [self.vwMKMap removeAnnotations:self.vwMKMap.annotations];
    
    for(NSDictionary *dictData in arrHotspot){
        
        CLLocation *locationHotspot = [[CLLocation alloc] initWithLatitude:[[dictData objectForKey:KEY_LAT] doubleValue] longitude:[[dictData objectForKey:KEY_LONG] doubleValue]];
        MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
        annotationPoint.coordinate = locationHotspot.coordinate;
        annotationPoint.title = @"HOTSPOT AREA";
        annotationPoint.subtitle = @"HOTSPOT AREA";
        [self.vwMKMap addAnnotation:annotationPoint];
        
        MKCircle *circle = [MKCircle circleWithCenterCoordinate:locationHotspot.coordinate radius:([[dictData objectForKey:KEY_RADIUS] doubleValue]*1000)];
        [self.vwMKMap addOverlay:circle];
        
    }
    
}

- (MKOverlayRenderer *)mapView:(MKMapView *)map viewForOverlay:(id <MKOverlay>)overlay
{
    MKCircleRenderer *circleView = [[MKCircleRenderer alloc] initWithOverlay:overlay];
//    circleView.strokeColor = [UIColor redColor];
    circleView.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.3];
    return circleView;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    mapView.centerCoordinate = userLocation.location.coordinate;
    currentUserLocation = userLocation.location;
}
- (IBAction)onClickAddHotspot:(id)sender {
    
    LocationManager *mngr = [LocationManager sharedInstance];
    NSMutableArray *arr = mngr.arrHotspot;
    NSDictionary *dict = [LocationManager createDictForLocation:currentUserLocation andRadius:@"0.2"];
    [arr addObject:dict];
    
    [self markHotspotAreasWithArr:mngr.arrHotspot];

}

@end
