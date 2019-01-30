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
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signInButton.layer.cornerRadius = 10.0
        signInButton.layer.masksToBounds = true
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                self.performSegue(withIdentifier: "signed", sender: nil)
            }
        }
    }
    
    @IBAction func signInTapped(_ sender: Any) {
        signInButton.isEnabled = false
        if (CheckInternet.Connection()) {
            if let email = emailText.text, let password = passwordText.text {
                Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        let alert = UIAlertController(title: "เกิดข้อผิดพลาด", message: "โปรดลองใหม่อีกครั้ง", preferredStyle: UIAlertController.Style.alert)
                        self.present(alert, animated: true, completion: nil)
                    }
                    self.performSegue(withIdentifier: "signed", sender: nil)
                    self.signInButton.isEnabled = true
                }
            } else {
                self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดกรอกข้อมูลให้เรียบร้อย")
                signInButton.isEnabled = true
            }
        } else {
            self.showMsg(msgTitle: "เกิดข้อผิดพลาด", msgText: "โปรดเชื่อมต่ออินเทอร์เน็ต")
            signInButton.isEnabled = true
        }
    }
    
    func showMsg(msgTitle: String, msgText: String) {
        let alert = UIAlertController(title: msgTitle, message: msgText, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "ตกลง", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }


}
