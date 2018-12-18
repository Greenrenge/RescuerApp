//
//  HistoryViewController.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var historyData: [Request] = []
    var historyListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        startListeningForRestaurants()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningForRestaurants()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyData.count
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
//    {
//        return 100.0
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell",
                                                 for: indexPath) as! HistoryTableViewCell
        let request = historyData[indexPath.row]
        cell.populate(request: request)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let request = historyData[indexPath.row]
        let controller = HistoryDetailViewController.fromStoryboard(request: request)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    private func startListeningForRestaurants() {
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
    
    private func stopListeningForRestaurants() {
        historyListener?.remove()
        historyListener = nil
    }

}
