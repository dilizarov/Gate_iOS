//
//  AppDelegate.swift
//  Gate
//
//  Created by David Ilizarov on 1/23/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var mainViewController: MainViewController?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        var pushSettings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil)
        
        application.registerUserNotificationSettings(pushSettings)
        
        application.registerForRemoteNotifications()
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        println("In the didfinishlaunchingwithoptions")
        
        if launchOptions != nil && launchOptions![UIApplicationLaunchOptionsRemoteNotificationKey] != nil {
            var userInfo = launchOptions![UIApplicationLaunchOptionsRemoteNotificationKey] as Dictionary<NSObject, AnyObject>
            
            self.application(application, didReceiveRemoteNotification: userInfo)
        }
        
        return true
    }
        
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    
        NSUserDefaults.standardUserDefaults().setObject(deviceToken.description, forKey: "device_token")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        var state = application.applicationState
        
        println("In didReceiveRemoteNotification")
        
        if state == UIApplicationState.Active {
            var alert = (userInfo["aps"] as Dictionary<String, AnyObject>)["alert"] as String
            
            if application.applicationState == UIApplicationState.Active {
                iToast.makeText(" " + alert).setDuration(2000).setGravity(iToastGravityBottom).show()
            }
        } else if state == UIApplicationState.Inactive {
            
            println("IN THE THING")
            
            var notifType = userInfo["notification_type"] as Int
            if mainViewController != nil {
                mainViewController!.feedViewController.postId = userInfo["post_id"] as? String
                mainViewController!.feedViewController.notifType = notifType
                
                NSNotificationCenter.defaultCenter().postNotificationName("handleNotification", object: nil)
            }
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        if mainViewController != nil {
            mainViewController?.feedViewController.backgroundRefresh(completionHandler)
        } else {
            completionHandler(UIBackgroundFetchResult.Failed)
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

