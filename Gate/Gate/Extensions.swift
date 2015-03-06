//
//  Extensions.swift
//  Gate
//
//  Created by David Ilizarov on 1/28/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import Foundation
import SwiftHTTP

extension NSDate {
    func yearsFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitYear, fromDate: date, toDate: self, options: nil).year
    }
    
    func monthsFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitMonth, fromDate: date, toDate: self, options: nil).month
    }
    
    func weeksFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitWeekOfYear, fromDate: date, toDate: self, options: nil).weekOfYear
    }
    
    func daysFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitDay, fromDate: date, toDate: self, options: nil).day
    }
    
    func hoursFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitHour, fromDate: date, toDate: self, options: nil).hour
    }
    
    func minutesFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitMinute, fromDate: date, toDate: self, options: nil).minute
    }
    
    func secondsFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitSecond, fromDate: date, toDate: self, options: nil).second
    }
    
    func offsetFrom(date:NSDate) -> String {
        
        if yearsFrom(date) > 0 {
            return "\(yearsFrom(date))y"
        } else if weeksFrom(date) > 0 {
            return "\(weeksFrom(date))w"
        } else if daysFrom(date) > 0 {
            return "\(daysFrom(date))d"
        } else if hoursFrom(date) > 0 {
            return "\(hoursFrom(date))h"
        } else if minutesFrom(date) > 0 {
            return "\(minutesFrom(date))m"
        } else if secondsFrom(date) > 0 {
            return "\(secondsFrom(date))s"
        } else {
            return "1s"
        }

    }
    
    func minusDays(days: Int) -> NSDate {
        var dateComponents = NSDateComponents()
        dateComponents.day = -days
        return NSCalendar.currentCalendar().dateByAddingComponents(dateComponents, toDate: self, options: nil)!
        
    }
    
    func stringFromDate() -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        return formatter.stringFromDate(self)
    }
}

extension String {
    
    func toNSDate() -> NSDate {
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        return formatter.dateFromString(self)!
    }
    
    subscript (i: Int) -> Character {
        return self[advance(self.startIndex, i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: advance(startIndex, r.startIndex), end: advance(startIndex, r.endIndex)))
    }
    
    static func shortenForTitle(string: String) -> String {
        var wordsToSkip = [ "a" : true, "an" : true, "at" : true, "but" : true, "by" : true, "for" : true, "in" : true, "nor" : true, "of" : true, "on" : true, "or" : true, "so" : true, "the" : true, "to" : true, "up" : true, "yet" : true ]
        
        if NSString(string: string).length <= 15 {
            return string
        } else if NSString(string: string).length <= 18 {
            return string[0...13] + "..."
        } else {
            var stringArray = split(string) { $0 == " " }
            
            if stringArray.count >= 4 {
                
                var compactedArray = [String]()
                
                for var i = 0; i < stringArray.count; i++ {
                    if wordsToSkip[stringArray[i]] == nil {
                        compactedArray.append(stringArray[i])
                    }
                }
                
                var result = ""
                
                for var i = 0; i < compactedArray.count; i++ {
                    if i != 0 { result += "." }
                    var firstLetter = compactedArray[i][0] as String
                    result += firstLetter.capitalizedString
                }
                
                if NSString(string: result).length > 15 {
                    result = result[0...14] + "..."
                }
                
                return result
            } else {
                return string[0...13] + "..."
            }
        }
    }
    
    static func prettyErrorMessage(response: HTTPResponse?) -> String {
        var errorText = ""
        
        if response != nil && response!.statusCode != nil {
            var statusCode = response?.statusCode!
            
            if statusCode >= 500 {
                errorText += "We made a mistake somewhere. Robots are investigating."
            } else if statusCode == 401 {
                errorText += "Gatekeeper, you are unauthorized to perform this action"
            } else {
                if response!.responseObject != nil {
                    var errors = (response!.responseObject as Dictionary<String, AnyObject>)["errors"] as [String]
                    
                    for var i = 0; i < errors.count; i++ {
                        if (i != 0) { errorText += "\n" }
                        errorText += errors[i]
                    }
                }
            }
            
        } else {
            errorText += "We couldn't connect to the internet"
        }
        
        if errorText == "" {
            errorText = "Something went wrong"
        }

        return errorText
    }
    
}

extension UIColor {
    
    class func gateBlueColor() -> UIColor {
        var red: CGFloat = 0.0862745
        var green: CGFloat = 0.258824
        var blue: CGFloat = 0.458824
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
}