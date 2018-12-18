//
//  RescueDetailViewController.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

class RescueDetailViewController: UIViewController {
    
    @IBOutlet private weak var phoneNumber: UILabel!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    private var request: Request!
    private var rescuer: [String: Any]!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.setHidesBackButton(true, animated:true);
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        completeButton.layer.cornerRadius = 10.0
        completeButton.layer.masksToBounds = true
        phoneNumber.text = request.phoneNumber
        
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
                
                self.titleLabel.text = name
                self.addressLabel.text = address
            }
            else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil),
                               request: Request, rescuer: [String: Any]) -> RescueDetailViewController {
        let controller =
            storyboard.instantiateViewController(withIdentifier: "RescueDetailViewController")
                as! RescueDetailViewController
        controller.request = request
        controller.rescuer = rescuer
        return controller
    }

    @IBAction func onClickComplete(_ sender: UIButton) {
        let rescuerId = self.rescuer["officerId"]
        let rescuerRef = Firestore.firestore().collection("officers").whereField("officerId", isEqualTo: rescuerId!)
        rescuerRef.getDocuments { (document, error) in
            if let document = document {
                let docId = document.documents[0].documentID
                let phoneNumber = self.request.phoneNumber
                let reqLocation = self.request.requestLocation
                let rescuerId = self.rescuer["officerId"]
                let rescuerName = self.rescuer["nameOfficer"]
                let rescuerLocation = self.rescuer["rescuerLocation"]
                
                let historyRef = Firestore.firestore().collection("officers").document(docId).collection("histories")
                historyRef.addDocument(data: [
                    "phoneNumber": phoneNumber,
                    "requestLocation": reqLocation,
                    "rescuerID": rescuerId!,
                    "rescuerName": rescuerName!,
                    "rescuerLocation": rescuerLocation!,
                    "status": 2,
                ]) { err in
                    if let err = err {
                        print("Error Adding: \(err)")
                    } else {
                        let requestRef = Firestore.firestore().collection("requests").document(self.request.documentID)
                        requestRef.updateData(["status": 2]) { err in
                            if let err = err {
                                print("Error Updating: \(err)")
                            } else {
                                let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
                                self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
                            }
                        }
                    }
                }
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
}
