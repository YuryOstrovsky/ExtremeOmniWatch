//
//  APStats.swift
//  Extreme AP
//
//  Created by test on 2019-05-31.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import ObjectMapper


class ChannelInfo : Mappable {
    typealias Entry = (index: Int, channel: String)
    var channelByRadioIndex : [Entry] = []
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        let rawDictionary = map.JSON
        channelByRadioIndex = rawDictionary.compactMap{ (key, value) -> Entry? in
            var splitKey = key.split(separator: "/")
            if splitKey.count > 0 {
                splitKey = String(splitKey[1]).split(separator: ".")
            }
            let index = Int(String(splitKey[0])) ?? 0
            guard let intValue = value as? Int else {return nil}
            let channel = Utils.renderChannelValue(channel: intValue)
            return (index, channel)
        }
    }
}

class PowerLevelInfo : Mappable {
    typealias Entry = (index: Int, powerLevel: String)
    var powerLevelsByRadioIndex : [Entry] = []
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        let rawDictionary = map.JSON
        powerLevelsByRadioIndex = rawDictionary.compactMap{ (key, value) -> Entry? in
            var splitKey = key.split(separator: "/")
            if splitKey.count > 0 {
                splitKey = String(splitKey[1]).split(separator: ".")
            }
            let index = Int(String(splitKey[0])) ?? 0
            let power = String(value as? Int ?? 0) + " dBm"
            return (index, power)
        }
    }
}
