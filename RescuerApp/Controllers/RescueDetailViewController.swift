//
//  RescueDetailViewController.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

class RescueDetailViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet private weak var phoneNumber: UILabel!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    private var requestId: String!
    private var request: Request!
    private let locationManager = CLLocationManager()
    private var rescuer: [String: Any]!
    private var statusListener: ListenerRegistration?
    private var srcPin = MKPointAnnotation()
    private var desPin = MKPointAnnotation()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        startListening()
        
        titleLabel.text = "Loading..."
        addressLabel.text = "Loading..."
        phoneNumber.text = "Loading..."
        
        self.navigationItem.setHidesBackButton(true, animated:true);
        
        completeButton.layer.cornerRadius = 10.0
        completeButton.layer.masksToBounds = true
        
        phoneNumber.text = request.phoneNumber
        
        let phoneTap = UITapGestureRecognizer(target: self, action: #selector(RequestDetailViewController.onClickPhoneLabel))
        phoneNumber.isUserInteractionEnabled = true
        phoneNumber.addGestureRecognizer(phoneTap)
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListening()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        else {
            showMsg(msgTitle: "Cannot Access Location Service", msgText: "Do not have Location Services or permission is not given")
        }
    }
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil),
                               request: Request, rescuer: [String: Any], requestId: String) -> RescueDetailViewController {
        let controller =
            storyboard.instantiateViewController(withIdentifier: "RescueDetailViewController")
                as! RescueDetailViewController
        controller.request = request
        controller.rescuer = rescuer
        controller.requestId = requestId
        return controller
    }
    
    @objc func onClickPhoneLabel(sender: UITapGestureRecognizer) {
        makeAPhoneCall(phoneNumber: request.phoneNumber)
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
    
    private func startListening() {
        let requestRef = Firestore.firestore().collection("requests").document(requestId)
        statusListener = requestRef.addSnapshotListener { (snapshot, error) in
            if let error = error {
                print ("I got an error retrieving requests: \(error)")
                return
            }
            guard let snapshot = snapshot else { return }
            let requestData = snapshot.data()
            let status = requestData?["status"] as! Int
            
            let title = "เกิดข้อผิดพลาด"
            let canceling = "คำขอถูกยกเลิก"
            
            if status == 3 {
                let alert = UIAlertController(title: title, message: canceling, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "ตกลง", style: UIAlertAction.Style.default) { action in
                    let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
                    self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
                })
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    private func stopListening() {
        statusListener?.remove()
        statusListener = nil
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mapView.removeAnnotations([srcPin, desPin])
        
        let requestLocation = request.requestLocation
        let location = locations.last! as CLLocation
        
        let src = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
//        let src = CLLocationCoordinate2D(latitude: 13.8551301, longitude: 100.5333459)
        let des = CLLocationCoordinate2D(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
        
        srcPin.coordinate = src
        srcPin.title = "ฉัน"
        desPin.coordinate = des
        desPin.title = "ผู้ประสบภัย"
        
        mapView.addAnnotations([srcPin, desPin])
        
        let srcPlaceMark = MKPlacemark(coordinate: src)
        let desPlaceMark = MKPlacemark(coordinate: des)
        
        let dirRequest:MKDirections.Request = MKDirections.Request()
        dirRequest.source = MKMapItem(placemark: srcPlaceMark)
        dirRequest.destination = MKMapItem(placemark: desPlaceMark)
        dirRequest.transportType = .automobile
        
        let directions = MKDirections(request: dirRequest)
        directions.calculate { (response, error) in
            guard let directionResonse = response else {
                if let error = error {
                    print("we have error getting directions==\(error.localizedDescription)")
                }
                return
            }
            let route = directionResonse.routes[0]
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
        self.mapView.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showMsg(msgTitle: "Cannot Access Location Service", msgText: "Do not have Location Services or permission is not given")
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        return renderer
    }
    
}
