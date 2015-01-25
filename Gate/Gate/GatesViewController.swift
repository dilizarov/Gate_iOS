//  GatesViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/24/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class GatesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

    @IBOutlet var gatesTable: UITableView!
    @IBAction func viewAggregate(sender: AnyObject) {
        println("Aggregate")
    }
    
    @IBAction func createGate(sender: AnyObject) {
        println("CreateGate")
    }
    
    
    var gates = [Gate]()
    
    var refresher: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresher = UIRefreshControl()
        refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refresher.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.gatesTable.addSubview(refresher)
        
        var longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("handleLongPress:"))
        longPressGestureRecognizer.minimumPressDuration = 2.0
        longPressGestureRecognizer.delegate = self
        gatesTable.addGestureRecognizer(longPressGestureRecognizer)
        
        requestGatesAndPopulateList(false)
    }
    
    func refresh() {
        
        requestGatesAndPopulateList(true)
        
    }
    
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if (gestureRecognizer.state == UIGestureRecognizerState.Began) {
            
            var point = gestureRecognizer.locationInView(gatesTable)
            var indexPath = gatesTable.indexPathForRowAtPoint(point)
            
            if (indexPath != nil) {
                var unwrappedIndexPath = indexPath!
                
                var gate = gates[unwrappedIndexPath.row]
                
                let alertController = UIAlertController(title: "Leave \(gate.name)", message: "Are you sure you want to leave \(gate.name)?", preferredStyle: .ActionSheet)
                
                let deleteAction = UIAlertAction(title: "Leave", style: .Destructive, handler: {
                    (alert: UIAlertAction!) -> Void in
                    
                    self.leaveGate(gate, index: unwrappedIndexPath.row)
                    
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                
                alertController.addAction(deleteAction)
                alertController.addAction(cancelAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gates.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = self.gatesTable.dequeueReusableCellWithIdentifier("gateCell") as UITableViewCell
        
        var gateName = cell.viewWithTag(1)! as UILabel
        var gatekeepersCount = cell.viewWithTag(2)! as UILabel
        
        var gate = self.gates[indexPath.row]
        
        gateName.text = gate.name
        
        if gate.usersCount.toInt() == 1 {
            gatekeepersCount.text = "1 Gatekeeper"
        } else {
            gatekeepersCount.text = gate.usersCount + " Gatekeepers"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        println("You have selected cell \(indexPath.row)")
    }
    
    func requestGatesAndPopulateList(refreshing: Bool) {
        
        if (refreshing) {
            println("Refreshing")
        }
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "09b19f4a-6e4d-475a-b7c8-a369c60e9f83" ]
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/gates.json", parameters: params,
            success: {(response: HTTPResponse) in
                println(response.responseObject!)

                if refreshing {
                    self.refresher.endRefreshing()
                }
                
                self.gates = []
                
                var jsonGates = response.responseObject!["gates"]
                
                let unwrappedGates = jsonGates as [Dictionary<String, AnyObject>]
                
                for var i = 0; i < unwrappedGates.count; i++ {
                    var jsonGate = unwrappedGates[i]
                    var gate = Gate(id: jsonGate["external_id"] as String,
                        name: jsonGate["name"] as String,
                        usersCount: jsonGate["users_count"] as Int,
                        creator: (jsonGate["creator"] as Dictionary<String, String>)["name"]!)
                    
                    self.gates.append(gate)
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.gatesTable.reloadData()
                })
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                
             }
        )
        
        
    }
    
    func leaveGate(gate: Gate, index: Int) {
        gates.removeAtIndex(index)
        gatesTable.reloadData()
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "09b19f4a-6e4d-475a-b7c8-a369c60e9f83" ]
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.DELETE("https://infinite-river-7560.herokuapp.com/api/v1/gates/\(gate.id)/leave.json", parameters: params,
            success: {(response: HTTPResponse) in
                    // Don't do anything, preprocessed.
            },
            failure: {(error: NSError, response: HTTPResponse?) in

                // Add removed Gate back into list.
                self.addGatesToArray([gate])
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.gatesTable.reloadData()
                    let alertController = UIAlertController(title: "Failed to leave Gate", message: "We couldn't connect to the internet", preferredStyle: .Alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    
                    alertController.addAction(defaultAction)
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                })
                
            }
        )
        
    }
    
    func addGatesToArray(newGates: [Gate]) {
        
        var len = newGates.count
        var startingPoint = 0
        var reachedEnd = false
        for var i = 0; i < len; i++ {
            var gate = newGates[i]
            
            var length = gates.count
            
            if length == 0 {
                gates.append(gate)
                continue
            }
            
            for var j = startingPoint; j < length; j++ {
                var name = gates[j].name
                if name.caseInsensitiveCompare(gate.name) == NSComparisonResult.OrderedDescending {
                    gates.insert(gate, atIndex: j)
                    startingPoint = j + 1
                    break;
                } else if reachedEnd || j == length - 1 {
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
