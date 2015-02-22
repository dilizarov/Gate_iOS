//
//  KeyShareProvider.swift
//  Gate
//
//  Created by David Ilizarov on 2/21/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

class KeyShareProvider: NSObject, UIActivityItemSource {
   
    var placeholder: String!
    var key: String!
    
    init(placeholder: String, key: String) {
        self.placeholder = placeholder
        self.key = key
    
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return NSString(string: placeholder)
    }
        
    func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        if activityType == UIActivityTypeMessage {
            return NSString(string: key)
        } else {
            return NSString(string: placeholder)
        }
    }
}
