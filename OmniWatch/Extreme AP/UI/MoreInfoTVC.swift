//
//  MoreInfoTVC.swift
//  Extreme AP
//
//  Created by nifer on 16/04/2019.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import UIKit

class MoreInfoTVC: UITableViewController {
    
    struct Segue {
        static let ClientScreen = "goToClientScreen"
    }
    
    class CellItem {
        var key : String = ""
        var value : String?
        var bold : Bool
        
        init(key: String, value: String?, bold: Bool? = false) {
            self.key = key
            self.value = value
            self.bold = bold!
        }
    }
    
    private var apCellsData  : [CellItem] = []
    private var radioOneData : [CellItem] = []
    private var radioTwoData : [CellItem] = []
    private var clientData   : [CellItem] = []
    
    var clientSelected : APClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        completeCellsData()
        tableView.reloadData()
    }
    
    private func completeCellsData() {
        guard let ap = APManager.shared.currentAP else {
            debugLog("ERROR \(#function):\(#line) : Missing AP data, nothing to display!")
            self.performSegue(withIdentifier: Constants.SegueId.LoginVC, sender: nil)
            return
        }
        
        apCellsData.append(CellItem(key: "AP name", value: String(ap.name ?? "Nil")))
        apCellsData.append(CellItem(key: "IP address", value: String(ap.ipAddress ?? "Nil")))
        apCellsData.append(CellItem(key: "Software version", value: String(ap.swVersion ?? "Nil")))
        apCellsData.append(CellItem(key: "MAC address", value: String(ap.macAddress ?? "Nil")))
        apCellsData.append(CellItem(key: "Open Reports", value: nil, bold: true))

        // Radios
        if ap.radios.count > 1 {
            let radio1 = ap.radios[0]
            let radio2 = ap.radios[1]
            var channel1 = "", channel2 = "", power1 = "", power2 = ""
            if APManager.shared.channels != nil {
                for channelInfo in APManager.shared.channels!.channelByRadioIndex {
                    if channelInfo.index == radio1.index {
                        channel1 = channelInfo.channel
                    } else if channelInfo.index == radio2.index {
                        channel2 = channelInfo.channel
                    }
                }
            }
            if APManager.shared.powerLevels != nil {
                for powerInfo in APManager.shared.powerLevels!.powerLevelsByRadioIndex {
                    if powerInfo.index == radio1.index {
                        power1 = powerInfo.powerLevel
                    } else if powerInfo.index == radio2.index {
                        power2 = powerInfo.powerLevel
                    }
                }
            }
            radioOneData.append(CellItem(key: "Mode", value: radio1.mode))
            radioOneData.append(CellItem(key: "Channel", value: channel1))
            radioOneData.append(CellItem(key: "TX power", value: power1))
            radioOneData.append(CellItem(key: "Noise Floor", value: String(APManager.shared.noisePerRadioR1?.noisePerRadio ?? "?")))
            
            radioTwoData.append(CellItem(key: "Mode", value: radio2.mode))
            radioTwoData.append(CellItem(key: "Channel", value: channel2))
            radioTwoData.append(CellItem(key: "TX power", value: power2))
            radioTwoData.append(CellItem(key: "Noise Floor", value: String(APManager.shared.noisePerRadioR2?.noisePerRadio ?? "?")))
        }
        
        // Clients
        APManager.shared.clients.forEach { client in
            let macAddr = client.macAddr ?? ""
            let hostname = client.hostname ?? ""

//            clientData.append(CellItem(key: macAddr + " " + hostname, value: nil))
             clientData.append(CellItem(key: hostname + " (" + macAddr + ")", value: nil))
        }
    }
    
    func goToClientDetails(apClient: APClient?) {
        clientSelected = apClient
        performSegue(withIdentifier: Segue.ClientScreen, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.ClientScreen,
            let vc = segue.destination as? ClientTVC {
            vc.apClient = clientSelected
        }
    }
    
    // MARK: UITableViewDataSource & UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return apCellsData.count
        case 1:
            return radioOneData.count
        case 2:
            return radioTwoData.count
        case 3:
            return clientData.count
        default:
            return 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 1:
            return "RADIO 1"
        case 2:
            return "RADIO 2"
        case 3:
            return "CLIENTS"
        default:
            return nil
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var data = CellItem(key: "", value: "")
        
        switch indexPath.section {
        case 0:
            data = apCellsData[indexPath.row]
        case 1:
            data = radioOneData[indexPath.row]
        case 2:
            data = radioTwoData[indexPath.row]
        case 3:
            data = clientData[indexPath.row]
        default: ()
        }
        
        if data.value == nil { // disclosure cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "disclosureCell", for: indexPath)
            cell.textLabel?.text = data.key
            if data.bold {
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            } else {
                cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
            }
            return cell
        } else { // detail cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            cell.textLabel?.text = data.key
            cell.detailTextLabel?.text = data.value
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 3 { // only client section\
            let client = APManager.shared.clients[indexPath.row]
            goToClientDetails(apClient: client)
        } else if indexPath.section == 0 {
            self.performSegue(withIdentifier: "goToAPReports", sender: nil)
        }
    }

}
