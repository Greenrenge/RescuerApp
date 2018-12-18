//
//  HistoryTableViewCell.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit

class HistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var phoneLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func populate(request: Request) {
        phoneLabel.text = request.phoneNumber
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
