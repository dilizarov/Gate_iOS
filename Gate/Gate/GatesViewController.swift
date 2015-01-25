//  GatesViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/24/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class GatesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var gatesTable: UITableView!
    
    var gates = [Gate]()
    
    var refresher: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.gatesTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        refresher = UIRefreshControl()
        refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refresher.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.gatesTable.addSubview(refresher)
        
        requestGatesAndPopulateList(false)
        // Do any additional setup after loading the view.
    }
    
    func refresh() {
        
        requestGatesAndPopulateList(true)
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gates.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = self.gatesTable.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        
        cell.textLabel?.text = self.gates[indexPath.row].name
        
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
                    
                    self.refresher.endRefreshing()
                }
                
                self.gatesTable.reloadData()
                
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                
             }
        )
        
        
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
