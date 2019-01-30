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
        
        titleLabel.text = "รอสักครู่..."
        addressLabel.text = "รอสักครู่..."
        phoneNumber.text = "รอสักครู่..."
        
        rescueButton.layer.cornerRadius = 10.0
        rescueButton.layer.masksToBounds = true
        
        phoneNumber.text = request.phoneNumber
        
        let phoneTap = UITapGestureRecognizer(target: self, action: #selector(RequestDetailViewController.onClickPhoneLabel))
        phoneNumber.isUserInteractionEnabled = true
        phoneNumber.addGestureRecognizer(phoneTap)
        
        self.titleLabel.text = request.requestName
        self.addressLabel.text = "\(request.requestAddress)\n"
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
            showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "ไม่สามารถเข้าถึงตำแหน่งได้")
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
        
        guard Auth.auth().currentUser != nil else {
            self.rescueButton.isEnabled = true
            return
        }
        
        guard self.currentGeo != nil else {
            self.rescueButton.isEnabled = true
            return
        }
        
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
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                if (self.request.status == 0) {
                    let ref = Firestore.firestore().collection("requests").document(self.request.documentID)
                    
                    ref.getDocument { (document, error) in
                        if let document = document {
                            let created_at = document.get("created_at") as! Date
                            let read_at = Date()
                            let components = Calendar.current.dateComponents([.second], from: created_at, to: read_at)
                            let second_between = components.second!
                            print(second_between)
                            if (second_between > 30) {
                                print("timeout")
                                self.stopListening()
                                Firestore.firestore().collection("requests").document((self.request.documentID)).updateData([
                                    "status": 3
                                ]) { error in
                                    if let error = error {
                                        print(error.localizedDescription)
                                        self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดลองใหม่อีกครั้ง")
                                        self.rescueButton.isEnabled = true
                                        return
                                    } else {
                                        let alert = UIAlertController(title: "เกิดข้อผิดพลาด", message: "คำขอเกินเวลา", preferredStyle: UIAlertController.Style.alert)
                                        alert.addAction(UIAlertAction(title: "ตกลง", style: UIAlertAction.Style.default) { action in
                                            self.navigationController?.popToRootViewController(animated: true)
                                        })
                                        self.present(alert, animated: true, completion: nil)
                                        return
                                    }
                                }
                            } else {
                                print("rescue!")
                                let rescuerId = Auth.auth().currentUser?.uid
                                let rescuerRef = Firestore.firestore().collection("officers").whereField("officerId", isEqualTo: rescuerId!).limit(to: 1)
                                
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
                                            "rescuerLocation": self.currentGeo!,
                                            "status": 1
                                        ]) { err in
                                            if err != nil {
                                                print(err!.localizedDescription)
                                                self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดลองใหม่อีกครั้ง")
                                                self.rescueButton.isEnabled = true
                                                return
                                            } else {
                                                rescuer["location"] = self.currentGeo!
                                                let controller = RescueDetailViewController.fromStoryboard(request: self.request, rescuer: rescuer, requestId: self.requestId)
                                                self.stopListening()
                                                self.navigationController?.pushViewController(controller, animated: true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
            } else {
                self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ต")
                self.rescueButton.isEnabled = true
                return
            }
            
        }))
        
        self.rescueButton.isEnabled = true
        self.present(alert, animated: true, completion: nil)
    
    }
    
    private func startListening() {
        if (CheckInternet.Connection()) {
            let requestRef = Firestore.firestore().collection("requests").document(requestId)
            statusListener = requestRef.addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print (error.localizedDescription)
                    self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ต")
                    return
                }
                guard let snapshot = snapshot else { return }
                let requestData = snapshot.data()
                self.request.status = requestData?["status"] as! Int
                
                guard self.request.status == 0 else {
                    let title = "เกิดข้อผิดพลาด"
                    let completing = "คำขอเสร็จสิ้นแล้ว"
                    let canceling = "คำขอถูกยกเลิก"
                    var message = ""
                    
                    if self.request.status == 2 {
                        message = completing
                    } else if self.request.status == 3 {
                        message = canceling
                    }
                    
                    if (self.request.status != 1) {
                        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "ตกลง", style: UIAlertAction.Style.default) { action in
                            self.stopListening()
                            self.navigationController?.popToRootViewController(animated: true)
                        })
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                    return
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
                showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "ไม่สามารถเข้าถึงการโทรได้")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mapView.removeAnnotations([srcPin, desPin])
        
        let requestLocation = request.requestLocation
        let location = locations.last! as CLLocation
        currentGeo = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        let src = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let des = CLLocationCoordinate2D(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
        
        srcPin.coordinate = src
        srcPin.title = "คุณอยู่ที่นี่"
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
        print(error.localizedDescription)
        showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "ไม่สามารถเข้าถึงตำแหน่งได้")
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        return renderer
    }
    
}
