//
//  IotProfile.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-08.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import ObjectMapper

// Example sub classed object mapping
// https://github.com/tristanhimmelman/AlamofireObjectMapper

/*class iBeaconUUID : Mappable {
    var uuid : String?

    required init?(map: Map) {}

    func mapping(map: Map) {
        uuid <- map["uuid"]
    }
} */ // Do not need this atm

class IotProfile : Mappable {
    var id : String?
    var uuid : String? // could be of type uuidArr : [iBeaconUUID]


    required init?(map: Map) {}

    func mapping(map: Map) {
        id       <- map["id"]
        uuid  <- map["iBeaconAdvertisement.uuid"]
    }
}
