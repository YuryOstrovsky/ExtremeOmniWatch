//
//  UserManager.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-04.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import SwiftyJSON

struct UserParameters {
    var username       : String
    var password       : String
    var server         : String
    var beaconDistance : Double
    var units          : Int //0 = meters, 1 = feet

    init() {
        //username       = "readonly"
        username       = ""
        //password       = "readonly"
        password       = ""
        //server         = "ca-eca-p1.extremenetworks.com"
        server         = ""
//        server         = "extremeconnect.extremewireless.ca"
        beaconDistance = 10.0
        units          = 0
    }
}

class UserManager: NSObject {
    // Need to be stored in nsdefaults and reloaded
    private let defaults = UserDefaults.standard
    private let authKey = "auth"

    static let shared = UserManager()

    let operationQueue : OperationQueue
    var currentToken : AccessToken?

    // Should we make this private??
    var userParameters = UserParameters()

    override init() {
        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1;
        // Guarantees running one at a time, no ordering guarantee

        super.init()
    }

    func setUserParameters(uname : String?, passwd: String?, srv: String?) {
        guard let username = uname, let password = passwd else {
            debugLog("ERROR \(#function):\(#line) : Not able to set user parameters, empty values")
            return
        }

        userParameters.username = username
        userParameters.password = password
        if (srv != nil) {
            userParameters.server = srv!
        }
    }

    typealias OperationReadCompletionBlock = (_ token: AccessToken?, _ error: Error?) -> Void
    typealias OperationWriteCompletionBlock = (Error?) -> Void

    func read(_ completion: @escaping OperationReadCompletionBlock) {
        operationQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }

            if let currentToken = strongSelf.currentToken {

                DispatchQueue.main.async {

                    completion(currentToken, nil)
                }
            } else {

                if let dataRetrieved = UserDefaults().data(forKey: strongSelf.authKey),
                    let retrievedToken = NSKeyedUnarchiver.unarchiveObject(with: dataRetrieved) as? AccessToken {
                    strongSelf.currentToken = retrievedToken

                    DispatchQueue.main.async {
                        completion(retrievedToken, nil)
                    }
                } else {
                    // We have nothing to retrieve, error
                    debugLog("ERROR \(#function):\(#line) : auth key in nsdata not retrieved")
                    let error = NSError.init(domain: strongSelf.authKey, code: 1, userInfo: nil)

                    DispatchQueue.main.async {

                        completion(nil, error)
                    }
                }


            }
        }

    }

    func write(_ accessToken : AccessToken, completion: @escaping OperationWriteCompletionBlock) {

        operationQueue.addOperation { [weak self] in

            guard let strongSelf = self else {
                return
            }

            do {

                let dataToSave = try NSKeyedArchiver.archivedData(withRootObject: accessToken, requiringSecureCoding: false) as NSData
                strongSelf.defaults.set(dataToSave, forKey: strongSelf.authKey)

                strongSelf.currentToken = accessToken

                DispatchQueue.main.async {
                    completion(nil)
                }

            }
            catch {
                debugLog("ERROR \(#function):\(#line) : auth key not able to write to nsdata")
                let error = NSError.init(domain: strongSelf.authKey, code: 2, userInfo: nil)

                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
}
