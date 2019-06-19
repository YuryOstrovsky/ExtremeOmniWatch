//
//  LoginTVC.swift
//  Extreme AP
//
//  Created by nifer on 12/04/2019.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import UIKit
import SwiftyJSON
import MBProgressHUD

class LoginTVC: UITableViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var serverAddressTextField: UITextField!
    @IBOutlet weak var beaconDistanceTextField: UITextField!
    @IBOutlet weak var rememberMeSwitch: UISwitch!
    @IBOutlet weak var unitsSwitch: UISegmentedControl!

    // AB: TODO We can improve this by checking if this beaconDistance has been filled
    // some can be optional
    // FG: which ones?
    private var areInputsFilled : Bool {
        return usernameTextField.text != "" &&
            passwordTextField.text != "" &&
            serverAddressTextField.text != "" &&
            beaconDistanceTextField.text != ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if rememberMeSwitch.isOn {
            let defaults = UserDefaults.standard
            if let username = defaults.string(forKey: "username") {
                usernameTextField.text = username
            }
            if let password = defaults.string(forKey: "password") {
                passwordTextField.text = password
            }
            if let server = defaults.string(forKey: "server") {
                serverAddressTextField.text = server
            }
            if let beaconDistance = defaults.string(forKey: "beaconDistance") {
                beaconDistanceTextField.text = beaconDistance
            }
            if let units = defaults.string(forKey: "units") {
                unitsSwitch.selectedSegmentIndex = Int(units) ?? 0
            }
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        // Use user values if all inputs all filled
        if areInputsFilled {
            if let distance = Double(beaconDistanceTextField.text!) {
                UserManager.shared.userParameters.beaconDistance = distance
            } else {
                showAlert(title: "Invalid distance", message: "Beacon distance field should be a number.")
                return
            }
            UserManager.shared.userParameters.username = usernameTextField.text!
            UserManager.shared.userParameters.password = passwordTextField.text!
            UserManager.shared.userParameters.server   = serverAddressTextField.text!
            UserManager.shared.userParameters.units    = unitsSwitch.selectedSegmentIndex
        } else if beaconDistanceTextField.text != "" {
            if let distance = Double(beaconDistanceTextField.text!) {
                UserManager.shared.userParameters.beaconDistance = distance
            } else {
                showAlert(title: "Invalid distance", message: "Beacon distance field should be a number.")
                return
            }
        }
        
        if rememberMeSwitch.isOn {
            let defaults = UserDefaults.standard
            defaults.set(UserManager.shared.userParameters.username, forKey: "username")
            defaults.set(UserManager.shared.userParameters.password, forKey: "password")
            defaults.set(UserManager.shared.userParameters.server, forKey: "server")
            defaults.set(UserManager.shared.userParameters.beaconDistance, forKey: "beaconDistance")
            defaults.set(UserManager.shared.userParameters.units, forKey: "units")
        }
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Login"
        NetworkController.shared.postToken() { [weak self] (token, error) in
            guard let self = self else { return }
            hud.hide(animated: true)
            if error == nil {
                self.performSegue(withIdentifier: Constants.SegueId.LookingForBeaconVC, sender: nil)
            } else {
                let errorDescription = String(describing: error!.localizedDescription)
                self.showAlert(title: "Login Failed", message: "Please double check the server, username and password.")
            }
        }
    }
    
    @IBAction func changeUnits(_ sender: UISegmentedControl) {
        debugLog(unitsSwitch.selectedSegmentIndex)
    }
    
    func findBeacons() {
        APManager.shared.findAP(inView: self.view) { [weak self] (error) in
            if error == nil {
                self?.performSegue(withIdentifier: Constants.SegueId.LookingForBeaconVC, sender: nil)
            } else {
                let errorDescription = String(describing: error!.localizedDescription)
                self?.showAlert(title: "Error", message: errorDescription)
            }
        }
    }
    
}
