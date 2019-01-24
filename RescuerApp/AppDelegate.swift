//
//  AppDelegate.swift
//  RescuerApp
//
//  Created by CNC on 17/12/2561 BE.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if (CheckInternet.Connection()) {
            FirebaseApp.configure()
            
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
        } else {
            self.toNoInternet()
        }
        
        return true
    }
    
    func toNoInternet() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "NoInternetController")
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
    }
    
    func toMainPage() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "TabBarController")
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
    }
    
    func toMapPage(request: Request, rescuer: [String: Any], requestID: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tab = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        let navi = tab.viewControllers![0] as! UINavigationController
        let map = RescueDetailViewController.fromStoryboard(request: request, rescuer: rescuer, requestId: requestID)
        navi.pushViewController(map, animated: true)
        self.window?.rootViewController = tab
        self.window?.makeKeyAndVisible()
    }
    
    func toSignInPage() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SignInController")
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

