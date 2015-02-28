//
//  HqViewController.swift
//  Gate
//
//  Created by David Ilizarov on 2/25/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

protocol AddKeysDelegate {
    func addKeys(keys: [Key])
}

class HqViewController: MyViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, AddKeysDelegate {

    var keys = [Key]()
    
    var gates = [Gate]()
    
    var refreshButton: UIBarButtonItem!
    
    var loadingIndicator: UIActivityIndicatorView!
    
    var alertController: MyAlertController?
    
    var buttonTapped = false
    
    var deleteController: MyAlertController!
    var deleteAlertDisplayed = false
    
    @IBOutlet var keysList: UITableView!
    @IBOutlet var noKeysText: UILabel!
    @IBAction func createKeyAction(sender: AnyObject) {
        performSegueWithIdentifier("createKey", sender: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBar()
        
        keysList.rowHeight = UITableViewAutomaticDimension
        
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        
        loadingIndicator.center = CGPointMake(self.view.center.x, self.view.center.y)
        
        self.view.addSubview(loadingIndicator)
        
        var longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("handleLongPress:"))
        longPressGestureRecognizer.minimumPressDuration = 1.5
        longPressGestureRecognizer.delegate = self
        keysList.addGestureRecognizer(longPressGestureRecognizer)
        
        requestDataAndPopulate(false)
    }
    
    override func viewWillAppear(animated: Bool) {
        (UIApplication.sharedApplication().delegate as AppDelegate).toggledViewController = self
        
        if keys.count > 0 {
            keysList.reloadData()
        }
    }
    
