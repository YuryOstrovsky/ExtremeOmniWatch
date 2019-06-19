//
//  ViewController+ExtremeAP.swift
//  Extreme AP
//
//  Created by nifer on 12/04/2019.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showAlert(title: String?  = "",
                         message: String?,
                         completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title , message: message, preferredStyle:.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default,handler: completion ))
        self.present(alert, animated: true, completion: nil)
    }
    
}
