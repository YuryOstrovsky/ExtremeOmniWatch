//
//  SelectAPTVC.swift
//  Extreme AP
//
//  Created by Dmitry Voronov on 2019-05-28.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import UIKit
import MBProgressHUD


class APSelectionCell : UITableViewCell {
    @IBOutlet weak var apDistance: UILabel!
    @IBOutlet weak var apName: UILabel!
    @IBOutlet weak var apImage: UIImageView!
}

class SelectAPTVC : UITableViewController {
    class RowEntry {
        let apImage: UIImage?
        let apName: String?
        let distance: Double
        
        init(apImage: UIImage?, apName: String?, distance: Double) {
            self.apImage = apImage
            self.apName = apName
            self.distance = distance
        }
    }
    
    var TableData : [RowEntry] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        generateTableData()
        tableView.reloadData()
    }
    
    func generateTableData() {
        for beacon in BLEManager.shared.currentBeaconData! {
            if let ap = APManager.shared.getAP(withMajor: beacon.major, andMinor: beacon.minor) {
                TableData.append(RowEntry(apImage: ap.apImage, apName: ap.name, distance: beacon.accuracy))
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TableData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        var row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "apCell", for: indexPath) as! APSelectionCell
        
        let rowEntry = TableData[row]
        if let image = rowEntry.apImage {
            cell.apImage?.image = image
        }
        if let name = rowEntry.apName {
            cell.apName?.text = name
        }
        //cell.apDistance?.text = String(rowEntry.distance)
        
        return cell
    }
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        
        let beacon = BLEManager.shared.currentBeaconData?[row]
        BLEManager.shared.selectedBeaconData = beacon
        var hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.label.text = "Loading AP details..."
        APManager.shared.loadSelectedAP({ (error) in
            hud.hide(animated: true);
            if error == nil {
                self.performSegue(withIdentifier: Constants.SegueId.MainVC, sender: nil)
            } else {
                self.showAlert(title: "Error", message: error?.localizedDescription, completion: {
                    (alertAction) in
                    
                    self.performSegue(withIdentifier: Constants.SegueId.LoginVC, sender: nil)
                })
            }
        })
    }
    
    @IBAction func findMoreBeaconsButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: Constants.SegueId.LookingForBeaconVC, sender: nil)
    }
}