    func setupNavBar() {
        var navBar: UINavigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, 64))
        
        navBar.barTintColor = UIColor.blackColor()
        navBar.translucent = false
        
        var navbarView = UIView()
        
        var navTitle = UILabel()
        navTitle.frame = CGRect(x: 0, y: 20, width: self.view.bounds.width, height: 44)
        navTitle.textColor = UIColor.whiteColor()
        navTitle.textAlignment = NSTextAlignment.Center
        navTitle.text = "Keys"
        
        navbarView.addSubview(navTitle)
        
        navBar.addSubview(navbarView)
        
        var navigationItem = UINavigationItem()
        
        var backButton = UIBarButtonItem(image: UIImage(named: "Back"), style: .Plain, target: self, action: Selector("dismiss"))
        
        backButton.tintColor = UIColor.whiteColor()
        
        navigationItem.leftBarButtonItem = backButton
        
        refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: Selector("refresh"))
        
        refreshButton.tintColor = UIColor.whiteColor()
        
        navigationItem.rightBarButtonItem = refreshButton
        
        self.view.addSubview(navBar)
        
        navBar.pushNavigationItem(navigationItem, animated: false)
    }
    
    func requestDataAndPopulate(refreshing: Bool) {
        refreshButton.enabled = false
        startLoading()
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params : Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/keys.json", parameters: params,
            success: {(response: HTTPResponse) in
                
                self.keys = []
                
                var jsonKeys = response.responseObject!["keys"]
                
                let unwrappedKeys = jsonKeys as [Dictionary<String, AnyObject>]
                
                for var i = 0; i < unwrappedKeys.count; i++ {
                    var jsonKey = unwrappedKeys[i]
                    
                    var gateNames = [String]()
                    var jsonGates = jsonKey["gates"] as [Dictionary<String, AnyObject>]
                    for var j = 0; j < jsonGates.count; j++ {
                        gateNames.append(jsonGates[j]["name"] as String)
                    }
                    
                    var key = Key(key: jsonKey["key"] as String, gateNames: gateNames, timeUpdated: jsonKey["updated_at"] as String)
                    
                    self.keys.append(key)
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingIndicator.stopAnimating()
                    
                    if self.keys.count == 0 {
                        self.noKeysText.text = "No keys yet"
                        self.noKeysText.alpha = 1.0
                    } else {
                        self.noKeysText.alpha = 0.0
                    }
                    
                    self.keysList.reloadData()
                    
                    if refreshing {
                        self.keysList.setContentOffset(CGPointZero, animated: false)
                    }
                    
                    self.refreshButton.enabled = true
                })
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingIndicator.stopAnimating()
                    
                    if self.keys.count == 0 {
                        if response == nil {
                            self.noKeysText.text = "We couldn't connect to the internet"
                        } else {
                            self.noKeysText.text = "Something went wrong"
                        }
                        
                        self.noKeysText.alpha = 1.0
                    }
                    
                    iToast.makeText(" " + String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                    
                    
                    self.refreshButton.enabled = true
                })
            }
        )
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.keys.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = self.keysList.dequeueReusableCellWithIdentifier("key") as KeyCell
        
        if self.keys.count > indexPath.row {
            
            var key = self.keys[indexPath.row]
            
            cell.configureViews(key)
            
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        if indexPath.row < keys.count {
            var key = keys[indexPath.row]
            
            self.buttonTapped = true
            
            self.alertController = MyAlertController(title: key.key, message: "This key unlocks " + key.gatesList(), preferredStyle: .Alert)
            
            let shareAction = UIAlertAction(title: "Share", style: .Default, handler: {
                (alert: UIAlertAction!) in
                
                var stringToShare = KeyShareProvider(placeholder: "Use " + key.key + " to #unlock " + key.gatesList() + " on #Gate\n\nhttp://unlockgate.today", key: key.key)
                
                var sharingItems = [AnyObject]()
                sharingItems.append(stringToShare)
                
                let activityViewController = MyActivityViewController(activityItems: sharingItems, applicationActivities: nil)
                
                activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr, UIActivityTypePostToVimeo, UIActivityTypeAirDrop]
                
                activityViewController.completionWithItemsHandler = {
                    (activityType: String!, completed: Bool, returnedItems: [AnyObject]!, activityError: NSError!) in
                    
                    self.buttonTapped = false
                    
                }
                
                self.presentViewController(activityViewController, animated: true, completion: nil)
            })
            
            var cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            
            self.alertController!.addAction(cancelAction)
            self.alertController!.addAction(shareAction)
            
            self.presentViewController(self.alertController!, animated: true, completion: nil)
        }
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if (gestureRecognizer.state == UIGestureRecognizerState.Began) {
            var point = gestureRecognizer.locationInView(keysList)
            var indexPath = keysList.indexPathForRowAtPoint(point)
            
            if (indexPath != nil) {
                var unwrappedIndexPath = indexPath!
                
                var key = keys[unwrappedIndexPath.row]
                
                deleteController = MyAlertController(title: "Delete \(key.key)", message: "Are you sure you want to delete this key? It unlocks \(key.gatesList()).", preferredStyle: .ActionSheet)
                
                let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: {
                    (alert: UIAlertAction!) -> Void in
                    
                    self.deleteAlertDisplayed = false
                    self.deleteKey(key, index: unwrappedIndexPath.row)
                    
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { (alert: UIAlertAction!) in
                    self.deleteAlertDisplayed = false
                })
                
                deleteController.addAction(deleteAction)
                deleteController.addAction(cancelAction)
                
                deleteAlertDisplayed = true
                self.presentViewController(deleteController, animated: true, completion: nil)
            }
        }
    }
    
    func deleteKey(key: Key, index: Int) {
        keys.removeAtIndex(index)
        keysList.reloadData()
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        request.DELETE("https://infinite-river-7560.herokuapp.com/api/v1/keys/" + key.key.stringByReplacingOccurrencesOfString("-", withString: "", options: nil, range: nil) + ".json", parameters: params,
            success: {(response: HTTPResponse) in
                // Don't do anything, preprocessed.
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                
                // Add removed Gate back into list.
                self.keys.insert(key, atIndex: index)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.keysList.reloadData()
                    
                    iToast.makeText(" " + String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                })
            }
        )
    }
    
    func startLoading() {
        noKeysText.alpha = 0.0
        loadingIndicator.startAnimating()
    }
    
    func refresh() {
        requestDataAndPopulate(true)
    }
    
    func addKeys(keys: [Key]) {
        self.keys.extend(keys)
        
        dispatch_async(dispatch_get_main_queue(), {
            self.keysList.reloadData()
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "createKey" {
            var destination = segue.destinationViewController as CreateKeyViewController
            
            destination.delegate = self
            destination.gates = gates
            (UIApplication.sharedApplication().delegate as AppDelegate).toggledViewController = destination
        }
    }
    
    func dismiss() {
        (UIApplication.sharedApplication().delegate as AppDelegate).toggledViewController = nil
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
