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
    var refresher: UIRefreshControl!
    
    var cachedHeights = [String: CGFloat]()
    
    @IBOutlet var feed: UITableView!
 
    // Infinite scroll handling
    var infiniteScrollBufferCount: Int!
    var reachedEndOfList: Bool!
    var reachedEndOfCallback: Bool!
    var isLoading: Bool!
    var problemsLoading: Bool!
    var preloadPostCount: Int!
    var currentPage: Int!
    var infiniteScrollTimeBuffer: String!
    var lastTimeLoading: NSDate!
    
    @IBAction func createPost(sender: AnyObject) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        infiniteScrollBufferCount = 3
        reachedEndOfList = false
        reachedEndOfCallback = false
        isLoading = false
        problemsLoading = false
        preloadPostCount = 0
        // We initialize currentPage to 2 because we load in page 1. Infinite scrolling takes over for pages 2+
        currentPage = 2
        infiniteScrollTimeBuffer = ""

        refresher = UIRefreshControl()
        refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refresher.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        self.feed.addSubview(refresher)
        
        feed.rowHeight = UITableViewAutomaticDimension
        
        requestPostsAndPopulateList(false, page: nil)
        // Do any additional setup after loading the view.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        self.feed.reloadData()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = self.feed.dequeueReusableCellWithIdentifier("gatePost") as PostCell
        
        var post = self.posts[indexPath.row]
        
        cell.configureViews(post, gate: currentGate)
                
        // The next few lines are solely because of the iOS bug with UITableViewAutomaticDimension
        // when scrolling up.
        
        var visibleIndexPaths = feed.indexPathsForVisibleRows() as [NSIndexPath]
        
        var dequeuedRow = visibleIndexPaths[0].row - 1
        
        //dequeuedRow + 1 != indexPath.row makes sure that we're scrolling down, not up.
        
        if dequeuedRow >= 0 && dequeuedRow < posts.count && (dequeuedRow + 1 != indexPath.row) {
            var dequeuedPost = posts[dequeuedRow]
            
            if cachedHeights[dequeuedPost.id] == nil && cell.bounds.height != 0.0 {
                cachedHeights[dequeuedPost.id] = cell.bounds.height
            }
            
        }
        
//        if indexPath.row > 0 {
//            var separatorLineView = UIView(frame: CGRectMake(0, 0, 20, 1))
//            
//            separatorLineView.backgroundColor = UIColor.lightGrayColor()
//            
//            cell.contentView.addSubview(separatorLineView)
//        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        var post = posts[indexPath.row]
        
        if cachedHeights[post.id] != nil {
            return cachedHeights[post.id]!
        } else {
            return 140
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {

        if reachedEndOfList! || posts.count < 15 { return }
        
        if posts.count < preloadPostCount {
            preloadPostCount = posts.count
            if (posts.count == 0) { isLoading = true }
        }
        
        if isLoading! && reachedEndOfCallback! {
            isLoading = false
            preloadPostCount = posts.count
            currentPage = currentPage + 1
        }
        
        if problemsLoading! {
            if lastTimeLoading != nil && NSDate().secondsFrom(lastTimeLoading) > 4 {
                isLoading = false
            }
        }
        
        if (!isLoading) {
            
            var visibleIndexPaths = feed.indexPathsForVisibleRows() as [NSIndexPath]
            var visibleCount = visibleIndexPaths.count
            
            // We add one so that it plays nicely with posts.count
            var bottomVisiblePost = visibleIndexPaths[visibleCount - 1].row + 1
            
            if (bottomVisiblePost + infiniteScrollBufferCount >= posts.count) {
                isLoading = true
                reachedEndOfCallback = false
                lastTimeLoading = NSDate()
                requestPostsAndPopulateList(false, page: currentPage)
            }
            
        }
        
    }
    
    func refresh() {
        
        requestPostsAndPopulateList(true, page: nil)
        
    }
    
    func requestPostsAndPopulateList(refreshing: Bool, page: Int?) {
        
        var request = HTTPTask()
        
        println("Sending request")
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params : Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "09b19f4a-6e4d-475a-b7c8-a369c60e9f83" ]
        
        if (!refreshing) {
            
            if page != nil {
                var unwrappedPage = page!
                params["page"] = unwrappedPage
            }
            
            if (!infiniteScrollTimeBuffer.isEmpty) {
                params["infinite_scroll_time_buffer"] = infiniteScrollTimeBuffer
            }
        }
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/aggregate.json", parameters: params,
            success: {(response: HTTPResponse) in
                if (refreshing) {
                    self.refresher.endRefreshing()
                    self.posts = []
                    self.cachedHeights.removeAll(keepCapacity: false)
                    self.reachedEndOfList = false
                }
                
                var jsonPosts = response.responseObject!["posts"] as [Dictionary<String, AnyObject>]
                
                if (jsonPosts.count < 15) {
                    self.reachedEndOfList = true
                }
                
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
                    
                    if (i == 0 && (self.infiniteScrollTimeBuffer.isEmpty || refreshing)) {
                        
                        // The stuff you do to add a millisecond to some time =.=
                        self.infiniteScrollTimeBuffer = NSDate(timeIntervalSince1970: (post.timeCreated.timeIntervalSince1970 * 1000 + 1)/1000).stringFromDate()
                    }
                    
                    self.posts.append(post)
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.feed.reloadData()
                    
                    if refreshing {
                        self.currentPage = 2
                    }
                    
                    self.reachedEndOfCallback = true
                })
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                
                self.refresher.endRefreshing()
                
            }
        )
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
