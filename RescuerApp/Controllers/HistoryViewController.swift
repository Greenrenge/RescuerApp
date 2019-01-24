//
//  HistoryViewController.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var historyData: [Request] = []
    var historyListener: ListenerRegistration?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if  let arrayOfTabBarItems = self.tabBarController?.tabBar.items as AnyObject as? NSArray,let tabBarItem = arrayOfTabBarItems[0] as? UITabBarItem {
            tabBarItem.isEnabled = true
        }
        startListening()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListening()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        let icon = UIImage(named: "padlock")?.withRenderingMode(.alwaysOriginal)
        let logoutButton = UIBarButtonItem(image: icon, style: UIBarButtonItem.Style.plain, target: self, action: #selector(HistoryViewController.logout))
        self.navigationItem.rightBarButtonItem = logoutButton
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell",
                                                 for: indexPath) as! HistoryTableViewCell
        cell.populate(name: "Loading...", address: "Loading...")
        
        let request = historyData[indexPath.row]
        
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
                
                cell.populate(name: name, address: address)
            }
            else {
                print("Problem with the data received from geocoder")
                cell.populate(name: "Not Founded", address: "Not Founded")
            }
        })
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let request = historyData[indexPath.row]
        let controller = HistoryDetailViewController.fromStoryboard(request: request)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    private func startListening() {
        let rescuerId = Auth.auth().currentUser?.uid
        let rescuerRef = Firestore.firestore().collection("officers").whereField("officerId", isEqualTo: rescuerId!)
        rescuerRef.getDocuments { (document, error) in
            if let document = document {
                let docId = document.documents[0].documentID
                let historyRef = Firestore.firestore().collection("officers").document(docId).collection("histories")
                self.historyListener = historyRef.addSnapshotListener { (snapshot, error) in
                    if let error = error {
                        print ("I got an error retrieving requests: \(error)")
                        return
                    }
                    guard let snapshot = snapshot else { return }
                    self.historyData = []
                    for requestDocument in snapshot.documents {
                        if let newRequest = Request(document: requestDocument) {
                            self.historyData.append(newRequest)
                        }
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func stopListening() {
        historyListener?.remove()
        historyListener = nil
    }
    
    @objc private func logout(sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            self.dismiss(animated: true, completion: nil)
        } catch let err {
            print(err)
        }
    }

}
