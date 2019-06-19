//
//  IotAP.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-06.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import CoreLocation
import ObjectMapper

struct BeaconData {
    var uuid: UUID
    var major : CLBeaconMajorValue
    var minor : CLBeaconMinorValue
    var rssi  : Int
    var accuracy : CLLocationAccuracy
}

class IotAP : Mappable {
    var name: String?
    var serialNumber : String?
    var hardwareType : String?
    var platformName : String?
    var swVersion : String?
    var ipAddress : String?
    var macAddress : String?

    var iotiBeaconMajor : UInt16?
    var iotiBeaconMinor : UInt16?
    // Do not consider any APs unless they have this as true
    var iotEnabled : Bool = false
    var radios : [APRadioInfo] = []
    
    private let apAssets : [(key: String, image: UIImage?)] = [
        (key: "AP505i", UIImage(named: "AP505")),
        (key: "AP510i", UIImage(named: "AP510i")),
        (key: "AP510e", UIImage(named: "AP510e")),
        (key: "SA201", UIImage(named: "SA201")),
        // Parsing WiNG APs with Internal and External Antennas
        (key: "AP-7612", UIImage(named: "AP7612")),
        (key: "AP-7632-680B30", UIImage(named: "AP505")),
        (key: "AP-7662-680B30", UIImage(named: "AP7662i")),
        (key: "AP-8432", UIImage(named: "AP505")),
        (key: "AP-8533-68SB30", UIImage(named: "AP8533i")),
        (key: "AP-7532-67030", UIImage(named: "AP505")),

        (key: "AP-7632-680B40", UIImage(named: "AP510e")),
        (key: "AP-7662-680B40", UIImage(named: "AP7662e")),
        (key: "AP-8533-68SB40", UIImage(named: "AP8533e")),
        (key: "AP-7532-67040", UIImage(named: "AP510e")),

        (key: "AP510i", UIImage(named: "AP510")), // Double check
        (key: "AP3912", UIImage(named: "AP3912")),
        (key: "AP3915e", UIImage(named: "AP3915e")),
        (key: "AP3915i", UIImage(named: "AP3915i")),
        (key: "AP3916ic", UIImage(named: "AP3916c")),
        (key: "AP3917e", UIImage(named: "AP3917e")),
        (key: "AP3917k", UIImage(named: "AP3917e")), // Double check
        (key: "AP3917i", UIImage(named: "AP3917i")),
        (key: "AP3935", UIImage(named: "AP3935")),
        (key: "AP3965", UIImage(named: "AP3965")),
    ]

    /* Hardware types supported
 AP3912i-FCC
 AP3912i-ROW

 AP3915i-FCC
 AP3915e-FCC
 AP3915i-ROW
 AP3915e-ROW

 AP3916ic-FCC
 AP3916ic-ROW

 AP3917i-FCC
 AP3917i-ROW
 AP3917e-FCC
 AP3917e-ROW
 AP3917k-FCC
 AP3917k-ROW

 AP505i-FCC
 AP505i-WR

 AP510i-FCC
 AP510i-WR
 AP510e-FCC
 AP510e-WR.
 */

// WiNG Antennas Hardware Types -- currently using 505i for internal
    // and 510e for external

/* AP-7612-680B30-US    <<<<<< (internal antenna)
 AP-7612-680B30-WR      <<<<<< (internal antenna)
 AP-7612-680B30-IL    <<<<<< (internal antenna)

 AP-7632-680B30-US        <<<<<< (internal antenna)
 AP-7632-680B30-WR      <<<<<< (internal antenna)
 AP-7632-680B30-IL          <<<<<< (internal antenna)

 AP-7632-680B40-US        <<<<<< (external antenna)
 AP-7632-680B40-WR      <<<<<< (external antenna)
 AP-7632-680B40-IL          <<<<<< (external antenna)

 AP-7662-680B30-US        <<<<<< (internal antenna, outdoor)
 AP-7662-680B30-WR      <<<<<< (internal antenna,outdoor)
 AP-7662-680B30-IL          <<<<<< (internal antenna, outdoor)

 AP-7662-680B40-US        <<<<<< (external antenna,outdoor)
 AP-7662-680B40-WR      <<<<<< (external antenna,outdoor)
 AP-7662-680B40-IL          <<<<<< (external antenna,outdoor)

 AP-8432-680B30-US        <<<<<< (internal antenna)
 AP-8432-680B30-WR      <<<<<< (internal antenna)
 AP-8432-680B30-EU        <<<<<< (internal antenna)

 AP-8533-68SB30-US        <<<<<< (internal antenna)
 AP-8533-68SB30-WR      <<<<<< (internal antenna)
 AP-8533-68SB30-EU        <<<<<< (internal antenna)

 AP-8533-68SB40-US        <<<<<< (external antenna)
 AP-8533-68SB40-WR      <<<<<< (external antenna)
 AP-8533-68SB40-EU        <<<<<< (external antenna)

 AP-7532-67030-US          <<<<<< (internal antenna)
 AP-7532-67030-WR         <<<<<< (internal antenna)
 AP-7532-67030-IL            <<<<<< (internal antenna)
 AP-7532-67030-EU          <<<<<< (internal antenna)
 AP-7532-67030-1-WR     <<<<<< (internal antenna)

 AP-7532-67040-US          <<<<<< (external antenna)
 AP-7532-67040-WR         <<<<<< (external antenna)
 AP-7532-67040-EU          <<<<<< (external antenna)
 AP-7532-67040-1-WR     <<<<<< (external antenna)
 */
    
    // The next logic is not the best, but as I don't now
    // all the posible values, I adopt this a good aproach.
    var apImage : UIImage? {
        get {
            guard let hardwareType = hardwareType else { return nil }
            let image = apAssets.first { (apImageT) -> Bool in
                return hardwareType.contains(apImageT.key)
            }?.image
            return image
        }
    }
    
    // only for QA purpose
    static let demo : IotAP = {
        var ap = IotAP()
        ap.serialNumber = "43212343412"
        ap.hardwareType = ""
        ap.platformName = "AP3915i"
        ap.swVersion = ""
        ap.ipAddress = ""
        
        return ap
    }()
    
    init() { }
    required init?(map: Map) {

    }

    func mapping(map: Map) {
        name              <- map["apName"]
        serialNumber      <- map["serialNumber"]
        hardwareType      <- map["hardwareType"]
        platformName      <- map["platformName"] // 3915i, 3960
        swVersion         <- map["softwareVersion"]
        ipAddress         <- map["ipAddress"]
        macAddress        <- map["macAddress"]

        iotiBeaconMajor   <- map["iotiBeaconMajor"]
        iotiBeaconMinor   <- map["iotiBeaconMinor"]

        iotEnabled        <- map["iotEnabled"] // == HAS TO BE true to consider the AP
        radios            <- map["radios"]
        
        
    }
    
}

