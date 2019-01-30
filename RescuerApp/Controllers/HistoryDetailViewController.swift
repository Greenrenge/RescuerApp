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
        
        nameLabel.text = "รอสักครู่.."
        addressLabel.text = "รอสักครู่.."
        phoneLabel.text = "รอสักครู่.."
        
        phoneLabel.text = request.phoneNumber
        
        let phoneTap = UITapGestureRecognizer(target: self, action: #selector(HistoryDetailViewController.onClickPhoneLabel))
        phoneLabel.isUserInteractionEnabled = true
        phoneLabel.addGestureRecognizer(phoneTap)
        
        self.nameLabel.text = request.requestName
        self.addressLabel.text = request.requestAddress
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
            showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "ไม่สามารถเข้าถึงตำแหน่งได้")
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
        
        alert.addAction(UIAlertAction(title: "ตกลง", style: UIAlertAction.Style.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func makeAPhoneCall(phoneNumber: String) {
        if let url = URL(string: "tel://" + phoneNumber) {
            if UIApplication.shared.canOpenURL(url) == true {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            else {
                self.showMsg(msgTitle: "ไม่สามารถเข้าถึงการโทรได้", msgText: "โปรดโทรไปที่เบอร์ \(phoneNumber)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mapView.removeAnnotations([srcPin, desPin])
        
        let requestLocation = request.requestLocation
        let rescuerLocation = request.rescuerLocation
        
        let src = CLLocationCoordinate2D(latitude: (rescuerLocation?.latitude)!, longitude: (rescuerLocation?.longitude)!)
        let des = CLLocationCoordinate2D(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
        
        srcPin.coordinate = src
        srcPin.title = "คุณอยู่ที่นี่"
        desPin.coordinate = des
        desPin.title = "ผู้ประสบภัย"
        
        mapView.addAnnotations([srcPin, desPin])
        
        let srcPlaceMark = MKPlacemark(coordinate: src)
        let desPlaceMark = MKPlacemark(coordinate: des)
        
        let dirRequest = MKDirections.Request()
        dirRequest.source = MKMapItem(placemark: srcPlaceMark)
        dirRequest.destination = MKMapItem(placemark: desPlaceMark)
        dirRequest.transportType = .automobile
        
        let directions = MKDirections(request: dirRequest)
        directions.calculate { (response, error) in
            guard let directionResonse = response else {
                if let error = error {
                    print("we have error getting directions==\(error.localizedDescription)")
                    self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "ไม่สามารถแสดงเส้นทางได้")
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
        showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "ไม่สามารถเข้าถึงตำแหน่งได้")
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        return renderer
    }
    
}
