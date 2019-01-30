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
        let icon = UIImage(named: "logout")?.withRenderingMode(.alwaysOriginal)
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
        
        cell.populate(name: request.requestName, address: request.requestAddress)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let request = historyData[indexPath.row]
        let controller = HistoryDetailViewController.fromStoryboard(request: request)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "ลบ", message: "คุณต้องการลบประวัติการช่วยเหลือใช่หรือไม่ ?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ไม่ใช่", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "ใช่", style: .default, handler: { action in
            if (CheckInternet.Connection()) {
                if editingStyle == .delete {
                    let documentID = self.historyData[indexPath.row].documentID
                    let rescuerId = Auth.auth().currentUser?.uid
                    let rescuerRef = Firestore.firestore().collection("officers").whereField("officerId", isEqualTo: rescuerId!)
                    rescuerRef.getDocuments { (document, error) in
                        if let document = document {
                            let docId = document.documents[0].documentID
                            let historyRef = Firestore.firestore().collection("officers").document(docId).collection("histories")
                            historyRef.document(documentID).delete()
                        }
                    }
                }
            }
            else {
                self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ต")
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func startListening() {
        if (CheckInternet.Connection()) {
//            let historyRef = Firestore.firestore().collection("officers").document(self.docId!).collection("histories")
//            self.historyListener = historyRef.addSnapshotListener { (snapshot, error) in
//                if let error = error {
//                    print ("I got an error retrieving requests: \(error)")
//                    return
//                }
//                guard let snapshot = snapshot else { return }
//                self.historyData = []
//                for requestDocument in snapshot.documents {
//                    if let newRequest = Request(document: requestDocument) {
//                        self.historyData.append(newRequest)
//                    }
//                }
//                self.tableView.reloadData()
//            }
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
        } else {
            self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ต")
        }
    }
    
    private func stopListening() {
        historyListener?.remove()
        historyListener = nil
    }
    
    private func showMsg(msgTitle: String, msgText: String) {
        let alert = UIAlertController(title: msgTitle, message: msgText, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func logout(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "ออกจากระบบ", message: "คุณต้องการออกจากระบบใช่หรือไม่", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ไม่ใช่", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "ใช่", style: .default, handler: {
            action in
            do {
                try Auth.auth().signOut()
                self.dismiss(animated: true, completion: nil)
            } catch let err {
                print(err)
                self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดลองใหม่อีกครั้ง")
            }
        }))
    }

}
