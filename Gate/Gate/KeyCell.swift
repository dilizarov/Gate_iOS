//
//  KeyCell.swift
//  Gate
//
//  Created by David Ilizarov on 2/25/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class KeyCell: UITableViewCell {
    
    var key: Key!
    
    @IBOutlet var keyText: UILabel!
    @IBOutlet var gatesList: UILabel!
    @IBOutlet var expiresSoonButton: UIButton!
    
    @IBAction func expiresSoonAction(sender: AnyObject) {
        var expireTime = key.expireTime();
        var toastText: String!
        
        if expireTime == "" {
            toastText = "This key is expired"
        } else {
            toastText = "This key expires in \(expireTime)"
        }
        
        iToast.makeText("\(toastText)").setGravity(iToastGravityCenter).setDuration(3000).show()
    }

    
    func configureViews(key: Key) {
        self.key = key
        
        self.keyText.text = key.key
        self.gatesList.text = key.gatesList();
        
        if key.expiresSoon() {
            expiresSoonButton.alpha = 1.0
        } else {
            expiresSoonButton.alpha = 0.0
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.layoutIfNeeded()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
