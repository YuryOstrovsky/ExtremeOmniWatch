//
//  ChannelUtilization.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-23.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import ObjectMapper

class ChannelUtilizationValues : Mappable {
    var channelUtil : String?
    var timestamp : Double?

    required init?(map: Map) {}

    func mapping(map: Map) {
        channelUtil     <- map["value"]
        timestamp       <- map["timestamp"]
    }
}

// Grab the last of these information arrays which holds the Available
class ChannelUtilizationInformation : Mappable {
    var values : [ChannelUtilizationValues]?

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        values <- map["values"]
    }
}

class ChannelUtilizationStatistics : Mappable {
    var channelUtilizationInfoArr : [ChannelUtilizationInformation]?

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        channelUtilizationInfoArr <- map["statistics"]
    }
}
