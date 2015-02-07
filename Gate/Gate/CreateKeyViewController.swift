//
//  CreateKeyViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/26/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class CreateKeyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var gates = [Gate]()
    var selectedGates = [String: Gate]()
    var fadedCheckMarkColor: UIColor!
    var checkMarkColor: UIColor!
    
    @IBOutlet var gatesTable: UITableView!
    @IBAction func tapForKey(sender: AnyObject) {
        if (selectedGates.isEmpty) {
            iToast.makeText(" You must unlock at least one Gate").setDuration(3000).setGravity(iToastGravityCenter).show()
        } else {
            
            var hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            hud.labelText = "Robots processing..."
            processGatesForKey()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBar()
        
        fadedCheckMarkColor = UIColor.gateBlueColor().colorWithAlphaComponent(0.3)
        checkMarkColor = UIColor.gateBlueColor()
        
        gatesTable.reloadData()
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
        navTitle.text = "Select Gates To Unlock..."
        
        navbarView.addSubview(navTitle)
        
        navBar.addSubview(navbarView)
        
        var navigationItem = UINavigationItem()
        
        var backButton = UIBarButtonItem(image: UIImage(named: "Back"), style: .Plain, target: self, action: Selector("dismiss"))
        
        backButton.tintColor = UIColor.whiteColor()
        
        navigationItem.leftBarButtonItem = backButton
        
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
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    
    func processGatesForKey() {
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params: Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "09b19f4a-6e4d-475a-b7c8-a369c60e9f83" ]
        
        var gatesArray = [ "gates" : [String](selectedGates.keys) ]
        
        params["key"] = gatesArray
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.POST("https://infinite-river-7560.herokuapp.com/api/v1/keys.json", parameters: params,
            success: { (response: HTTPResponse) in
                
                var jsonKeyData = response.responseObject!["key"] as Dictionary<String, AnyObject>
                
                var key = jsonKeyData["key"] as String
                var gates = jsonKeyData["gates"] as [Dictionary<String, AnyObject>]
                
                var numOfGates = gates.count
                
                var gatesString = ""
                
                if numOfGates == 1 {
                    gatesString += gates[0]["name"] as String
                } else if numOfGates == 2 {
                    gatesString += (gates[0]["name"] as String) + " and " + (gates[1]["name"] as String)
                } else if numOfGates > 2 {
                    for var i = 0; i < numOfGates; i++ {
                        if i != 0 {
                            gatesString += ", "
                        }
                        
                        if i == numOfGates - 1 {
                            gatesString += "and "
                        }
                        
                        gatesString += gates[i]["name"] as String
                    }
                }
                
                let alertController = UIAlertController(title: key, message: "This key unlocks " + gatesString + "\n\n" + "The key expires 3 days after inactivity", preferredStyle: .Alert)
                
                let shareAction = UIAlertAction(title: "Share", style: .Default, handler: { (alert: UIAlertAction!) in
                    
                        var sharingItems = [AnyObject]()
                        sharingItems.append(NSString(string: "Use " + key + " to #unlock " + gatesString + " on #Gate\n\nhttp://unlockgate.today"))
                    
                        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
                    
                        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr, UIActivityTypePostToVimeo, UIActivityTypeAirDrop]
                    
                        self.presentViewController(activityViewController, animated: true, completion: nil)

                })
                
                alertController.addAction(shareAction)
                
                dispatch_async(dispatch_get_main_queue(), {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                })
            },
            failure: { (error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    
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
