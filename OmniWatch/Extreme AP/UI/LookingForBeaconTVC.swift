//
//  LookingForBeaconTVC.swift
//  Extreme AP
//
//  Created by Dmitry Voronov on 2019-05-06.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import UIKit

class LookingForBeaconTVC : UIViewController {
    @IBOutlet weak var progressView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        findBeacons();
    }
    func findBeacons() {
        BLEManager.shared.currentBeaconData = []
        BLEManager.shared.selectedBeaconData = nil
        APManager.shared.findAP(inView: self.progressView) { [weak self] (error) in
            if error == nil {
                if BLEManager.shared.selectedBeaconData != nil {
                    self?.performSegue(withIdentifier: Constants.SegueId.MainVC, sender: nil)
                } else {
                    self?.performSegue(withIdentifier: Constants.SegueId.SelectAPVC, sender: nil)
                }
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
