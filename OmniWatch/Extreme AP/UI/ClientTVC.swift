//
//  ClientTVC.swift
//  Extreme AP
//
//  Created by nifer on 16/04/2019.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import UIKit

class ClientTVC: UITableViewController {

    var apClient : APClient?
    
    @IBOutlet weak var currentRoleLabel: UILabel!
    // Plz disable this for now!! currentNetwork is found in another REST call
    @IBOutlet weak var rssLabel: UILabel!
    @IBOutlet weak var deviceTypeLabel: UILabel!
    @IBOutlet weak var hostnameLabel: UILabel!
    @IBOutlet weak var protocolLabel: UILabel!
    @IBOutlet weak var channelLabel: UILabel!
    // TODO: Remove this one and enable the two below - they should be 2 separate ones
    @IBOutlet weak var txRateLabel: UILabel!
    @IBOutlet weak var rxRateLabel: UILabel!
    @IBOutlet weak var macLabel: UILabel!
    @IBOutlet weak var ipLabel: UILabel!
    @IBOutlet weak var osImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = apClient?.apName
        populateFields()
    }
    
    private func populateFields() {
        
        guard let apClient = apClient else { return }
        currentRoleLabel.text = String(apClient.role ?? "Nil")
        rssLabel.text = String(apClient.rss ?? 0) // Zero if is nil
        deviceTypeLabel.text = String(apClient.deviceType ?? "Nil")
        hostnameLabel.text = String(apClient.hostname ?? "Nil")
        protocolLabel.text = String(apClient.protocolType ?? "Nil")
        channelLabel.text = String(apClient.channel ?? "Nil")
        ipLabel.text = String(apClient.ipAddr ?? "Nil")
        macLabel.text = String(apClient.macAddr ?? "Nil")
        if apClient.osImage != nil {
            osImage.image = apClient.osImage!
        } else {
            osImage.isHidden = true
        }

        var tx = Double(apClient.txRate ?? 0)
        tx = tx/1000000; // convert from bytes to MB/sec
        txRateLabel.text = String(format: "%.2f", tx)
        var rx = Double(apClient.rxRate ?? 0)
        rx = rx/1000000;
        rxRateLabel.text = String(format: "%.2f", rx)
    }

}
