//
//  BLEManager.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-07.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth
import UIKit

extension Array where Element: Equatable {
    func removing(_ obj: Element) -> [Element] {
        return filter {$0 != obj}
    }
}

public extension UIAlertController {
    func show() {
        let win = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        win.rootViewController = vc
        win.windowLevel = UIWindow.Level.alert + 1
        win.makeKeyAndVisible()
        vc.present(self, animated: true, completion: nil)
    }
}

class BLEManager : NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate {
    
    var locationManager : CLLocationManager!
    var centralManager : CBCentralManager!
    var beaconRegionArr : [CLBeaconRegion]?

    var bluetoothAvailable : Bool = false
    var usingMeters : Bool = true // later for showing user preference onf eet vs meter selection

    var listOfRegions : [IotProfile]?
    var beaconsToRangeArr : [CLBeaconRegion]?
    
    var currentBeaconData : [BeaconData]?
    var selectedBeaconData : BeaconData?

    static let shared = BLEManager()

    // hsould have another constructor
    // which takes in the list of regions
    
    override init() {
        super.init()
        
        locationManager = CLLocationManager()
        for var region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true

        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        
        centralManager = CBCentralManager()
        centralManager.delegate = self

        // Initialize beacon region here
    }

    // Called from UI where user toggles the preference
    // of displaying beacon distance in meters vs feet

    func setMetersToFeet() {
        usingMeters = false
    }

