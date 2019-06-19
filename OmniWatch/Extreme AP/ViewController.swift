//
//  ViewController.swift
//  Extreme AP
//
//  Created by Ania Bogatch on 2019-04-01.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import UIKit
import CoreLocation


class ViewController: UIViewController, CLLocationManagerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // Base function for showing alerts
    // Use this for bluetooth on
    func presentAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil);
    }


    func updateDistance(_ distance: CLProximity) {
        UIView.animate(withDuration: 0.8) {
            switch distance {
            case .far:
                self.view.backgroundColor = UIColor.blue

            case .near:
                self.view.backgroundColor = UIColor.orange

            case .immediate:
                self.view.backgroundColor = UIColor.red

            case .unknown:
                self.view.backgroundColor = UIColor.gray

            default:
                self.view.backgroundColor = UIColor.gray
            }

        }
    }
}

