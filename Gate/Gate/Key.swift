//
//  Key.swift
//  Gate
//
//  Created by David Ilizarov on 2/25/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import Foundation

class Key {
    
    var key: String
    var gateNames: [String]
    var timeUpdated: NSDate
    
    init(key: String, gateNames: [String], timeUpdated: String) {
        self.key = key
        self.gateNames = gateNames
        self.timeUpdated = timeUpdated.toNSDate()
    }
    
    func gatesList() -> String {
        var len = gateNames.count
        
        var result = ""
        
        if len == 1 {
            result += gateNames[0]
        } else if len == 2 {
            result += gateNames[0] + " and " + gateNames[1]
        } else if len > 2 {
            for var i = 0; i < len; i++ {
                if i != 0 { result += ", " }
                if i == len - 1 { result += "and " }
                result += gateNames[i]
            }
        }
            
        return result
    }
    
    func expired() -> Bool {
        return timeUpdated.secondsFrom(NSDate().minusDays(3)) == 0
    }
    
    func expiresSoon() -> Bool {
        return timeUpdated.hoursFrom(NSDate().minusDays(3)) <= 24
    }
    
    func expireTime() -> String {
        var threeDaysAgo = NSDate().minusDays(3)
        
        var string = ""
        
        if timeUpdated.hoursFrom(threeDaysAgo) > 0 {
            if timeUpdated.hoursFrom(threeDaysAgo) == 1 {
                string += "1 hour"
            } else {
                string += "\(timeUpdated.hoursFrom(threeDaysAgo)) hours"
            }
        } else if timeUpdated.minutesFrom(threeDaysAgo) > 0 {
            if timeUpdated.minutesFrom(threeDaysAgo) == 1 {
                string += "1 minute"
            } else {
                string += "\(timeUpdated.minutesFrom(threeDaysAgo)) minutes"
            }
        } else if timeUpdated.secondsFrom(threeDaysAgo) > 0 {
            if timeUpdated.secondsFrom(threeDaysAgo) == 1 {
                string += "1 second"
            } else {
                string += "\(timeUpdated.secondsFrom(threeDaysAgo)) seconds"
            }
        }
        
        return string
    }
    
}