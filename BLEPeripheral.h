//
//  BLEPeripheral.h
//  Dude Where's My Car
//
//  Created by Michael Holp on 4/10/13.
//  Copyright (c) 2013 Flash Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEDevice.h"
#import "SensorTagApp.h"

@interface BLEPeripheral : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (strong,nonatomic) CBCentralManager *m;
@property (strong,nonatomic) NSMutableArray *nDevices;
@property (strong,nonatomic) NSMutableArray *sensorTags;

-(NSMutableDictionary *) makeSensorTagConfiguration;

- (void)startScanningForUUIDString;
+ (id) sharedInstance;


@end
