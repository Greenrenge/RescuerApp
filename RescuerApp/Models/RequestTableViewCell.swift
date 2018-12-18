//
//  RequestTableViewCell.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit

class RequestTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func populate(name: String, address: String) {
        self.name.text = name
        self.address.text = address
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
