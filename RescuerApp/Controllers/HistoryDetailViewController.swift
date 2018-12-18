//
//  HistoryDetailViewController.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit

class HistoryDetailViewController: UIViewController {

    @IBOutlet weak var phoneLabel: UILabel!
    private var request: Request!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phoneLabel.text = request.phoneNumber
    }
    
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil),
                               request: Request) -> HistoryDetailViewController {
        let controller =
            storyboard.instantiateViewController(withIdentifier: "HistoryDetailViewController")
                as! HistoryDetailViewController
        controller.request = request
        return controller
    }
    
}
