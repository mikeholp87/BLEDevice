//
//  BLEPeripheral.m
//  Dude Where's My Car
//
//  Created by Michael Holp on 4/10/13.
//  Copyright (c) 2013 Flash Corp. All rights reserved.
//

#import "BLEPeripheral.h"

@implementation BLEPeripheral
@synthesize m, nDevices, sensorTags;

/****************************************************************************/
/*									Init									*/
/****************************************************************************/

+ (id)sharedInstance
{
	static BLEPeripheral *this	= nil;
    
	this = [[BLEPeripheral alloc] init];
    
	return this;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.m = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.nDevices = [[NSMutableArray alloc] init];
        self.sensorTags = [[NSMutableArray alloc] init];
	}
    return self;
}

#pragma mark - CBCentralManager delegate

- (void)startScanningForUUIDString
{
	[self.m scanForPeripheralsWithServices:nil options:nil];
}

- (void)stopScanning
{
	[self.m stopScan];
}

- (void)disconnectPeripheral:(CBPeripheral*)peripheral
{
	[self.m cancelPeripheralConnection:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Connection failed to peripheral: %@ with UUID: %@ with error: %@", [peripheral name], [peripheral UUID], [error localizedDescription]);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Disconnected from peripheral: %@ with UUID: %@",peripheral,peripheral.UUID);
    
    UIStoryboard *mainstoryboard;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        mainstoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    else
        mainstoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
    
    UINavigationController *DWMC_NavBar = [mainstoryboard instantiateViewControllerWithIdentifier:@"DWMC_NavController"];
    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:DWMC_NavBar];
    
    [[[UIAlertView alloc] initWithTitle:@"BlueTooth Device" message:[NSString stringWithFormat:@"Success! Your DWMC device is connected! %@", peripheral] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"BLE not supported !" message:[NSString stringWithFormat:@"CoreBluetooth return state: %d",central.state] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
    else {
        [central scanForPeripheralsWithServices:nil options:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Found a BLE Device : %@",peripheral);
    
    peripheral.delegate = self;
    [central connectPeripheral:peripheral options:nil];
    
    [self.nDevices addObject:peripheral];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral discoverServices:nil];
}

#pragma  mark - CBPeripheral delegate

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    BOOL replace = NO;
    BOOL found = NO;
    NSLog(@"Services scanned !");
    [self.m cancelPeripheralConnection:peripheral];
    for (CBService *s in peripheral.services) {
        NSLog(@"Service found : %@",s.UUID);
        if ([s.UUID isEqual:[CBUUID UUIDWithString:@"f000aa00-0451-4000 b000-000000000000"]])  {
            NSLog(@"This is a SensorTag !");
            found = YES;
        }
    }
    if (found) {
        // Match if we have this device from before
        for (int ii=0; ii < self.sensorTags.count; ii++) {
            CBPeripheral *p = [self.sensorTags objectAtIndex:ii];
            if ([p isEqual:peripheral]) {
                [self.sensorTags replaceObjectAtIndex:ii withObject:peripheral];
                replace = YES;
            }
        }
        if (!replace) {
            [self.sensorTags addObject:peripheral];
            //[self.tableView reloadData];
        }
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic %@ error = %@",characteristic,error);
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@ error = %@",characteristic,error);
}


#pragma mark - SensorTag configuration

-(NSMutableDictionary *) makeSensorTagConfiguration {
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    // First we set ambient temperature
    [d setValue:@"1" forKey:@"Ambient temperature active"];
    // Then we set IR temperature
    [d setValue:@"1" forKey:@"IR temperature active"];
    // Append the UUID to make it easy for app
    [d setValue:@"f000aa00-0451-4000 b000-000000000000"  forKey:@"IR temperature service UUID"];
    [d setValue:@"f000aa01-0451-4000 b000-000000000000" forKey:@"IR temperature data UUID"];
    [d setValue:@"f000aa02-0451-4000 b000-000000000000"  forKey:@"IR temperature config UUID"];
    // Then we setup the accelerometer
    [d setValue:@"1" forKey:@"Accelerometer active"];
    [d setValue:@"500" forKey:@"Accelerometer period"];
    [d setValue:@"f000aa10-0451-4000 b000-000000000000"  forKey:@"Accelerometer service UUID"];
    [d setValue:@"f000aa11-0451-4000 b000-000000000000"  forKey:@"Accelerometer data UUID"];
    [d setValue:@"f000aa12-0451-4000 b000-000000000000"  forKey:@"Accelerometer config UUID"];
    [d setValue:@"f000aa13-0451-4000 b000-000000000000"  forKey:@"Accelerometer period UUID"];
    
    //Then we setup the rH sensor
    [d setValue:@"1" forKey:@"Humidity active"];
    [d setValue:@"f000aa20-0451-4000 b000-000000000000"   forKey:@"Humidity service UUID"];
    [d setValue:@"f000aa21-0451-4000 b000-000000000000" forKey:@"Humidity data UUID"];
    [d setValue:@"f000aa22-0451-4000 b000-000000000000" forKey:@"Humidity config UUID"];
    
    //Then we setup the magnetometer
    [d setValue:@"1" forKey:@"Magnetometer active"];
    [d setValue:@"500" forKey:@"Magnetometer period"];
    [d setValue:@"f000aa30-0451-4000 b000-000000000000" forKey:@"Magnetometer service UUID"];
    [d setValue:@"f000aa31-0451-4000 b000-000000000000" forKey:@"Magnetometer data UUID"];
    [d setValue:@"f000aa32-0451-4000 b000-000000000000" forKey:@"Magnetometer config UUID"];
    [d setValue:@"f000aa33-0451-4000 b000-000000000000" forKey:@"Magnetometer period UUID"];
    
    //Then we setup the barometric sensor
    [d setValue:@"1" forKey:@"Barometer active"];
    [d setValue:@"f000aa40-0451-4000 b000-000000000000" forKey:@"Barometer service UUID"];
    [d setValue:@"f000aa41-0451-4000 b000-000000000000" forKey:@"Barometer data UUID"];
    [d setValue:@"f000aa42-0451-4000 b000-000000000000" forKey:@"Barometer config UUID"];
    [d setValue:@"f000aa43-0451-4000 b000-000000000000" forKey:@"Barometer calibration UUID"];
    
    [d setValue:@"1" forKey:@"Gyroscope active"];
    [d setValue:@"f000aa50-0451-4000 b000-000000000000" forKey:@"Gyroscope service UUID"];
    [d setValue:@"f000aa51-0451-4000 b000-000000000000" forKey:@"Gyroscope data UUID"];
    [d setValue:@"f000aa52-0451-4000 b000-000000000000" forKey:@"Gyroscope config UUID"];
    
    NSLog(@"%@",d);
    
    return d;
}

@end
