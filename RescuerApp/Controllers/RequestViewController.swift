//
//  RequestViewController.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit
import FirebaseFirestore
import CoreLocation

class RequestViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var requestData: [Request] = []
    private var requestListener: ListenerRegistration?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        startListeningForRestaurants()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningForRestaurants()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
//
//        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
//        loadingIndicator.hidesWhenStopped = true
//        loadingIndicator.style = UIActivityIndicatorView.Style.gray
//        loadingIndicator.startAnimating();
//
//        alert.view.addSubview(loadingIndicator)
//        present(alert, animated: true, completion: nil)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "requestCell",
                                                 for: indexPath) as! RequestTableViewCell
        let request = requestData[indexPath.row]
        
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
        
//        dismiss(animated: false, completion: nil)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let request = requestData[indexPath.row]
        let controller = RequestDetailViewController.fromStoryboard(request: request, requestId: request.documentID)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    private func startListeningForRestaurants() {
        
        let basicQuery = Firestore.firestore().collection("requests").whereField("status", isEqualTo: 0).limit(to: 10)
        requestListener = basicQuery.addSnapshotListener { (snapshot, error) in
            if let error = error {
                print ("I got an error retrieving requests: \(error)")
                return
            }
            guard let snapshot = snapshot else { return }
            self.requestData = []
            for requestDocument in snapshot.documents {
                if let newRequest = Request(document: requestDocument) {
                    self.requestData.append(newRequest)
                }
            }
            self.tableView.reloadData()
        }
        
    }
    
    private func stopListeningForRestaurants() {
        requestListener?.remove()
        requestListener = nil
    }
    
}
