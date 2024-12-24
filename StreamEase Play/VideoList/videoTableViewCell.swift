//
//  videoTableViewCell.swift
//  StreamEase Play
//
//  Created by Unique Consulting Firm on 22/12/2024.
//

import UIKit

class videoTableViewCell: UITableViewCell {

    @IBOutlet weak var videoimage: UIImageView!
    @IBOutlet weak var titlelb: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
