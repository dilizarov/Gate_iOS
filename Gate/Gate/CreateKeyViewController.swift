//
//  CreateKeyViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/26/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class CreateKeyViewController: MyViewController, UITableViewDelegate, UITableViewDataSource {

    // Any keys made will be stored to display back on the previous viewcontroller upon dismissal.
    var keys = [Key]()
    
    var gates = [Gate]()
    var selectedGates = [String: Gate]()
    var fadedCheckMarkColor: UIColor!
    var checkMarkColor: UIColor!
    
    var refreshButton: UIBarButtonItem!
    
    var loadingIndicator: UIActivityIndicatorView!
    
    var alertController: MyAlertController?
    
    var delegate : AddKeysDelegate?
    
    var buttonTapped = false
    
    @IBOutlet var gatesTable: UITableView!
    @IBAction func tapForKey(sender: AnyObject) {
        var gateIds = [String](selectedGates.keys)
        if (gateIds.isEmpty) {
            iToast.makeText(" You must unlock at least one Gate").setDuration(3000).setGravity(iToastGravityCenter).show()
        } else {
            var hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            hud.labelText = "Robots processing..."
            self.buttonTapped = true
            processGatesForKey(gateIds)
        }
    }
    @IBOutlet var noGatesText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBar()
        
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        
        loadingIndicator.center = CGPointMake(self.view.center.x, self.view.center.y)
        
        self.view.addSubview(loadingIndicator)
        
        fadedCheckMarkColor = UIColor.gateBlueColor().colorWithAlphaComponent(0.3)
        checkMarkColor = UIColor.gateBlueColor()
        
        if gates.count > 0 {
            gatesTable.reloadData()
        } else {
            requestDataAndPopulate(false)
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
        navTitle.text = "Select Gates To Share"
        
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gates.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell = self.gatesTable.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        
        var gateName = cell.viewWithTag(10)! as UILabel
        
        gateName.text = self.gates[indexPath.row].name
        
        cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        cell.tintColor = fadedCheckMarkColor
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = self.gatesTable.cellForRowAtIndexPath(indexPath) {
            var gate = gates[indexPath.row]
            
            selectedGates[gate.id] = gate
            cell.tintColor = checkMarkColor
        }
        
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = self.gatesTable.cellForRowAtIndexPath(indexPath) {
            var gate = gates[indexPath.row]
            
            selectedGates[gate.id] = nil
            cell.tintColor = fadedCheckMarkColor
        }
        
    }
    
    func requestDataAndPopulate(refreshing: Bool) {
        refreshButton.enabled = false
        startLoading()
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params : Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/gates.json", parameters: params,
            success: {(response: HTTPResponse) in
                
                self.gates = []
                self.selectedGates.removeAll(keepCapacity: false)
                
                var jsonGates = response.responseObject!["gates"]
                
                let unwrappedGates = jsonGates as [Dictionary<String, AnyObject>]
                
                for var i = 0; i < unwrappedGates.count; i++ {
                    var jsonGate = unwrappedGates[i]
                    
                    var gate = Gate(id: jsonGate["external_id"] as String,
                        name: jsonGate["name"] as String,
                        usersCount: jsonGate["users_count"] as Int,
                        creator: (jsonGate["creator"] as Dictionary<String, String>)["name"]!,
                        generated: jsonGate["generated"] as Bool,
                        attachedToSession: jsonGate["session"] as Bool)
                    
                    self.gates.append(gate)
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingIndicator.stopAnimating()
                    
                    if self.gates.count == 0 {
                        self.noGatesText.text = "No gates yet"
                        self.noGatesText.alpha = 1.0
                    } else {
                        self.noGatesText.alpha = 0.0
                    }
                    
                    self.gatesTable.reloadData()
                    
                    if refreshing {
                        self.gatesTable.setContentOffset(CGPointZero, animated: false)
                    }
                    
                    self.refreshButton.enabled = true
                })
                
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingIndicator.stopAnimating()
                    
                    if self.gates.count == 0 {
                        if response == nil {
                            self.noGatesText.text = "We couldn't connect to the internet"
                        } else {
                            self.noGatesText.text = "Something went wrong"
                        }
                        
                        self.noGatesText.alpha = 1.0
                    }
                    
                    iToast.makeText(" " + String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                    
                    self.refreshButton.enabled = true
                })
            }
        )
        
    }
    
    func startLoading() {
        noGatesText.alpha = 0.0
        loadingIndicator.startAnimating()
    }
    
    func refresh() {
        requestDataAndPopulate(true)
    }
    
    func dismiss() {
        self.delegate?.addKeys(keys)
        
        (UIApplication.sharedApplication().delegate as AppDelegate).toggledViewController = nil
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func processGatesForKey(gateIds: [String]) {
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params: Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        var gatesArray = [ "gates" : gateIds ]
        
        params["key"] = gatesArray
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.POST("https://infinite-river-7560.herokuapp.com/api/v1/keys.json", parameters: params,
            success: { (response: HTTPResponse) in
                
                var jsonKeyData = response.responseObject!["key"] as Dictionary<String, AnyObject>
                
                var gateNames = [String]()
                var jsonGates = jsonKeyData["gates"] as [Dictionary<String, AnyObject>]
                
                for var i = 0; i < jsonGates.count; i++ {
                    gateNames.append(jsonGates[i]["name"] as String)
                }

                var key = Key(key: jsonKeyData["key"] as String
, gateNames: gateNames, timeUpdated: jsonKeyData["updated_at"] as String)
                self.keys.append(key)
                
                self.alertController = MyAlertController(title: key.key, message: "This key unlocks " + key.gatesList() + "\n\n" + "The key expires 3 days after inactivity", preferredStyle: .Alert)
                
                let shareAction = UIAlertAction(title: "Share", style: .Default, handler: { (alert: UIAlertAction!) in

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
                
                dispatch_async(dispatch_get_main_queue(), {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    
                    self.presentViewController(self.alertController!, animated: true, completion: nil)
                })
            },
            failure: { (error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    
                    self.buttonTapped = false
                    
                    iToast.makeText(" " + String.prettyErrorMessage(response)).setDuration(3000).setGravity(iToastGravityCenter).show()
                })
            }
        )
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
