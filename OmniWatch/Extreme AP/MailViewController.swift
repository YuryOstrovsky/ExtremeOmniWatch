//
//  MailViewController.swift
//  Extreme AP
//
//  Created by Yury Ostrovsky on 2019-05-20.
//  Copyright © 2019 Extreme Networks. All rights reserved.
//

import UIKit
import MessageUI

class MailViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet var nameField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var messageField: UITextField!
    @IBOutlet weak var lblValidationMessage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        lblValidationMessage.isHidden = true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func Send(_ sender: Any) {
        
// Warn user if text fields are empty
        
        guard let name = nameField.text,nameField.text?.count != 0
            else {
                lblValidationMessage.isHidden = false
                lblValidationMessage.text = "Please enter your name"
                return
        }
        guard let email = emailField.text,emailField.text?.count != 0
            else {
                lblValidationMessage.isHidden = false
                lblValidationMessage.text = "Please enter e-mail address"
                return
        }
// Validate the email format
        
        if isValidEmail(emailID: email) == false {
            lblValidationMessage.isHidden = false
            lblValidationMessage.text = "Please enter valid e-mail"
            print("test")
            
            return
        }
        
        
        guard let message = messageField.text,messageField.text?.count != 0
            else {
                lblValidationMessage.isHidden = false
                lblValidationMessage.text = "Please enter the Subject"
                return
        }
        lblValidationMessage.isHidden = true
// Composing e-mail
        
        let toRecipients = ["omniwatch@extremenetworks.com"]
        let mc: MFMailComposeViewController = MFMailComposeViewController()
        mc.mailComposeDelegate = self
        mc.setToRecipients(toRecipients)
        mc.setSubject(messageField.text!)
     //   mc.setMessageBody("Name: \(nameField.text!) \n\nEmail: \(emailField.text!) \n\nMessage enter here: \(messageField.text!)", isHTML: false)
        mc.setMessageBody("Name: \(nameField.text!) \nEmail: \(emailField.text!) \n\nPlease enter message here: ", isHTML: false)
        self.present(mc, animated: true, completion: nil)
        
    }
    
    func isValidEmail(emailID:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: emailID)
    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result.rawValue {
        case MFMailComposeResult.cancelled.rawValue:
            print("Cancelled")
        case MFMailComposeResult.failed.rawValue:
            print("Failed")
        case MFMailComposeResult.saved.rawValue:
            print("Saved")
        case MFMailComposeResult.sent.rawValue:
            print("Sent")
        default:
            break
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func dismissKeyboard(_ sender: Any) {
        
        self.resignFirstResponder()
    }
    
    
}
