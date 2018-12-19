//
//  HistoryTableViewCell.swift
//  RescuerApp
//
//  Created by CNC on 18/12/2561 BE.
//

import UIKit

class HistoryTableViewCell: UITableViewCell {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func populate(name: String, address: String) {
        nameLabel.text = name
        addressLabel.text = address
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = "Loading..."
        addressLabel.text = "Loading..."
    }

}
