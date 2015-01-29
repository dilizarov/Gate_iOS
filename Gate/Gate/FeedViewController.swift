//
//  FeedViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/24/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var posts = [Post]()
    var currentGate: Gate?
    var currentPage: Int!
    var refresher: UIRefreshControl!
    
    @IBOutlet var feed: UITableView!
    
    @IBAction func createPost(sender: AnyObject) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        requestPostsAndPopulateList(false)
        // Do any additional setup after loading the view.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = self.feed.dequeueReusableCellWithIdentifier("gatePost") as UITableViewCell
        
        var userName = cell.viewWithTag(1)! as UILabel
        var timestamp = cell.viewWithTag(2)! as UILabel
        var postBody = cell.viewWithTag(5)! as UILabel
        
        var post = self.posts[indexPath.row]
        
        userName.text = post.name
        timestamp.text = post.timestamp
        postBody.text = post.body
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("You have selected cell \(indexPath.row)")
    }
    
    func requestPostsAndPopulateList(refreshing: Bool) {
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        println(userInfo.objectForKey("created_at"))
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "09b19f4a-6e4d-475a-b7c8-a369c60e9f83" ]
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/aggregate.json", parameters: params,
            success: {(response: HTTPResponse) in
                if (refreshing) {
                    self.posts = []
                }
                
                var jsonPosts = response.responseObject!["posts"] as [Dictionary<String, AnyObject>]
                
                for var i = 0; i < jsonPosts.count; i++ {
                    var jsonPost = jsonPosts[i]
                    
                    var post = Post(
                        id: jsonPost["external_id"] as String,
                        name: (jsonPost["user"] as Dictionary<String, AnyObject>)["name"] as String,
                        body: jsonPost["body"] as String,
                        gateId: (jsonPost["gate"] as Dictionary<String, AnyObject>)["external_id"] as String,
                        gateName: (jsonPost["gate"] as Dictionary<String, AnyObject>)["name"] as String,
                        commentCount: jsonPost["comments_count"] as Int,
                        likeCount: jsonPost["up_count"] as Int,
                        liked: jsonPost["uped"] as Bool,
                        timeCreated: jsonPost["created_at"] as String
                        )
                    
                    self.posts.append(post)
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.feed.reloadData()
                    println(self.posts.count)
                })
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
