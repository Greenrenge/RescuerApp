//
//  RequestDetailViewController.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

class RequestDetailViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var rescueButton: UIButton!
    @IBOutlet weak var phoneNumber: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    private var requestId: String!
    private var request: Request!
    private let locationManager = CLLocationManager()
    private var currentGeo: GeoPoint?
    private var statusListener: ListenerRegistration?
    private var srcPin = MKPointAnnotation()
    private var desPin = MKPointAnnotation()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if  let arrayOfTabBarItems = self.tabBarController?.tabBar.items as AnyObject as? NSArray,let tabBarItem = arrayOfTabBarItems[0] as? UITabBarItem {
            tabBarItem.isEnabled = false
        }
        setNeedsStatusBarAppearanceUpdate()
        startListening()
        
        titleLabel.text = "Loading..."
        addressLabel.text = "Loading..."
        phoneNumber.text = "Loading..."
        
        rescueButton.layer.cornerRadius = 10.0
        rescueButton.layer.masksToBounds = true
        
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
                self.addressLabel.text = "\(address)\n"
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
                               request: Request, requestId: String) -> RequestDetailViewController {
        let controller =
            storyboard.instantiateViewController(withIdentifier: "RequestDetailViewController")
                as! RequestDetailViewController
        controller.request = request
        controller.requestId = requestId
        return controller
    }
    
    @objc func onClickPhoneLabel(sender: UITapGestureRecognizer) {
        makeAPhoneCall(phoneNumber: request.phoneNumber)
    }
    
    @IBAction func onClickRescue(_ sender: UIButton) {
        self.rescueButton.isEnabled = false
        
        let alert = UIAlertController(title: "ช่วยเหลือ", message: "คุณต้องการช่วยเหลือใช่หรือไม่ ?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "ไม่ใช่", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "ใช่", style: .default, handler: {
            action in
            
            if (CheckInternet.Connection()) {
                guard self.request.status == 0 else {
                    let title = "เกิดข้อผิดพลาด"
                    let rescuing = "คำขอได้รับการช่วยเหลือแล้ว"
                    let completing = "คำขอเสร็จสิ้นแล้ว"
                    let canceling = "คำขอถูกยกเลิก"
                    var message = ""
                    
                    if self.request.status == 1 {
                        message = rescuing
                    } else if self.request.status == 2 {
                        message = completing
                    } else if self.request.status == 3 {
                        message = canceling
                    }
                    
                    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "ตกลง", style: UIAlertAction.Style.default) { action in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                let rescuerId = Auth.auth().currentUser?.uid
                let rescuerRef = Firestore.firestore().collection("officers").whereField("officerId", isEqualTo: rescuerId!)
                
                rescuerRef.getDocuments { (document, error) in
                    if let document = document {
                        var rescuer = document.documents[0].data()
                        let id = rescuer["officerId"]
                        let name = rescuer["nameOfficer"]
                        let ref = Firestore.firestore().collection("requests").document(self.request.documentID)
                        
                        guard id != nil && name != nil else { return }
                        ref.updateData([
                            "rescuerName": name!,
                            "rescuerID": id!,
                            "rescuerLocation": GeoPoint(latitude: 13.7270068, longitude: 100.5259204),
                            "status": 1
                        ]) { err in
                            if let err = err {
                                self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดลองใหม่อีกครั้ง")
                                self.rescueButton.isEnabled = true
                            } else {
                                rescuer["rescuerLocation"] = GeoPoint(latitude: 13.7270068, longitude: 100.5259204)
                                let controller = RescueDetailViewController.fromStoryboard(request: self.request, rescuer: rescuer, requestId: self.requestId)
                                self.navigationController?.pushViewController(controller, animated: true)
                            }
                        }
                    } else {
                        self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดลองใหม่อีกครั้ง")
                    }
                }
            } else {
                self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ต")
            }
            
        }))
        
        self.present(alert, animated: true, completion: nil)
    
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
            self.request.status = requestData?["status"] as! Int
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
        let des = CLLocationCoordinate2D(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
        
        srcPin.coordinate = src
        srcPin.title = "ฉัน"
        desPin.coordinate = des
        desPin.title = "ผู้ประสบภัย"
        
        mapView.addAnnotations([srcPin, desPin])
        
        let srcPlaceMark = MKPlacemark(coordinate: src)
        let desPlaceMark = MKPlacemark(coordinate: des)
        
        let dirRequest: MKDirections.Request = MKDirections.Request()
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
