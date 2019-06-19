//
//  BackendAuth.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-02.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON
import Alamofire

class NetworkController {
    static let shared = NetworkController()

    // AB: How to set up insecure type connection - no cert checking
    let manager : Alamofire.SessionManager = {
        // Create the server trust policies
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
            "*:5825": .disableEvaluation
        ]
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        let manager = Alamofire.SessionManager (
            configuration: URLSessionConfiguration.default
            // Note: took out security of certificate verification
            // only signed certificates accepted for now
            //serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
        )
        
        return manager
    }()

    private var currentAuth : AccessToken? {
        get {
            let auth = UserManager.shared.currentToken
            if (auth == nil) {
                print("Missing current authentication token for cloud!")
            }
            return auth
        }
    }

    // AB: This is currently hardcoded in userparams.server to be this default
    // take out this variable down the road.

    var baseURL = UserManager.shared.userParameters.server
    //"https://extremeconnect.extremewireless.ca:5825/management"
    
    
    private var reportDataJSON: Any?

    init() {
        let delegate: Alamofire.SessionDelegate = manager.delegate
        delegate.sessionDidReceiveChallenge = { session, challenge in
            var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                disposition = URLSession.AuthChallengeDisposition.useCredential
                credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            } else {
                if challenge.previousFailureCount > 0 {
                    disposition = .cancelAuthenticationChallenge
                } else {
                    credential = self.manager.session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
                    if credential != nil {
                        disposition = .useCredential
                    }
                }
            }
            return (disposition, credential)
        }
    }

    struct Endpoints {
        static let postTokenEndpoint         = "/management/v1/oauth2/token"
        static let postTokenRefreshEndpoint  = "/management/v1/oauth2/refreshToken"
        static let getIotProfileEndpoint     = "/management/v3/iotprofile"
        static let getAPsEndpoint            = "/management/v1/aps"
        static let getAPStationsEndpoint     = "/management/v1/stations"
        static let getReportApsEndpoint      = "/management/v1/report/aps"

        struct APReports {
            static let reportAll = "?duration=3H&widgetList=noisePerRadio%257Call%252CrfQuality%257Call%252CrfQuality%257Call%252CchannelUtilization2_4%252CchannelUtilization5%252CthroughputReport%257Call"
            static let reportApsNoisePerRadio   = "?duration=3H&widgetList=noisePerRadio%257Call"
            static let reportApsRFQuality       = "?duration=3H&widgetList=rfQuality%257Call"
            static let reportChannelUtilization = "?duration=3H&resolution=15&widgetList=channelUtilization2_4%252CchannelUtilization5"
            static let reportThroughput = "?duration=3H&resolution=15&widgetList=throughputReport%257Call"
        }
    }
    
    struct ReportDataStruct {
        var NoisePerRadioR1: [NoisePerRadioValues] = []
        var NoisePerRadioR2: [NoisePerRadioValues] = []
        var ChannelUtilR1: [ChannelUtilizationInformation] = []
        var ChannelUtilR2: [ChannelUtilizationInformation] = []
        var RFQuality: [RFQualityValues] = []
        var Throughput: [TimeseriesValues] = []
        var Channels: ChannelInfo?
        var PowerLevels: PowerLevelInfo?
    }
    
    var ReportData = ReportDataStruct()

    struct ErrorCodes {
        // list 500, 401, etc here
        static let unregistered = 0 //blah
    }

    // Fix these data type outputs!
    typealias PostTokenResponse = (_ token : AccessToken?, _ responseError: Error?) -> Void

    // AB: Verify what we get back here
    typealias PostTokenRefreshResponse = (_ responseError: Error?) -> Void
    typealias GetAPInfoWithSerialResponse = (_ apRadio1 : APRadioInfo?, _ apRadio2 : APRadioInfo?, _ responseError: Error?) -> Void
    typealias GetAPsResponse = ( _ aps : [IotAP]?, _ responseError: Error?) -> Void
    typealias GetIotProfileResponse = (_ iotProfile : [IotProfile]?, _ responseError: Error?) -> Void
    typealias GetAPStationsResponse = (_ apClients : [APClient]?, _ responseError: Error?) -> Void

    typealias GetReportApsNoisePerRadioEndpointResponse = (_ noisePerRadioR1 : NoisePerRadioValues?, _ noisePerRadioR2 : NoisePerRadioValues?, _ responseError: Error?) -> Void
    typealias GetReportsEndpointResponse = (_ reports : Any?, _ responseError: String?) -> Void
    typealias GetReportApsRFQualityReportResponse = (_ rfQuality : RFQualityArr?, _ responseError: Error?) -> Void
    typealias GetReportApsRFQualityEndpointResponse = (_ rfQuality : RFQualityValues?, _ responseError: Error?) -> Void
    typealias GetReportApsChannelUtilizationReportResponse = (_ channelUtil24 : ChannelUtilizationStatistics?, _ channelUtil5 : ChannelUtilizationStatistics?, _ responseError: Error?) -> Void
    typealias GetReportApsChannelUtilizationEndpointResponse = (_ channelUtil24 : ChannelUtilizationValues?, _ channelUtil5 : ChannelUtilizationValues?, _ responseError: Error?) -> Void
    typealias GetReportApsThroughputResponse = (_ throughput : TimeseriesValuesArr?, _ responseError: Error?) -> Void

    func postToken(_ serverResponse: PostTokenResponse?) {
        // Make this check nicer..
        debugLog("INFO \(#function):\(#line) : requesting new token")
        
        baseURL = UserManager.shared.userParameters.server
        
        if !baseURL.contains(":5825") {
            baseURL = baseURL + ":5825"
        }
        if !baseURL.lowercased().starts(with: "https://") {
            baseURL = "https://" + baseURL
        }
        
        let userParameters : [String : Any] = [
            "grantType" : "password",
            "userId" : UserManager.shared.userParameters.username,
            "password" : UserManager.shared.userParameters.password,
            "scope" : "myScope",
        ]
        
        manager.request(baseURL + Endpoints.postTokenEndpoint, method: .post, parameters: userParameters,
                        encoding: JSONEncoding.default, headers: ["Content-Type": "application/json"]
            ).validate(statusCode: 200..<300).validate(contentType: ["application/json"]).responseJSON { response in
            switch response.result {
            case .success(let value):
                print("PostToken success")
                if let json = value as? [String: Any], let token = AccessToken(JSON: json) {
                    print("\(json)")
                    print("\(token.accessToken)")
                    // Update current token
                    UserManager.shared.currentToken =  token
                    serverResponse!(token, nil)
                }
                else {
                    debugLog("ERROR \(#function):\(#line) : Unable to get JSON out of PostToken")
                    serverResponse!(nil, nil)
                }
            case .failure:
                // Need to display the error somehow here...
                // Can parse for known errors here
                debugLog("ERROR \(#function):\(#line) : PostToken failure with error \(String(describing: response.error))")
                serverResponse!(nil, response.error)
            }
        }
    }

    // AB: fix params here
    func postTokenRefresh(_ serverResponse: PostTokenRefreshResponse?) {
        debugLog("INFO \(#function):\(#line) : refreshing token")
        
        guard let auth = currentAuth, let refreshTkn = auth.refreshToken else {
            debugLog("ERROR \(#function):\(#line) : No current auth, unable to post refresh token")
            return
        }

        let refreshParameters : [String: Any] = [
            "grantType" : "refresh_token",
            "scope" : "myScope",
            "refreshToken" : refreshTkn,
        ]

        manager.request(baseURL + Endpoints.postTokenRefreshEndpoint, method: .post, parameters: refreshParameters, headers: auth.header).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                print("PostTokenRefresh success")
                if let json = value as? [String: Any], let token = AccessToken(JSON: json) {
                    UserManager.shared.currentToken = token
                    serverResponse!(nil)
                } else {
                    debugLog("ERROR \(#function):\(#line) : Unable to get JSON out of PostTokenRefresh")
                    let error = NSError(domain: "Unable to get JSON out of PostTokenRefresh", code: 4000, userInfo: nil)
                    serverResponse!(error)
                }
            case .failure:
                // Need to display the error somehow here...
                // Can parse for known errors here
                debugLog("ERROR \(#function):\(#line) : PostTokenRefresh failure with error \(String(describing: response.error))")
                serverResponse!(response.error)
            }
        }
    }

    func getAPInfoWithSerial(withSerial: String, _ serverResponse: GetAPInfoWithSerialResponse?) {
        guard let auth = currentAuth else {
            debugLog("ERROR \(#function):\(#line) : No current auth, unable to get ap info with serial")
            return
        }

        let url : String = baseURL + Endpoints.getAPsEndpoint + "/" + withSerial

        manager.request(url, method: .get, parameters: ["brief": "false"], headers: auth.header).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                print("GetAPInfoWithSerial success")
                if let valueDic = value as? [String: Any],
                    let radioOne = Mapper<APRadioInfo>().mapArray(JSONObject: valueDic["radios"])?[0],
                    let radioTwo = Mapper<APRadioInfo>().mapArray(JSONObject: valueDic["radios"])?[1] {

                    serverResponse!(radioOne, radioTwo, nil)
                } else {
                    debugLog("ERROR \(#function):\(#line) : Unable to get JSON out of GetAPInfoWithSerial")
                    serverResponse!(nil, nil, nil)
                }
            case .failure(_):
                debugLog("ERROR \(#function):\(#line) : GetAPInfoWithSerial failure with error \(String(describing: response.error))")
                serverResponse!(nil, nil, response.error)
            }

        }
    }

    // Retrieves list of APs and should parse the ones that have iotEnabled = true
    // Build the DB based on this
    func getAPs(isRetry: Bool = false, _ serverResponse: GetAPsResponse?) {
        guard let auth = currentAuth else {
            debugLog("ERROR \(#function):\(#line) : No current auth, unable to get aps")
            return
        }

        manager.request(baseURL + Endpoints.getAPsEndpoint, method: .get, parameters: ["brief": "false"], headers: auth.header).validate().responseJSON()
            { response in
            switch response.result {
            case .success(let value):
                let apArr = Mapper<IotAP>().mapArray(JSONObject: value)
                serverResponse!(apArr ?? [], nil)
            case .failure(_):
                if isRetry {
                    debugLog("ERROR \(#function):\(#line) : GetAPs failure with error \(String(describing: response.error))")
                    serverResponse!(nil, response.error)
                } else {
                    NetworkController.shared.postTokenRefresh ({ (error) in
                        NetworkController.shared.getAPs(isRetry: true, serverResponse)
                    })
                }
            }

        }
    }

    // Gets a list of all UUIDs that are under this iotprofile ie. user
    func getIotProfile(isRetry: Bool = false, _ serverResponse : GetIotProfileResponse?) {
        guard let auth = currentAuth else {
            debugLog("ERROR \(#function):\(#line) : No current auth, unable to get iot profile")
            return
        }
        
        manager.request(baseURL + Endpoints.getIotProfileEndpoint, method: .get, headers: auth.header).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                print("GetIotProfileEndpoint success")
                print(value)
                if let iotProfile = Mapper<IotProfile>().mapArray(JSONObject: value) {
                    // FG: The return value is an array, the response paramenter request only one profile.
                    serverResponse!(iotProfile, nil)
                } else {
                    debugLog("ERROR \(#function):\(#line) : Unable to get JSON out of GetIotProfileEndpoint")
                    serverResponse!(nil, nil)
                }
                
            case .failure(_):
                if isRetry {
                    debugLog("ERROR \(#function):\(#line) : GetIotProfileEndpoint failure with error \(String(describing: response.error))")
                    serverResponse!(nil, response.error)
                } else {
                    NetworkController.shared.postTokenRefresh ({ (error) in
                        NetworkController.shared.getIotProfile(isRetry: true, serverResponse)
                    })
                }
            }

        }
    }

    func getAPStations(isRetry: Bool = false, _ serverResponse: GetAPStationsResponse?) {
        guard let auth = currentAuth else {
            debugLog("ERROR \(#function):\(#line) : No current auth, unable to get ap stations")
            return
        }

        let url = baseURL + Endpoints.getAPStationsEndpoint

        manager.request(url, method: .get, parameters: nil, headers: auth.header).validate().responseJSON() { response in
            switch response.result {
            case .success(let value):
                print("GetAPStationsEndpoint success")
                let apClientsArr = Mapper<APClient>().mapArray(JSONObject: value)
                serverResponse!(apClientsArr ?? [], nil)
            case .failure(_):
                debugLog("ERROR \(#function):\(#line) : GetAPStationsEndpoint failure with error \(String(describing: response.error))")
                serverResponse!(nil, response.error)
                if isRetry {
                    debugLog("ERROR \(#function):\(#line) : GetIotProfileEndpoint failure with error \(String(describing: response.error))")
                    serverResponse!(nil, response.error)
                } else {
                    NetworkController.shared.postTokenRefresh ({ (error) in
                        NetworkController.shared.getAPStations(isRetry: true, serverResponse)
                    })
                }
            }

        }
    }

    func processNoisePerRadio() {
        if let valueDic = self.reportDataJSON as? [String: Any] {
            let noisePerRadioArr = Mapper<NoisePerRadioStatistics>().mapArray(JSONObject: valueDic["noisePerRadio"])
            
            if let noiseArr = noisePerRadioArr {
                if noiseArr.count > 0 {
                    if let noiseArrValues = noiseArr[0].noisePerRadioArr {
                        if noiseArrValues.count > 1 {
                            
                            self.ReportData.NoisePerRadioR1 = noiseArrValues[0].values!
                            self.ReportData.NoisePerRadioR2 = noiseArrValues[1].values!
                        }
                    }
                }
            }
        } else {
            debugLog("ERROR \(#function):\(#line) : Unable to get JSON out of Noise per Radio values")
        }
        
    }
    
    func processChannelUtilization() {
        if let valueDic = self.reportDataJSON as? [String: Any] {
            let channel24 = Mapper<ChannelUtilizationStatistics>().mapArray(JSONObject: valueDic["channelUtilization2_4"])
            let channel5 = Mapper<ChannelUtilizationStatistics>().mapArray(JSONObject: valueDic["channelUtilization5"])
            
            
            if let utilInfo = channel24 {
                if utilInfo.count > 0 {
                    self.ReportData.ChannelUtilR1 = utilInfo[0].channelUtilizationInfoArr!
                }
            }
            if let utilInfo = channel5 {
                if utilInfo.count > 0 {
                    self.ReportData.ChannelUtilR2 = utilInfo[0].channelUtilizationInfoArr!
                }
            }
        } else {
            debugLog("ERROR \(#function):\(#line) : Unable to get JSON out of Channel Utilization values")
        }
    }
    
    func processRFQuality() {
        if let valueDic = self.reportDataJSON as? [String: Any] {
            let rfQualityArr = Mapper<RFQualityStatistics>().mapArray(JSONObject: valueDic["rfQuality"])
            
            if var arr = rfQualityArr?[0].rfQualityArr {
                self.ReportData.RFQuality = arr[0].rfQualityVals!
            } else {
                self.ReportData.RFQuality = []
            }
        } else {
            debugLog("ERROR \(#function):\(#line) : Unable to get JSON out of RF Quality values")
        }
    }
    
    func processPowerAndChannels() {
        if let valueDic = self.reportDataJSON as? [String: Any] {
            self.ReportData.Channels = Mapper<ChannelInfo>().map(JSONObject: valueDic["bandAndChannel"])
            self.ReportData.PowerLevels = Mapper<PowerLevelInfo>().map(JSONObject: valueDic["currentPowerLevel"])
        } else {
            debugLog("ERROR \(#function):\(#line) : Unable to get JSON out of channe/power values")
        }
    }
    
    func processThroughput() {
        if let valueDic = self.reportDataJSON as? [String: Any] {
            
            if let throughput = Mapper<Timeseries>().mapArray(JSONObject: valueDic["throughputReport"]) {
                if throughput.count > 0  && throughput[0].stats != nil {
                    self.ReportData.Throughput = (throughput[0].stats?[0].timeseriesValuesArr)!
                }
            }
            
        } else {
            debugLog("ERROR \(#function):\(#line) : Unable to get JSON out of Throughput values")
        }
    }
    
    
    func loadReportData(isRetry: Bool = false, serialNumber : String, _ completion: (( _ error: String?) -> Void)?) {
        guard let auth = currentAuth else {
            debugLog("ERROR \(#function):\(#line) : No current auth, unable to get reports")
            completion?("Unable to load AP reports, not logged in");
            return
        }
        
        let url = baseURL + Endpoints.getReportApsEndpoint + "/" + serialNumber + Endpoints.APReports.reportAll
        
        manager.request(url, method: .get, parameters: nil, headers: auth.header).validate().responseJSON() { response in
            switch response.result {
            case .success(let value):
                self.reportDataJSON = value
                debugLog("Report JSON: \(value)")
                self.processPowerAndChannels()
                self.processRFQuality()
                self.processThroughput()
                self.processNoisePerRadio()
                self.processChannelUtilization()
                completion!(nil)
            case .failure(_):
                if isRetry {
                    debugLog("ERROR \(#function):\(#line) : loadReports failure with error \(String(describing: response.error))")
                    completion!(response.error?.localizedDescription)
                } else {
                    NetworkController.shared.postTokenRefresh ({ (error) in
                        NetworkController.shared.loadReportData(isRetry: true, serialNumber: serialNumber, completion)
                    })
                }
            }
            
        }
    }
    
    

}

