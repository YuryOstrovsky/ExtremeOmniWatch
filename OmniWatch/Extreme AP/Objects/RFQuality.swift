//
//  RFQuality.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-08.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import ObjectMapper

class RFQualityValues : Mappable {
    var rfQualityRadio : String?
    var timestamp : Double?

    // Extend client information here...

    required init?(map: Map) {}

    func mapping(map: Map) {
        rfQualityRadio     <- map["value"]
        timestamp          <- map["timestamp"]
    }
}

class RFQualityArr : Mappable {
    var rfQualityVals : [RFQualityValues]?

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        rfQualityVals     <- map["values"]
    }
}

class RFQualityStatistics : Mappable {
    var rfQualityArr : [RFQualityArr]?

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        rfQualityArr <- map["statistics"]
    }
}
