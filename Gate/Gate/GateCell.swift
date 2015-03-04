//
//  GateCell.swift
//  Gate
//
//  Created by David Ilizarov on 3/3/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

class GateCell: UITableViewCell {

    var gate: Gate!
    
    @IBOutlet var gateName: UILabel!
    @IBOutlet var gatekeeperCount: UILabel!
    @IBOutlet var generatedFlag: UIImageView!
    
    func configureViews(gate: Gate) {
        self.gate = gate
        
        self.gateName.text = gate.name
    
        if gate.usersCount.toInt() == 1 {
            gatekeeperCount.text = "1 Gatekeeper"
        } else {
            gatekeeperCount.text = gate.usersCount + " Gatekeepers"
        }
        
        if gate.generated {
            generatedFlag.alpha = 1.0
        } else {
            generatedFlag.alpha = 0.0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
