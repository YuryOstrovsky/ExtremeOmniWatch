//
//  APManager.swift
//  Extreme AP
//
//  Created by nifer on 16/04/2019.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

class APManager {
    
    static let shared = APManager()
    
    var currentAP : IotAP?
    var currentAPRFQuality : RFQualityValues?
    var currentAPRFQualityReport : [RFQualityValues]?
    var noisePerRadioR1 : NoisePerRadioValues?
    var noisePerRadioR2 : NoisePerRadioValues?
    var channelUtil24 : ChannelUtilizationValues?
    var channelUtilReport24 : [ChannelUtilizationInformation]?
    var channelUtil5 : ChannelUtilizationValues?
    var channelUtilReport5: [ChannelUtilizationInformation]?
    var throughputReport: [TimeseriesValues]?
    var channels: ChannelInfo?
    var powerLevels: PowerLevelInfo?
    var clientCount : Int?
    var clients : [APClient] = []
    var aps : [IotAP] = []
    var hud: MBProgressHUD?
    
    func clean() {
        currentAP                   = nil
        currentAPRFQuality          = nil
        currentAPRFQualityReport    = nil
        noisePerRadioR1             = nil
        noisePerRadioR2             = nil
        channelUtil24               = nil
        channelUtilReport24         = nil
        channelUtil5                = nil
        channelUtilReport5          = nil
        throughputReport            = nil
        clients                     = []
        clientCount                 = nil
        aps                         = []
    }
    
    func showHud(text: String, view: UIView) {
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        self.hud!.label.text = text
    }
    
    func setHud(text: String) {
        self.hud!.label.text = text;
    }
    
    func hideHud() {
        if self.hud != nil {
            self.hud!.hide(animated: true);
        }
    }
    
    /// Returns the ap with minor and major values from the current list of aps.
    func getAP(withMajor major: UInt16, andMinor minor: UInt16) -> IotAP? {
        return aps.first(where: { $0.iotiBeaconMajor == major && $0.iotiBeaconMinor == minor })
    }
    
    func findAP(inView view: UIView,_ completion: (( _ error: Error?) -> Void)?) {
        showHud(text: "Looking for Access Points...", view: view)

        // Clean if looking again
        APManager.shared.clean()

        NetworkController.shared.getIotProfile() { (profiles, error) in
            if error == nil {
                BLEManager.shared.scanBeacons(profiles: profiles, { (parameter1, error) in
                    if error == nil {
                        // We will not receive any more callbacks for this beacon
                        BLEManager.shared.informationAboutBeaconHandler = nil
                        self.setHud(text: "AP(s) found, loading details...")
                        NetworkController.shared.getAPs({ (iots, error) in
                            if error == nil {
                                if let iots = iots {
                                    APManager.shared.aps = iots.filter( { $0.iotEnabled } )
                                }
                                //only one AP, load it
                                if BLEManager.shared.currentBeaconData?.count == 1 {
                                    BLEManager.shared.selectedBeaconData = BLEManager.shared.currentBeaconData?[0]
                                    APManager.shared.retrieveAP({ (error) in
                                        self.hideHud()
                                        completion?(error)
                                    })
                                    return;
                                }
                            }
                            completion?(error)
                        })
                    } else {
                        self.hideHud()
                        completion?(error)
                    }
                })
            } else {
                self.hideHud()
                completion?(error)
            }
        }
    }
    
    func loadSelectedAP(_ completion: (( _ error: Error?) -> Void)?) {
        if BLEManager.shared.selectedBeaconData != nil {
            retrieveAP(completion)
        } else {
            let error = NSError(domain: "No AP selected",
                code: 1,
                userInfo: nil)
            completion?(error)
        }
    }
    
    private func retrieveAP(_ completion: (( _ error: Error?) -> Void)?) {
        let majorBeacon = BLEManager.shared.selectedBeaconData?.major ?? 0
        let minorBeacon = BLEManager.shared.selectedBeaconData?.minor ?? 0
        if let ap = APManager.shared.getAP(withMajor: majorBeacon, andMinor: minorBeacon) {
            APManager.shared.currentAP = ap
            let apSN = ap.serialNumber!
            print(APManager.shared.aps.toJSONString() ?? "")
            NetworkController.shared.getAPStations({ (clients, error) in
                // apSerialNumber
                if let allClients = clients {
                    for c in allClients {
                        if c.apSerialNumber == apSN {
                            debugLog("INFO \(#function):\(#line) : Found client for ap \(apSN) with client info \(c)")
                            if c.clientStatus == "ACTIVE" {
                                APManager.shared.clients.append(c)
                            } else {
                                debugLog("INFO \(#function):\(#line) : Client is not active, not adding to view")
                            }
                        }
                    }
                }
                APManager.shared.clientCount = APManager.shared.clients.count;
            
                self.setHud(text: "Loading AP stats...")
                NetworkController.shared.loadReportData(serialNumber: apSN){ [weak self] (error) in
                    if error == nil {
                        let reportData = NetworkController.shared.ReportData
                        
                        APManager.shared.channels = reportData.Channels
                        APManager.shared.powerLevels = reportData.PowerLevels
                        
                        APManager.shared.noisePerRadioR1 = reportData.NoisePerRadioR1.last
                        APManager.shared.noisePerRadioR2 = reportData.NoisePerRadioR2.last
                        
                        APManager.shared.channelUtilReport24 = reportData.ChannelUtilR1
                        if reportData.ChannelUtilR1.count > 0 {
                            APManager.shared.channelUtil24 = reportData.ChannelUtilR1.last?.values?.last
                        }
                        APManager.shared.channelUtilReport5 = reportData.ChannelUtilR2
                        if reportData.ChannelUtilR2.count > 0 {
                            APManager.shared.channelUtil5 = reportData.ChannelUtilR2.last?.values?.last
                        }
                        
                        
                        APManager.shared.currentAPRFQuality = reportData.RFQuality.last
                        APManager.shared.currentAPRFQualityReport = reportData.RFQuality
                        
                        APManager.shared.throughputReport = reportData.Throughput
                        
                        completion?(nil)
                    } else {
                        completion?(NSError(domain: error ?? "Error loading AP Report",
                            code: 1,
                            userInfo: nil))
                    }
                }
            })
        } else {
            let error = NSError(domain: "Couldn't find an AP with major: \(majorBeacon) and \(minorBeacon)",
                                code: 1,
                                userInfo: nil)
            completion?(error)
        }
    }
    
    
    private func checkCompletion(_ completion: (( _ error: Error?) -> Void)?) {
        if
            currentAP                   != nil &&
            currentAPRFQualityReport    != nil &&
            noisePerRadioR1             != nil &&
            noisePerRadioR2             != nil &&
            channelUtilReport24         != nil &&
            channelUtilReport5          != nil &&
            clientCount                 != nil &&
            throughputReport            != nil {
            self.setHud(text: "Stats loaded...")
            debugLog("All network calls succeeded")
            completion?(nil);
        } else {
            debugLog("Not all objects loaded")
        }
    }
    
}
