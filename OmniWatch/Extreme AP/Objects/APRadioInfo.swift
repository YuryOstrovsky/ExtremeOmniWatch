//
//  APInfo.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-06.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import ObjectMapper

class APRadioInfo : Mappable {
    var channel      : String?
    var channelWidth : String?
    var mode         : String?
    var txPower      : Int = 0
    var index        : Int = 0

    required init?(map: Map) {
        
    }

    func mapping(map: Map) {
        channel           <- map["channel"]
        mode              <- map["mode"]
        txPower           <- map["txPower"]
        index             <- map["radioIndex"]
    }
}
