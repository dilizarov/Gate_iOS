//
//  AppDelegate.swift
//  Gate
//
//  Created by David Ilizarov on 1/23/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftHTTP

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var locationManager: CLLocationManager!
    var location: CLLocation?
    var lastGeneratedGatesUpdate: NSDate!
    var requestingGates = false
    
    var window: UIWindow?
    var mainViewController: MainViewController?
    // Used to handle getting back to mainViewController to trigger notification work.
    var toggledViewController: UIViewController?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        var pushSettings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil)
        
        application.registerUserNotificationSettings(pushSettings)
        
        application.registerForRemoteNotifications()
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        if launchOptions != nil && launchOptions![UIApplicationLaunchOptionsRemoteNotificationKey] != nil {
            var userInfo = launchOptions![UIApplicationLaunchOptionsRemoteNotificationKey] as Dictionary<NSObject, AnyObject>
            
            self.application(application, didReceiveRemoteNotification: userInfo)
        }
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = CLLocationDistance.abs(20)
        lastGeneratedGatesUpdate = NSDate()
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        var storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        var viewController : UIViewController!
        
        // Logged in? Head to Main, otherwise go to LoginRegister
        if NSUserDefaults.standardUserDefaults().objectForKey("auth_token") != nil {
            viewController = storyboard.instantiateViewControllerWithIdentifier("MainViewController") as? MainViewController
        } else {
            viewController = storyboard.instantiateViewControllerWithIdentifier("LoginRegisterViewController") as? LoginRegisterViewController
        }

        self.window?.rootViewController = viewController
        self.window?.makeKeyAndVisible()
        
        return true
    }
        
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    
        NSUserDefaults.standardUserDefaults().setObject(deviceToken.description, forKey: "device_token")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        var state = application.applicationState
        
        if state == UIApplicationState.Active {
            
            var alert = (userInfo["aps"] as Dictionary<String, AnyObject>)["alert"] as String
            
            var viewController =  toggledViewController != nil ? toggledViewController : mainViewController
            
            TSMessage.showNotificationInViewController(viewController,
                title: alert,
                type: TSMessageNotificationType.Message,
                duration: TSMessageNotificationDuration.Automatic,
                atPosition: TSMessageNotificationPosition.NavBarOverlay,
                canBeDismissedByUser: true,
                callback: {
                    self.processNotification(userInfo)
                }
            )

            
        } else if state == UIApplicationState.Inactive {
            processNotification(userInfo)
        }
    }
    
    func processNotification(userInfo: [NSObject : AnyObject]) {
        var notifType = userInfo["notification_type"] as Int
        if mainViewController != nil {
            mainViewController!.feedViewController.notifAttributes = userInfo
            mainViewController!.feedViewController.postId = userInfo["post_id"] as? String
            
            mainViewController!.feedViewController.notifType = notifType
            
            //UIActivityViewController
            NSNotificationCenter.defaultCenter().postNotificationName("dismissActivityForNotif", object: nil)
            
            dispatch_after(dispatch_time_t(2.00), dispatch_get_main_queue(), {
                NSNotificationCenter.defaultCenter().postNotificationName("dismissAlertForNotif", object: nil)
                
                dispatch_after(dispatch_time_t(2.00), dispatch_get_main_queue(), {
                    if self.toggledViewController != nil && self.toggledViewController is CreateKeyViewController {
                        (self.toggledViewController)?.dismissViewControllerAnimated(true, completion: {
                            NSNotificationCenter.defaultCenter().postNotificationName("dismissForNotif", object: nil)
                        })
                    } else {
                        NSNotificationCenter.defaultCenter().postNotificationName("dismissForNotif", object: nil)
                    }
                })
            })
        }
    }
    
    func bootUpLocationTracking() {
        switch CLLocationManager.authorizationStatus() {
            case .Authorized:
                locationManager.startUpdatingLocation()
            case .NotDetermined:
                locationManager.requestAlwaysAuthorization()
            case .AuthorizedWhenInUse, .Restricted, .Denied:
                let alertController = MyAlertController(
                    title: "Background Location Access Disabled",
                    message: "In order to unlock Gates while you're on the move, please open Gate's settings and set location access to 'Always'.",
                    preferredStyle: .Alert)
            
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                alertController.addAction(cancelAction)
            
                let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                    if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                        UIApplication.sharedApplication().openURL(url)
                    }
                }
                alertController.addAction(openAction)
            
                if toggledViewController != nil {
                    toggledViewController?.presentViewController(alertController, animated: true, completion: nil)
                } else {
                    mainViewController?.presentViewController(alertController, animated: true, completion: nil)
                }
        }
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .Authorized || status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if !locations.isEmpty {
            location = locations.last as? CLLocation
        }
        
        // 40 second interval between requests.
        if location != nil && NSDate().secondsFrom(lastGeneratedGatesUpdate) > 40 && !requestingGates {
            lastGeneratedGatesUpdate = NSDate()
            requestGates(location!)
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
    
    func requestGates(location: CLLocation!) {
        requestingGates = true
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        params["lat"] = "\(location.coordinate.latitude)"
        params["long"] = "\(location.coordinate.longitude)"
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.POST("https://infinite-river-7560.herokuapp.com/api/v1/generated_gates.json", parameters: params,
            success: {(response: HTTPResponse) in
                
                var updatedGates = [Gate]()
                
                var jsonGates = response.responseObject!["gates"]
                
                let unwrappedGates = jsonGates as [Dictionary<String, AnyObject>]
                
                for var i = 0; i < unwrappedGates.count; i++ {
                    var jsonGate = unwrappedGates[i]
                    
                    var gate = Gate(id: jsonGate["external_id"] as String,
                        name: jsonGate["name"] as String,
                        usersCount: jsonGate["users_count"] as Int,
                        creator: (jsonGate["creator"] as Dictionary<String, String>)["name"]!,
                        generated: jsonGate["generated"] as Bool)
                    
                    updatedGates.append(gate)
                }
                
                self.requestingGates = false
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    if updatedGates.isEmpty { return }
                    
                    self.mainViewController?.gatesViewController.gates = updatedGates
                    
                    if self.toggledViewController == nil && !self.mainViewController!.gatesViewController.loadingGates {
                        self.mainViewController?.gatesViewController.gatesTable.reloadData()
                    }
                })
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                self.requestingGates = false
            }
        )
    }

}

