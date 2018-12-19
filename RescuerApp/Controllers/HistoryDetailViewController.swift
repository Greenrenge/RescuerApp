//
//  HistoryDetailViewController.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit
import CoreLocation

class HistoryDetailViewController: UIViewController {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    private var request: Request!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nameLabel.text = "Loading..."
        addressLabel.text = "Loading..."
        phoneLabel.text = "Loading..."
        
        phoneLabel.text = request.phoneNumber
        
        let phoneTap = UITapGestureRecognizer(target: self, action: #selector(HistoryDetailViewController.onClickPhoneLabel))
        phoneLabel.isUserInteractionEnabled = true
        phoneLabel.addGestureRecognizer(phoneTap)
        
        let longitude: CLLocationDegrees = request.requestLocation.longitude
        let latitude: CLLocationDegrees = request.requestLocation.latitude
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            
            if error != nil {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            
            if (placemarks?.count)! > 0 {
                let pm = placemarks![0]
                let name = pm.name ?? ""
                let subDistrict = pm.subLocality ?? ""
                let district = pm.subAdministrativeArea ?? ""
                let province = pm.locality ?? ""
                
                let address = "\(String(describing: subDistrict)), \(String(describing: district)), \(String(describing: province))"
                
                self.nameLabel.text = name
                self.addressLabel.text = "\(address)\n"
            }
            else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil),
                               request: Request) -> HistoryDetailViewController {
        let controller =
            storyboard.instantiateViewController(withIdentifier: "HistoryDetailViewController")
                as! HistoryDetailViewController
        controller.request = request
        return controller
    }
    
    @objc func onClickPhoneLabel(sender: UITapGestureRecognizer) {
        makeAPhoneCall(phoneNumber: request.phoneNumber)
    }
    
    private func showMsg(msgTitle: String, msgText: String) {
        let alert = UIAlertController(title: msgTitle, message: msgText, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func makeAPhoneCall(phoneNumber: String) {
        if let url = URL(string: "tel://" + phoneNumber) {
            if UIApplication.shared.canOpenURL(url) == true {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            else {
                showMsg(msgTitle: "Cannot Access Phone Call", msgText: "Do not have phone call or permission is not given")
            }
        }
    }
    
}
