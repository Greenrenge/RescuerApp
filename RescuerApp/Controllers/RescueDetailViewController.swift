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
        if  let arrayOfTabBarItems = self.tabBarController?.tabBar.items as AnyObject as? NSArray,let tabBarItem = arrayOfTabBarItems[0] as? UITabBarItem {
            tabBarItem.isEnabled = false
        }
        setNeedsStatusBarAppearanceUpdate()
        startListening()
        
        titleLabel.text = "รอสักครู่..."
        addressLabel.text = "รอสักครู่..."
        phoneNumber.text = "รอสักครู่..."
        
        self.navigationItem.setHidesBackButton(true, animated:true);
        
        completeButton.layer.cornerRadius = 10.0
        completeButton.layer.masksToBounds = true
        
        phoneNumber.text = request.phoneNumber
        
        let phoneTap = UITapGestureRecognizer(target: self, action: #selector(RequestDetailViewController.onClickPhoneLabel))
        phoneNumber.isUserInteractionEnabled = true
        phoneNumber.addGestureRecognizer(phoneTap)
        
        self.titleLabel.text = request.requestName
        self.addressLabel.text = request.requestAddress
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListening()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print(rescuer)
        
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
        self.completeButton.isEnabled = false
        
        let alert = UIAlertController(title: "เสร็จสิ้น", message: "ภารกิจเสร็จสิ้นแล้วใช่หรือไม่ ?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "ไม่ใช่", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "ใช่", style: .default, handler: {
            action in
            if (CheckInternet.Connection()) {
                print(self.rescuer)
                let rescuerId = self.rescuer["officerId"]
                let rescuerRef = Firestore.firestore().collection("officers").whereField("officerId", isEqualTo: rescuerId!)
                rescuerRef.getDocuments { (document, error) in
                    if let document = document {
                        let docId = document.documents[0].documentID
                        let phoneNumber = self.request.phoneNumber
                        let reqLocation = self.request.requestLocation
                        let requestName = self.request.requestName
                        let requestAddress = self.request.requestAddress
                        let rescuerName = self.rescuer["nameOfficer"]
                        let rescuerLocation = self.rescuer["location"]
                        
                        let historyRef = Firestore.firestore().collection("officers").document(docId).collection("histories")
                        historyRef.addDocument(data: [
                            "phoneNumber": phoneNumber,
                            "requestLocation": reqLocation,
                            "requestName": requestName,
                            "requestAddress": requestAddress,
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
                                            print("Error Adding: \(err)")
                                            self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดลองใหม่อีกครั้ง")
                                            self.completeButton.isEnabled = true
                                        } else {
                                            self.navigationController?.popToRootViewController(animated: true)
                                        }
                                    }
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
        
        self.completeButton.isEnabled = true
        self.present(alert, animated: true, completion: nil)
        
    }
    
    private func startListening() {
        if (CheckInternet.Connection()) {
            let requestRef = Firestore.firestore().collection("requests").document(requestId)
            statusListener = requestRef.addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print ("I got an error retrieving requests: \(error)")
                    self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดลองใหม่อีกครั้ง")
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
                        self.navigationController!.popToRootViewController(animated: true)
                    })
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ต")
        }
        
    }
    
    private func stopListening() {
        statusListener?.remove()
        statusListener = nil
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
                showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดลองใหม่อีกครั้ง")
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
        srcPin.title = "คุณอยู่ที่นี่"
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
                    print(error.localizedDescription)
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
