//
//  Extensions.swift
//  Gate
//
//  Created by David Ilizarov on 1/28/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import Foundation

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
}

extension String {
    
    func toNSDate() -> NSDate {
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        return formatter.dateFromString(self)!
    }
    
}