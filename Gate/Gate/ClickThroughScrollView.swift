//
//  ClickThroughScrollView.swift
//  Gate
//
//  Created by David Ilizarov on 2/3/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

class ClickThroughScrollView: TPKeyboardAvoidingScrollView {

    var noClickThrough = false
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        
        if noClickThrough { return true }
        
        var subviews = self.subviews
        
        for var i = 0; i < subviews.count; i++ {
            
            var subview = subviews[i]
            
            if subview is PHFComposeBarView {
                
                var composeBar = subview as PHFComposeBarView
                
                if !composeBar.hidden && composeBar.alpha > 0 && composeBar.userInteractionEnabled && composeBar.pointInside(convertPoint(point, toView: composeBar), withEvent: event) {
                    return true
                }
            }
            
        }
        
        return false
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
