//
//  SignInViewController.swift
//  RescuerApp
//
//  Created by CNC on 17/12/2561 BE.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {
    
    
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                self.performSegue(withIdentifier: "signed", sender: nil)
            }
        }
    }
    
    @IBAction func signInTapped(_ sender: Any) {
        if let email = emailText.text, let password = passwordText.text {
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.performSegue(withIdentifier: "signed", sender: nil)
            }
        }
    }

}
