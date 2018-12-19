//
//  HistoryDetailViewController.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit
import MapKit
import CoreLocation

class HistoryDetailViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    private var request: Request!
    private let locationManager = CLLocationManager()
    private var srcPin = MKPointAnnotation()
    private var desPin = MKPointAnnotation()
    
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mapView.removeAnnotations([srcPin, desPin])
        
        let requestLocation = request.requestLocation
//        let rescuerLocation = request.rescuerLocation
        
//        let src = CLLocationCoordinate2D(latitude: rescuerLocation.latitude, longitude: rescuerLocation.longitude)
        let src = CLLocationCoordinate2D(latitude: 13.8551301, longitude: 100.5333459)
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
    
}