    func setFeetToMeters() {
        usingMeters = true
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {

        switch central.state{
        case .poweredOn:
            debugLog("INFO \(#function):\(#line) : CoreBluetooth BLE state powered on \(central.state.rawValue)");
            break
        case .poweredOff:
            debugLog("ERROR \(#function):\(#line) : CoreBluetooth BLE state powered off \(central.state.rawValue)");
            break;
        case .unauthorized:
            debugLog("ERROR \(#function):\(#line) : CoreBluetooth BLE state is unauthorized \(central.state.rawValue)");
            break
        case .unknown:
            debugLog("ERROR \(#function):\(#line) : CoreBluetooth BLE state is unknown \(central.state.rawValue)");
            break;
        case .unsupported:
            debugLog("ERROR \(#function):\(#line) : CoreBluetooth BLE state is unsupported \(central.state.rawValue)");
            break;
        default:
            debugLog("ERROR \(#function):\(#line) : CoreBluetooth BLE state undefined \(central.state.rawValue)");
            break
        }

        bluetoothAvailable = central.state == .poweredOn

        if (central.state != .poweredOn) {
            let alertController = UIAlertController(title: "Bluetooth Disabled", message: "OmniWatch requires Bluetooth to be enabled. App will not find any AP without it!", preferredStyle: UIAlertController.Style.alert);
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default))
            alertController.show()
            
        }
    }
    
    func isBluetoothAvailable() -> Bool {
        return centralManager.state == .poweredOn
    }

    func escalateLocationServiceAuthorization() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }

    func rangingStoppedSuccessfully() {

    }

    func disableAllRanging() {
        if locationManager.rangedRegions.isEmpty {
            print("No regions are being ranged, nothing to disable")
            return
        }

        guard let beaconRegions = beaconsToRangeArr else {
            print("No regions in beacon region array, nothing to disable ranging on")
            return
        }

        for region in beaconRegions {
            locationManager.stopRangingBeacons(in: region)
            locationManager.stopMonitoring(for: region)

            rangingStoppedSuccessfully()
            beaconsToRangeArr = beaconsToRangeArr?.removing(region)

            print("Successfully disabled ranging and monitoring for region \(region)")
        }
    }

    func failedToStartRanging() {

    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status : CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            print("Location access is either restricted or denied, cannot look for beacons!")
            // Need to disable until we get permission again
            failedToStartRanging()
            break

        case .authorizedWhenInUse:
            print("Location access is granted when app in use")
            // Ask for more - ask to always be able to use it
            escalateLocationServiceAuthorization()
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
             if CLLocationManager.isRangingAvailable() {
             startScanning()
             }
             }
            break

            // AB: FIX THIS - authorized always is having issues with plist
        // https://stackoverflow.com/questions/44424092/location-services-not-working-in-ios-11/50733860#50733860
        case .authorizedAlways:
            print("Location access is always granted!")
            // All good, now lets continue
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    startScanning()
                }
            }
            break


        case .notDetermined:
            print("Location access is not determined, asking")

            locationManager.requestWhenInUseAuthorization()
            break

        default:
            print("Location access is unknown, asking")

            locationManager.requestWhenInUseAuthorization()
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("We have started monitoring for region \(region)")
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring has failed for region \(region!) with error \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print("Did determine state \(state.rawValue) for region \(region)")

        guard state == CLRegionState.inside else {
            print("We are not inside the region, do nothing")
            return
        }

        debugLog("INFO \(#function):\(#line) : We are starting to range for beacons with region \(region)")
        if region is CLBeaconRegion {
            turnOnRanging(beaconRegion: region as! CLBeaconRegion)

            if (beaconsToRangeArr?.append(region as! CLBeaconRegion)) == nil {
                beaconsToRangeArr = [region as! CLBeaconRegion]
            }
        }

    }

    func turnOffRegionMonitoring() {
        guard let regions = beaconRegionArr else {
            debugLog("ERROR \(#function):\(#line) : No regions to stop monitoring!")
            return
        }

        for region in regions {
            debugLog("INFO \(#function):\(#line) : Stopping monitoring for region \(region)")
            locationManager.stopMonitoring(for: region)

            beaconRegionArr = beaconRegionArr?.removing(region)
        }
    }

    func addRegionToMonitor(beaconRegion: CLBeaconRegion) {
        beaconRegion.notifyEntryStateOnDisplay = true;
        
        if locationManager.monitoredRegions.contains(beaconRegion) {
            print("Already monitoring region \(beaconRegion)")
            return
        }

        locationManager.startMonitoring(for: beaconRegion)
        print("Added beacon region to Monitor : \(beaconRegion)")

        // If it is nil, go put in the first element
        if (beaconRegionArr?.append(beaconRegion)) == nil {
            beaconRegionArr = [beaconRegion]
        }
    }

    func turnOnRegionMonitoring() {
        //let proximityUUID = UUID(uuidString: "0b2d7e83-3cd7-4df8-8ee8-dbb201a22e72")
        //let beaconID = "com.extreme.myBeaconRegion"

        guard let regions = listOfRegions else {
            debugLog("ERROR \(#function):\(#line) : No regions to monitor for!")
            return
        }

        for region in regions {
            guard let uuidStr = region.uuid, let uuid = UUID(uuidString: uuidStr) else {
                debugLog("ERROR \(#function):\(#line) : No UUID for this region!")
                continue
            }

            guard let id = region.id else {
                debugLog("ERROR \(#function):\(#line) : No ID for this region!")
                continue
            }

            let beaconRegion = CLBeaconRegion(proximityUUID: uuid /*proximityUUID!*/, identifier: id/*beaconID*/)
            // Note this option will notify the user they entered into a beacon region
            // EVEN if their app is not launched ** need to have background always location services on
            // App will go to the didDetermineState cb but it will not bring the
            // app into the foreground. Here we can push notify the user that they
            // have a beacon in range!

            beaconRegion.notifyEntryStateOnDisplay = true;
            
            if locationManager.monitoredRegions.contains(beaconRegion) {
                print("Already monitoring region \(beaconRegion)")
                continue
            }

            locationManager.startMonitoring(for: beaconRegion)
            print("Monitoring turned on for beacon region : \(beaconRegion)")

            // If it is nil, go put in the first element
            if (beaconRegionArr?.append(beaconRegion)) == nil {
                beaconRegionArr = [beaconRegion]
            }
        }
    }

    func turnOnRanging(beaconRegion: CLBeaconRegion) {
        //let proximityUUID = UUID(uuidString: "0b2d7e83-3cd7-4df8-8ee8-dbb201a22e72")
        //let beaconID = "com.extreme.myBeaconRegion"

        //beaconRegion = CLBeaconRegion(proximityUUID: proximityUUID!, identifier: beaconID)
        locationManager.startRangingBeacons(in: beaconRegion)
        print("Ranging turned on for beacon region : \(beaconRegion)")
    }

    func startScanning() {
        print("We are starting to scan now!")

        if !CLLocationManager.locationServicesEnabled() {
            print("Could not turn on monitoring, location services are not enabled")
            failedToStartRanging()
            return
        }

        if !CLLocationManager.isRangingAvailable() {
            print("Could not turn on ranging, it is not available")
            failedToStartRanging()
            return
        }

        if !locationManager.rangedRegions.isEmpty {
            print("Ranging is already on, nothing to start")
            return
        }

        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            print("Only when in use")
            escalateLocationServiceAuthorization()
            turnOnRegionMonitoring()
            break
        case .authorizedAlways:
            turnOnRegionMonitoring()
            print("Ok to proceed turning it on, got the right location permissions")
            break
        case .denied, .restricted:
            print("We do not have the proper location access to turn on ranging")
        case .notDetermined:
            print("Not sure on the location access privileges, asking user now")
            locationManager.requestWhenInUseAuthorization()
        default:
            print("Unknown location access privileges, asking user now")
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // #1# The main idea is return to the LoginVC with the information needed (witch
    // I don't know) so I believe that we can create a handler like the above:
    typealias BeaconDataResponse = (_ beaconData: [BeaconData?], _ error: Error?) -> Void
    var informationAboutBeaconHandler : BeaconDataResponse?
    
    // This function will need to go to a view controller
    func displayInformationAboutBeacon(uuid: UUID, major: CLBeaconMajorValue, minor: CLBeaconMinorValue, rssi: Int, accuracy : CLLocationAccuracy) -> BeaconData {

        if (!usingMeters) {
            // convert to feet
            let accuracyFeet = Measurement(value: accuracy, unit: UnitLength.feet)

           // ... do something with it here

            
        }
        
        return BeaconData(uuid: uuid, major: major, minor: minor, rssi: rssi, accuracy: accuracy)
    }
    
    // #3# I create function to handle all the calls and use the handler:
    func scanBeacons(profiles: [IotProfile]?,_ completion: BeaconDataResponse?) {
        informationAboutBeaconHandler = completion
        self.listOfRegions = profiles
#if targetEnvironment(simulator)
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (timer) in
            self.currentBeaconData = [
                self.displayInformationAboutBeacon(uuid: UUID(uuidString: "0B2D7E83-3CD7-4DF8-8EE8-DBB201A22E72")!,
                                                   major: 10,
                                                   minor: 62,
                                                   rssi: -71,
                                                   accuracy : 3.1)
            ]
            
            self.informationAboutBeaconHandler?(self.currentBeaconData!, nil)
            
        }
#else
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            if CLLocationManager.isRangingAvailable() {
                startScanning()
            }
        }
