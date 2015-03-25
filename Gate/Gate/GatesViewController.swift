//  GatesViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/24/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP
import CoreLocation

class GatesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    var gateName: UITextField!
    var createGateAlert: MyAlertController!
    var createGateAlertDisplayed = false
    var gates = [Gate]()
    var aroundYou: Gate!
    var refresher: ODRefreshControl!

    var loadingGates = false
    
    var gateOptionsController: MyAlertController!
    var leaveAlertDisplayed = false
    
    var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var noGatesText: UILabel!
    
    @IBOutlet var gatesTable: UITableView!
    @IBAction func viewAggregate(sender: AnyObject) {
        let parent = parentViewController as MainViewController
        
        parent.showFeed(nil)
    }
    
    @IBAction func createGate(sender: AnyObject) {

        createGateAlert = MyAlertController(title: "Create Gate", message: nil, preferredStyle: .Alert)
        
        createGateAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
            self.createGateAlertDisplayed = false
        }))
        
        createGateAlert.addAction(UIAlertAction(title: "Create", style: .Default, handler: {
            (action: UIAlertAction!) in
            
            self.createGateAlertDisplayed = false
            
            var potentialName = self.gateName.text
            
            potentialName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())

            self.createGate(potentialName)
            
        }))
        
        createGateAlert.addTextFieldWithConfigurationHandler({
            (textField: UITextField!) in
            
            textField.placeholder = "Gate name"
            textField.clearButtonMode = UITextFieldViewMode.WhileEditing
            textField.spellCheckingType = UITextSpellCheckingType.Default
            textField.autocapitalizationType = UITextAutocapitalizationType.Words
            
            textField.addTarget(self, action: "createGateTextChanged:", forControlEvents: .EditingChanged)
            self.gateName = textField
        })
        
        (createGateAlert.actions[1] as UIAlertAction).enabled = false
        
        createGateAlertDisplayed = true
        presentViewController(createGateAlert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("handleLongPress:"))
        longPressGestureRecognizer.minimumPressDuration = 1.0
        longPressGestureRecognizer.delegate = self
        gatesTable.addGestureRecognizer(longPressGestureRecognizer)
        
        gatesTable.rowHeight = UITableViewAutomaticDimension
        
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        
        loadingIndicator.center = self.view.center
        
        loadingIndicator.layer.zPosition = 5000
        
        self.view.addSubview(loadingIndicator)
        
        refresher = ODRefreshControl(inScrollView: self.gatesTable)
        refresher.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
        refresher.tintColor = UIColor.gateBlueColor()
        
        aroundYou = Gate(id: "aroundyou", name: "Around You")
        aroundYou.generated = true
        
        requestGatesAndPopulateList(false)
    
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("becomeActive:"), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
               
        if !loadingGates || gates.count == 0 { gatesTable.reloadData() }
        
    }
        
    func refresh() {
        requestGatesAndPopulateList(true)
    }
    
    func createGateTextChanged(sender: AnyObject) {
        let textField = sender as UITextField
        
        var flag = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != ""
        
        (createGateAlert.actions[1] as UIAlertAction).enabled = flag
    }
    
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if (gestureRecognizer.state == UIGestureRecognizerState.Began) {
            
            var point = gestureRecognizer.locationInView(gatesTable)
            var indexPath = gatesTable.indexPathForRowAtPoint(point)
            
            if (indexPath != nil) {
                var unwrappedIndexPath = indexPath!
                
                var gate = gates[unwrappedIndexPath.row]
                
                var title: String!
                
                if gate.id == "aroundyou" {
                    title = gate.name + " - 200 meter radius"
                } else {
                    title = gate.name
                }
                
                gateOptionsController = MyAlertController(title: title, message: nil, preferredStyle: .ActionSheet)
                
                let unlockPermAction = UIAlertAction(title: "Unlock Permanently", style: .Default, handler: {(alert: UIAlertAction!) in
                    self.unlockPermanently(gate)
                })
                
                let deleteAction = UIAlertAction(title: "Leave", style: .Destructive, handler: {
                    (alert: UIAlertAction!) -> Void in
                    
                    var confirmLeaveAlert = MyAlertController(title: "Leave \(gate.name)", message: "Are you sure you want to leave?", preferredStyle: .Alert)
                    
                    let confirmAction = UIAlertAction(title: "YES", style: .Default, handler: {(alert: UIAlertAction!) in
                        self.leaveAlertDisplayed = false
                        self.leaveGate(gate, index: unwrappedIndexPath.row)
                    })
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                    
                    confirmLeaveAlert.addAction(confirmAction)
                    confirmLeaveAlert.addAction(cancelAction)
                    
                    self.presentViewController(confirmLeaveAlert, animated: true, completion: nil)
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { (alert: UIAlertAction!) in
                    self.leaveAlertDisplayed = false
                })
                
                if gate.id == "aroundyou" {
                    gateOptionsController.message = "No Settings"
                } else {
                    if (gate.generated && !gate.unlockedPerm) {
                        gateOptionsController.addAction(unlockPermAction)
                    }

                    gateOptionsController.addAction(deleteAction)
                }
                
                gateOptionsController.addAction(cancelAction)
                
                leaveAlertDisplayed = true
                self.presentViewController(gateOptionsController, animated: true, completion: nil)
            }
        }
    }
    
    func becomeActive(notification: NSNotification) {
        if CLLocationManager.authorizationStatus() != .Authorized {
            gates = gates.filter({
                (element : Gate) in

                return !element.attachedToSession
            })
         
            dispatch_async(dispatch_get_main_queue(), {
                self.gatesTable.reloadData()
            })
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gates.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.gatesTable.dequeueReusableCellWithIdentifier("gateCell") as GateCell
        
        if self.gates.count > indexPath.row {
            var gate = self.gates[indexPath.row]

            cell.configureViews(gate)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let mainViewController = parentViewController as MainViewController
        
        if indexPath.row == 0 {
            var userInfo = NSUserDefaults.standardUserDefaults()
            
            if (userInfo.objectForKey("opened_around_you") as? Bool) == true {
                mainViewController.showFeed(gates[indexPath.row])
            } else {
                var firstTimeAlert = MyAlertController(title: "Around You", message: "Use this Gate to see posts around you. Gate uses your last known location, which might not be accurate if Location Services are disabled.", preferredStyle: .Alert)
                
                let confirmAction = UIAlertAction(title: "OK", style: .Default, handler: {
                    (alert) in
                    
                    userInfo.setBool(true, forKey: "opened_around_you")
                    userInfo.synchronize()
                    
                    mainViewController.showFeed(self.gates[indexPath.row])
                })
                
                firstTimeAlert.addAction(confirmAction)
                
                self.presentViewController(firstTimeAlert, animated: true, completion: nil)
            }
        } else {
            mainViewController.showFeed(gates[indexPath.row])
        }
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
     
        return 64
    }
    
    func requestGatesAndPopulateList(refreshing: Bool) {
        loadingGates = true
        
        if refreshing == false {
            startLoading()
        }
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/gates.json", parameters: params,
            success: {(response: HTTPResponse) in
                
                var generatedGates = [Gate]()
                var personalGates = [Gate]()
                
                var jsonGates = response.responseObject!["gates"]
                
                let unwrappedGates = jsonGates as [Dictionary<String, AnyObject>]
                
                var calledDeleteGeneratedGates = false
                
                for var i = 0; i < unwrappedGates.count; i++ {
                    var jsonGate = unwrappedGates[i]
                    
                    var gate = Gate(id: jsonGate["external_id"] as String,
                        name: jsonGate["name"] as String,
                        usersCount: jsonGate["users_count"] as Int,
                        creator: (jsonGate["creator"] as? Dictionary<String, String>)?["name"],
                        generated: jsonGate["generated"] as Bool,
                        attachedToSession: jsonGate["session"] as Bool,
                        unlockedPerm: jsonGate["unlocked_perm"] as Bool)
                    
                    if gate.generated && !gate.unlockedPerm {
                        let mainViewController = self.parentViewController as MainViewController
                        
                        if CLLocationManager.authorizationStatus() != .Authorized && !mainViewController.appDelegate.conserveBatteryFlag {
                            // On the assumption that the five attempts to delete generated gates failed, we will continue
                            // to try to deleteGeneratedGates as long as there are gates attached to the session, which should
                            // be impossible if deleteGeneratedGates was successful. Further, we filter so if a gate is attached to the session
                            // we won't show it to the user because it should techincally be deleted
                            if gate.attachedToSession && !calledDeleteGeneratedGates {
//                                mainViewController.appDelegate.deleteGeneratedGates()
                                
                                calledDeleteGeneratedGates = true
                            } else {
                                generatedGates.append(gate)
                            }
                        } else {
                            generatedGates.append(gate)
                        }
                    } else {
                        personalGates.append(gate)
                    }
                }
                
                self.gates = [self.aroundYou] + generatedGates + personalGates
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingIndicator.stopAnimating()
                    
                    self.gatesTable.reloadData()
                    
                    if refreshing {
                        self.refresher.endRefreshing()
                    }
                    
                    if self.gates.count == 0 {
                        self.noGatesText.text = "No gates yet"
                        self.noGatesText.alpha = 1.0
                    } else {
                        self.noGatesText.alpha = 0.0
                    }
                    
                    self.loadingGates = false
                })
                
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingIndicator.stopAnimating()
                    self.refresher.endRefreshing()
                    
                    if self.gates.count == 0 {
                        if response == nil {
                            self.noGatesText.text = "We couldn't connect to the internet"
                        } else {
                            self.noGatesText.text = "Something went wrong"
                        }
                        
                        self.noGatesText.alpha = 1.0
                    } else {
                        self.gatesTable.reloadData()
                    }
                    
                    iToast.makeText(String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                
                    self.loadingGates = false
                })
            }
        )
    }
    
    func startLoading() {
        noGatesText.alpha = 0.0
        loadingIndicator.startAnimating()
    }
    
    func leaveGate(gate: Gate, index: Int) {
        // This is to handle the scenario where the gatesTable was updated with generated Gates while trying to leave one.
        if gate.id == gates[index].id {
            gates.removeAtIndex(index)
        } else {
            gates = gates.filter({ return $0.id != gate.id })
        }

        gatesTable.reloadData()
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        request.DELETE("https://infinite-river-7560.herokuapp.com/api/v1/gates/" + gate.id + "/leave.json", parameters: params,
            success: {(response: HTTPResponse) in
                    // Don't do anything, preprocessed.
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                
                dispatch_async(dispatch_get_main_queue(), {
                    // Add removed Gate back into list.
                    self.addGatesToArray([gate])
                    self.gatesTable.reloadData()
                    
                    iToast.makeText(String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                })
                
            }
        )
        
    }
    
    func unlockPermanently(gate: Gate) {
        gate.unlockedPerm = true
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        request.PUT("https://infinite-river-7560.herokuapp.com/api/v1/generated_gates/" + gate.id + "/unlock.json", parameters: params,
            success: {(response: HTTPResponse) in
                // Don't do anything, preprocessed.
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                
                dispatch_async(dispatch_get_main_queue(), {
                    gate.unlockedPerm = false
                    
                    iToast.makeText(String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                })
                
            }
        )
        
    }
    
    func createGate(name: String) {
        
        dispatch_async(dispatch_get_main_queue(), {
            let mainViewController = self.parentViewController as MainViewController
            
            var hud = MBProgressHUD.showHUDAddedTo(mainViewController.view, animated: true)
            hud.labelText = "Robots processing..."
        })
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params: Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        var gate = [ "name" : name ]
        
        params["gate"] = gate
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.POST("https://infinite-river-7560.herokuapp.com/api/v1/gates.json", parameters: params,
            success: { (response: HTTPResponse) in
                
                self.gateName.text = ""
                
                var jsonGate = response.responseObject!["gate"] as Dictionary<String, AnyObject>
                
                var gate = Gate(id: jsonGate["external_id"] as String,
                    name: jsonGate["name"] as String,
                    usersCount: 1,
                    creator: (jsonGate["creator"] as? Dictionary<String, String>)?["name"],
                    generated: jsonGate["generated"] as Bool,
                    attachedToSession: jsonGate["session"] as Bool,
                    unlockedPerm: jsonGate["unlocked_perm"] as Bool)
                
                dispatch_async(dispatch_get_main_queue(), {
                    let mainViewController = self.parentViewController as MainViewController
                    MBProgressHUD.hideHUDForView(mainViewController.view, animated: true)
                    
                    self.addGatesToArray([gate])
                    self.gatesTable.reloadData()
                })
            },
            failure: { (error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    let mainViewController = self.parentViewController as MainViewController
                    MBProgressHUD.hideHUDForView(mainViewController.view, animated: true)
                    
                    iToast.makeText(String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                    
                    self.presentViewController(self.createGateAlert, animated: true, completion: nil)
                })
            
            }
        )
        
    }
    
    func addGatesToArray(newGates: [Gate]) {
        
        // Array has alphabetized gates.
        
        var len = newGates.count
        
        if len > 0 {
            noGatesText.alpha = 0.0
        }
        
        // Accounts for Around You
        var startingPoint = 1
        var reachedEnd = false
        
        for var i = 0; i < len; i++ {
            var gate = newGates[i]
            
            // Accounts for Around You
            if gates.count == 1 {
                gates.append(gate)
                continue
            }
            
            for var j = startingPoint; j < gates.count; j++ {
                var name = gates[j].name
                if name.caseInsensitiveCompare(gate.name) == NSComparisonResult.OrderedDescending {
                    gates.insert(gate, atIndex: j)
                    startingPoint = j + 1
                    break
                } else if (reachedEnd || j == gates.count - 1) {
                    gates.append(gate)
                    reachedEnd = true
                    break
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
