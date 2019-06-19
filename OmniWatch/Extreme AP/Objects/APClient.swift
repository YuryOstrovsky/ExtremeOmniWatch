//
//  APClient.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-06.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import ObjectMapper

class APClient : Mappable {
    var apSerialNumber : String?
    var apName : String?

    // AB: We ONLY want to count as client if clientStatus == 'ACTIVE'
    var clientStatus : String?
    var clientRoleId : String?
    // roleid will be used to do another call to v1/services and look for the role to
    // retrieve the SSID this client is sitting on

    // Extend client information here...
    var role : String?
    var rss : Int?
    var deviceType : String?
    var manufacturer : String?
    var hostname : String?
    var protocolType : String?
    var channel : String?
    var macAddr : String?
    var ipAddr : String?
    var txRate : UInt32?  // for tx and rx
    var rxRate : UInt32? // in bps and need to divide by 1Million to get Mbps
    var osImage : UIImage? {
        get {
            if deviceType == nil {
                return nil
            }
            if deviceType == "Windows" {
                return UIImage(named: "windows")
            }
            if deviceType == "Android" {
                return UIImage(named: "android")
            }
            if manufacturer == nil {
                return nil
            }
            if manufacturer == "Apple, Inc." {
                return UIImage(named: "apple")
            }
            return nil
        }
    }
    
    // only for QA purpose
    static let demo : APClient = {
        var client = APClient()
        client.apName = "AP505_name"
        client.apSerialNumber = "123123123123123123"
        client.role = "ROLE"
        client.rss = 90
        client.hostname = "hostname.client"
        client.deviceType = "AP505"
        client.protocolType = "IEEE xx"
        client.channel = "12"
        client.macAddr = "AB:CD:EF:GH:IJ"
        client.txRate = 100
        client.rxRate = 200
        
        return client
    }()
    
    init() {}
    required init?(map: Map) {}

    func mapping(map: Map) {
        apSerialNumber     <- map["accessPointSerialNumber"]
        apName             <- map["accessPointName"]
        clientStatus       <- map["status"]
        clientRoleId       <- map["roleId"]

        role               <- map["role"]
        rss                <- map["rss"]
        deviceType         <- map["deviceFamily"]
        manufacturer       <- map["manufacturer"]
        hostname           <- map["dhcpHostName"]
        protocolType       <- map["protocol"]
        channel            <- map["channel"]
        txRate             <- map["transmittedRate"]
        rxRate             <- map["receivedRate"]
        macAddr            <- map["macAddress"]
        ipAddr             <- map["ipAddress"]
    }
}
