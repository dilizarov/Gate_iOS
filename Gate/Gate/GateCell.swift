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
    
        if gate.id == "aroundyou" {
            if gate.usersCount.toInt() == nil {
                if !(UIApplication.sharedApplication().delegate as AppDelegate).locationUpdating {
                    gatekeeperCount.text = "GPS disabled. Will use last known location."
                } else {
                    gatekeeperCount.text = ""
                }
            } else if gate.usersCount.toInt() == 0 {
                gatekeeperCount.text = "No Gatekeepers around"
            } else {
                setGatekeeperCountText()
            }
            
            generatedFlag.alpha = 1.0
        } else {
            setGatekeeperCountText()
            generatedFlag.alpha = 0.0
        }
    }
    
    func setGatekeeperCountText() {
        if gate.usersCount.toInt() == 1 {
            gatekeeperCount.text = "1 Gatekeeper"
        } else {
            gatekeeperCount.text = gate.usersCount + " Gatekeepers"
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layoutIfNeeded()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
