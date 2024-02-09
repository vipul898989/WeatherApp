//
//  SearchLocationViewController.swift
//  McDemo
//
//  Created by iMac on 18/10/23.
//

import UIKit

protocol SearchDelegate: NSObject {
    func search(country: String, city: String)
}
class SearchLocationViewController: UIViewController {

    @IBOutlet weak var txtCountry: UITextField!
    @IBOutlet weak var txtCity: UITextField!
    
    
    weak var delegate: SearchDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        self.view.endEditing(true)
    }
    
    @IBAction func btnSearchTapped(_ sender: Any) {
        
        if valid() {
            self.delegate?.search(country: txtCountry.text!.trimmingCharacters(in: .whitespaces), city: txtCity.text!.trimmingCharacters(in: .whitespaces))
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func valid() -> Bool {
        var isValid: Bool = false
        
        let country = txtCountry.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let city = txtCity.text?.trimmingCharacters(in: .whitespaces) ?? ""

        if country == "" {
            // enter country name
        } else if city == "" {
            // enter city name
        } else {
            isValid = true
        }
        return isValid
    }

}
