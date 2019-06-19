//
//  HelpViewController.swift
//  Alamofire
//
//  Created by Yury Ostrovsky on 2019-05-21.
//

import UIKit
import WebKit

class HelpViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
   
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let urlString = "https://gtacknowledge.extremenetworks.com/articles/How_To/Extreme-OmniWatch"
        let request = URLRequest(url: URL(string: urlString)!)
        self.webView.load(request)
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
 }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loading" {
            if webView.isLoading {
                activityIndicator.startAnimating()
                activityIndicator.isHidden = false
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
