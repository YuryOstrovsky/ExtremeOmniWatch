//
//  Timeseries.swift
//  Extreme AP
//
//  Created by Dmitry Voronov on 2019-05-14.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import ObjectMapper

class TimeseriesValues : Mappable {
    var value : Double?
    var timestamp : Double?
    
    // Extend client information here...
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        var valueStr : String?
        valueStr <- map["value"]
        value = Double(valueStr ?? "0")
        timestamp          <- map["timestamp"]
    }
}

class TimeseriesValuesArr : Mappable {
    var timeseriesValuesArr : [TimeseriesValues]?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        timeseriesValuesArr     <- map["values"]
    }
}

class Timeseries : Mappable {
    var stats : [TimeseriesValuesArr]?
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        stats <- map["statistics"]
    }
}