#endif
    }

    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            disableAllRanging()
            self.currentBeaconData = []
            for beacon in beacons {
                let major = CLBeaconMajorValue(truncating: beacon.major)
                let minor = CLBeaconMinorValue(truncating: beacon.minor)
                var accuracy = CLLocationAccuracy(beacon.accuracy)
                accuracy = round(10.0 * accuracy) / 10.0
                let rssi = beacon.rssi
                let UUID = beacon.proximityUUID
                
                if rssi == 0 {
                    print("Skipping a beacon with rssi value \(rssi). Incomplete packet that we are discarding (uuid: \(UUID) major: \(major) minor: \(minor))")
                    continue
                }
                
                var distance = UserManager.shared.userParameters.beaconDistance
                if UserManager.shared.userParameters.units == 1 {
                    distance = Measurement(value: distance, unit: UnitLength.feet).converted(to: .meters).value
                    debugLog("Using feet, converted \(UserManager.shared.userParameters.beaconDistance) to \(distance)")
                }
                if (accuracy > distance) {
                    print("Skipping a beacon with distance \(accuracy), further than the max \(UserManager.shared.userParameters.beaconDistance). (uuid: \(UUID) major: \(major) minor: \(minor))")
                    continue
                }
                
                
                print("Found a good beacon with the following data uuid : \(UUID), major : \(major), minor : \(minor), rssi : \(rssi), accuracy : \(accuracy) meters")
                
                
                // Used for later showing up real-time values in the UI
                let beaconData = displayInformationAboutBeacon(uuid: UUID, major: major, minor: minor, rssi: rssi, accuracy: accuracy)
                currentBeaconData?.append(beaconData)
            }
            
            if currentBeaconData?.count == 0 {
                turnOnRanging(beaconRegion: region)
            } else {
                debugLog("Before Sort: \(currentBeaconData)");
                currentBeaconData = currentBeaconData?.sorted(by: {
                    return $0.accuracy < $1.accuracy
                })
                debugLog("After Sort: \(currentBeaconData)");
                informationAboutBeaconHandler?(self.currentBeaconData!, nil)
            }
        } else {
            debugLog("ERROR \(#function):\(#line) : Malformed cb to didRangeBeacons, disregarding")
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("We have entered region \(region)")
        // Check which Beacon type -- UUID
        // startRangingBeacons
        // We are inside a region right now so start ranging beacons for this UUID
        debugLog("INFO \(#function):\(#line) : We are starting to range for beacons with region \(region)")
        if region is CLBeaconRegion {
            turnOnRanging(beaconRegion: region as! CLBeaconRegion)

            if (beaconsToRangeArr?.append(region as! CLBeaconRegion)) == nil {
                beaconsToRangeArr = [region as! CLBeaconRegion]
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("We have exited region \(region)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Mgr failed with error \(error)")
    }
    
}
