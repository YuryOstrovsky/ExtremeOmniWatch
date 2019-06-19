//
//  MainTVC.swift
//  Extreme AP
//
//  Created by nifer on 12/04/2019.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import UIKit
import MBProgressHUD

class MainTVC: UITableViewController {
    
    // MARK: IBOulets
    @IBOutlet weak var apImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hwTypeLabel: UILabel!
    @IBOutlet weak var numberOfClientsLabel: UILabel!
    @IBOutlet weak var channelUtilization24GhzLabel: UILabel!
    @IBOutlet weak var channelUtilization5GhzLabel: UILabel!
    @IBOutlet weak var rfQualityLabel: UILabel!
    @IBOutlet weak var channelUtil24Progress: UIProgressView!
    @IBOutlet weak var channelUtil5Progress: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateFields()
    }
    
    private func populateFields() {
        guard let currentAp = APManager.shared.currentAP else { return }
        
        apImageView.image = currentAp.apImage
        nameLabel.text = String(currentAp.name ?? "Unknown AP")
        hwTypeLabel.text = String(currentAp.hardwareType ?? "Unknown")
        
        if let rfQuality = APManager.shared.currentAPRFQuality {
            if let rfQualityStr = rfQuality.rfQualityRadio {
                var rfQualityVal = Double(rfQualityStr) ?? 0.0
                rfQualityVal = min(5.0, round(rfQualityVal * 10.0) / 10.0)                
                rfQualityLabel.text = String(rfQualityVal)
            } else {
                rfQualityLabel.text = "n/a"
            }
        } else {
            rfQualityLabel.text = "n/a"
        }

        // Need to take the ChannelUtil value, convert it to int and subtract from 100
        // to get the final val
        var finalChannel24 = 0
        if let channel24 = Int(APManager.shared.channelUtil24?.channelUtil ?? "0") {
            if (channel24 > 0) {
                finalChannel24 = 100 - channel24
            }
        }

        var finalChannel5 = 0
        if let channel5 = Int(APManager.shared.channelUtil5?.channelUtil ?? "0") {
            if (channel5 > 0) {
                finalChannel5 = 100 - channel5
            }
        }
        
        let transform = CGAffineTransform(scaleX: 1.0, y: 5.0)
        
        channelUtilization24GhzLabel.text = String(finalChannel24) // Value for 2.4Ghz channel
        channelUtil24Progress.progress = Float(finalChannel24)/100
        //channelUtil24Progress.transform = transform
        
        channelUtilization5GhzLabel.text = String(finalChannel5) // Value for 5Ghz channel
        channelUtil5Progress.progress = Float(finalChannel5)/100
        //channelUtil5Progress.transform = transform
        
        numberOfClientsLabel.text = String(APManager.shared.clientCount!)
    }
    
    // MARK: - Actions
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        debugLog("INFO \(#function):\(#line) : Closing information about this AP, stop ranging and monitoring for this user!")
        BLEManager.shared.disableAllRanging()
        BLEManager.shared.turnOffRegionMonitoring()
        APManager.shared.clean()
        self.dismiss(animated: true, completion: nil)
    }
    
    // Find more beacons
    
    @IBAction func findMoreBeaconsButtonPressed(_ sender: Any) {
        //findBeacons()
        self.performSegue(withIdentifier: Constants.SegueId.LookingForBeaconVC, sender: nil)
    }
    
    func findBeacons() {
        APManager.shared.findAP(inView: self.view) { [weak self] (error) in
            if error == nil {
                self?.populateFields()
            } else {
                let errorDescription = String(describing: error!.localizedDescription)
                self?.showAlert(title: "Error", message: errorDescription, completion: {
                    (alertAction) in
                    
                    self?.performSegue(withIdentifier: Constants.SegueId.LoginVC, sender: nil)
                })
            }
        }
    }

}
