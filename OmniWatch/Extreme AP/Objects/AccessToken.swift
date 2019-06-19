//
//  AccessToken.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-06.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import ObjectMapper

class AccessToken : NSObject, NSCoding, Mappable {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(accessToken, forKey: "accessToken")
        aCoder.encode(tokenType, forKey: "tokenType")
        aCoder.encode(expiresIn, forKey: "expiresIn")
        aCoder.encode(idleTimeout, forKey: "idleTimeout")
        aCoder.encode(refreshToken, forKey: "refreshToken")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init()

        accessToken = aDecoder.decodeObject(forKey: "accessToken") as? String
        tokenType = aDecoder.decodeObject(forKey: "tokenType") as? String
        expiresIn = aDecoder.decodeObject(forKey: "expiresIn") as? Int
        idleTimeout = aDecoder.decodeObject(forKey: "idleTimeout") as? Int
        refreshToken = aDecoder.decodeObject(forKey: "refreshToken") as? String
    }

    //NSCopying {
    /*func copy(with zone: NSZone? = nil) -> Any {
        let copy = AccessToken.init(with: zone) as! AccessToken
        copy.accessToken = accessToken
        copy.tokenType = tokenType
        copy.expiresIn = expiresIn
        copy.idleTImeout = idleTimeout
        copy.refreshToken = refreshToken
    }*/

    var accessToken  : String?
    var tokenType    : String?
    var expiresIn    : Int?
    var idleTimeout  : Int?
    var refreshToken : String?

    /*"access_token" : "...",
    "token_type" : "...",
    "expires_in" : 12345,
    "idle_timeout" : 12345,
    "refresh_token" : "...",
    "adminRole" : "GUEST"
*/
    override init() {}

    required init?(map: Map) {

    }

    func mapping(map: Map) {
        accessToken  <- map["access_token"]
        tokenType    <- map["token_type"]
        expiresIn    <- map["expires_in"]
        idleTimeout  <- map["idle_timeout"]
        refreshToken <- map["refresh_token"]

    }

    // AB: Verify what the header looks like
    var header: [String: String] {
        guard let accessTkn = accessToken else {
            debugLog("ERROR \(#function):\(#line) : Unable to generate a header from current authentication")
            return [:]
        }
       /* get {
            do {
                //var authHeader = [String: String]()
               // authHeader["token"] = accessToken
               // let authJsonData = try JSONSerialization.data(withJSONObject: accessToken, options: [])
                //let authJson = String(data: authJsonData, encoding: .ascii)!*/
            return ["Content-Type": "application/json" ,
                    "Accept": "application/json",
                    "Authorization" : "Bearer \(accessTkn)"]
           /* } catch {
                debugLog("ERROR \(#function):\(#line) : Unable to generate a header from current authentication")
                return [:]
            }
         }
        */
    }
}
