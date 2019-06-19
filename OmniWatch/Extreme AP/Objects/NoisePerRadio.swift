//
//  NoisePerRadio.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-08.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import ObjectMapper

class NoisePerRadioValues : Mappable {
    var noisePerRadio : String?
    var timestamp : Double?

    required init?(map: Map) {}

    func mapping(map: Map) {
        noisePerRadio     <- map["value"]
        timestamp     <- map["timestamp"]
    }
}

class NoisePerRadioInformation : Mappable {
    var values : [NoisePerRadioValues]?

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        values <- map["values"]
    }
}

class NoisePerRadioStatistics : Mappable {
    var noisePerRadioArr : [NoisePerRadioInformation]?

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        noisePerRadioArr <- map["statistics"]
    }
}

