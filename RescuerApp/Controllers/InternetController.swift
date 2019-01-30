//
//  InternetController.swift
//  RescuerApp
//
//  Created by CNC on 28/1/2562 BE.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class InternetController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tryTapped(_ sender: Any) {
        
        if (CheckInternet.Connection()) {
            Auth.auth().addStateDidChangeListener { (auth, user) in
                if user != nil {
                    
                    guard let user = Auth.auth().currentUser else {
                        return
                    }
                    let rescuerID = user.uid
                    let query = Firestore.firestore().collection("requests")
                        .whereField("rescuerID", isEqualTo: rescuerID)
                        .order(by: "created_at", descending: true).limit(to: 1)
                    
                    query.getDocuments { (snapshot, error) in
                        if let error = error {
                            print("Oh no! Got an error! \(error.localizedDescription)")
                            return
                        }
                        
                        guard let snapshot = snapshot else { return }
                        let requestDocuments = snapshot.documents
                        
                        if (requestDocuments.count == 0) {
                            self.toMainPage()
                            return
                        } else {
                            let requestDocument = requestDocuments[0]
                            print("I have this request \(requestDocument.data())")
                            
                            if (requestDocument.get("status") as! Int == 1) {
                                let request = Request(document: requestDocument)
                                let rescuer = requestDocument.data()
                                let requestID = request?.documentID
                                self.toMapPage(request: request!, rescuer: rescuer, requestID: requestID!)
                                return
                            } else {
                                self.toMainPage()
                                return
                            }
                        }
                    }
                    
                } else {
                    self.toSignInPage()
                    return
                }
            }
        }
        
    }
    
    func toMainPage() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "TabBarController")
        present(vc, animated: true, completion: nil)
    }
    
    func toMapPage(request: Request, rescuer: [String: Any], requestID: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tab = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        let navi = tab.viewControllers![0] as! UINavigationController
        let map = RescueDetailViewController.fromStoryboard(request: request, rescuer: rescuer, requestId: requestID)
        navi.pushViewController(map, animated: true)
        present(tab, animated: true, completion: nil)
    }
    
    func toSignInPage() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SignInController")
        present(vc, animated: true, completion: nil)
    }
    
}
