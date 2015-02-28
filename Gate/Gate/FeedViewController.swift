//
//  FeedViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/24/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

protocol CreatePostViewControllerDelegate {
    func sendCreatePostRequest(postBody: String!, gate: Gate!, gates: [Gate])
}

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CreatePostViewControllerDelegate {

    var posts = [Post]()
    var currentGate: Gate?
    var refresher: UIRefreshControl!
    
    var notifAttributes = [NSObject : AnyObject]()
    
    var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var noPostsText: UILabel!
    
    var cachedHeights = [String: CGFloat]()
    
    @IBOutlet var feed: UITableView!
 
    // Handle Notifications that trigger segue to comments
    var commentsNotification = false
    var postId: String?
    var notifType: Int?
    
    
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
    
    // Pass back to createPostViewController if 
    // Failed to successfully post
    var attemptedGate: Gate?
    var attemptedPostBody: String?
    var attemptedGates: [Gate]?
    var createPostErrorMessage: String?
    
    var postedToOtherGateAlert: MyAlertController!
    var alertDisplayed = false
    
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
        
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        
        loadingIndicator.center = self.view.center
        
        loadingIndicator.layer.zPosition = 5000
        
        self.view.addSubview(loadingIndicator)
        
        feed.rowHeight = UITableViewAutomaticDimension
        
        requestPostsAndPopulateList(false, page: nil, completionHandler: nil)
    }
    
    func handleNotification() {
    
        // Markers for type of notification.
        var postCreated = 42
        var commentCreated = 126
        var postLiked = 168
        var commentLiked = 210
        
        let delayInSeconds = 0.75
        let startTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds * Double(NSEC_PER_SEC)))
        
        if notifType != nil {
            if notifType == commentCreated || notifType == postLiked || notifType == commentLiked {
                commentsNotification = true
                let mainViewController = parentViewController as MainViewController
                                
                dispatch_after(startTime, dispatch_get_main_queue(), {
                    mainViewController.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
                    mainViewController.pageControl.currentPage = 0
                    
                    self.performSegueWithIdentifier("showComments", sender: self)
                })
                
            } else if notifType == postCreated {
                let mainViewController = parentViewController as MainViewController
                
                var gate: Gate?
                
                if (notifAttributes["gate_id"] as? String) == nil {
                    gate = nil
                } else {
                    var name : String? = notifAttributes["gate_name"] as? String
                    if name == nil { name = "Feed" }
                    
                    gate = Gate(id: notifAttributes["gate_id"] as String, name: name!)
                }
                
                dispatch_after(startTime, dispatch_get_main_queue(), {
                    mainViewController.showFeed(gate)
                })
            }
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showComments", sender: indexPath)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showComments" {
            
            // I pass in the post as the sender, and later check to see what the sender object is. If it is a Post and not an NSIndexPath, I assume I pressed the button.
            var destination = segue.destinationViewController as CommentsViewController
            
            var creatingComment = false
            var post : Post!
            
            if sender is Post {
                post = sender as Post
                creatingComment = true
            } else if sender is NSIndexPath {
                post = posts[(sender as NSIndexPath).row]
            }
            
            if commentsNotification {
                destination.creatingComment = creatingComment
                destination.notification = true
                destination.postId = postId
                
                commentsNotification = false
                postId = nil
            } else {
                destination.post = post
                destination.creatingComment = creatingComment
                destination.notification = false
            }
            
            (UIApplication.sharedApplication().delegate as AppDelegate).toggledViewController = destination
        } else if segue.identifier == "createPost" {
            
            var destination = segue.destinationViewController as CreatePostViewController
            destination.delegate = self
            
            let mainViewController = parentViewController as MainViewController
            
            destination.currentGate = currentGate
            
            if attemptedGate != nil {
                destination.attemptedGate = attemptedGate
            }

            if attemptedPostBody != nil {
                destination.attemptedPostBody = attemptedPostBody
            }
            
            if attemptedGates != nil {
                destination.gates = attemptedGates!
            } else {
                destination.gates = mainViewController.getGates()
            }
            
            if createPostErrorMessage != nil {
                destination.createPostErrorMessage = createPostErrorMessage
            }
            
            (UIApplication.sharedApplication().delegate as AppDelegate).toggledViewController = destination
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        self.feed.reloadData()
    }
        
    func showFeed(gate: Gate?) {
        currentGate = gate
            
        self.posts = []
        self.feed.reloadData()
            
        startLoading()
        requestPostsAndPopulateList(true, page: nil, completionHandler: nil)
        feed.setContentOffset(CGPointZero, animated: false)
    }
    
    func sendCreatePostRequest(postBody: String!, gate: Gate!, gates: [Gate]) {
        dispatch_async(dispatch_get_main_queue(), {
            var hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            
            hud.labelText = "Robots processing..."
        })
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params: Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        var post = ["body" : postBody]
        
        params["post"] = post
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.POST("https://infinite-river-7560.herokuapp.com/api/v1/gates/\(gate.id)/posts.json", parameters: params,
            success: { (response: HTTPResponse) in
                
                if self.currentGate == nil || self.onGateAndGettingSameGate(gate) {
                    
                    var jsonPost = response.responseObject!["post"] as Dictionary<String, AnyObject>
                    
                    var post = Post(
                        id: jsonPost["external_id"] as String,
                        name: (jsonPost["user"] as Dictionary<String, AnyObject>)["name"] as String,
                        body: jsonPost["body"] as String,
                        gateId: (jsonPost["gate"] as Dictionary<String, AnyObject>)["external_id"] as String,
                        gateName: (jsonPost["gate"] as Dictionary<String, AnyObject>)["name"] as String,
                        commentCount: jsonPost["comments_count"] as Int,
                        likeCount: jsonPost["up_count"] as Int,
                        liked: false,
                        timeCreated: jsonPost["created_at"] as String
                    )
                    
                    self.posts.insert(post, atIndex: 0)
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                        self.feed.reloadData()
                        self.feed.setContentOffset(CGPointZero, animated: true)
                    })
                    
                } else {
                    self.postedToOtherGateAlert = MyAlertController(title: "Posted to another Gate", message: nil, preferredStyle: .Alert)
                    
                    let confirmAction = UIAlertAction(title: "OK", style: .Default, handler: { (alert: UIAlertAction!) in
                        self.alertDisplayed = false
                    })
                    
                    self.postedToOtherGateAlert.addAction(confirmAction)
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                        self.alertDisplayed = true
                        self.presentViewController(self.postedToOtherGateAlert, animated: true, completion: nil)
                    })
                }
                
                
            },
            failure: { (error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    
                    self.attemptedGate = gate
                    self.attemptedPostBody = postBody
                    self.attemptedGates = gates
                    self.createPostErrorMessage = String.prettyErrorMessage(response)
                    
                    // If someone has no internet connection, everything fires off too fast and the Segue doesn't get performed, so we delay it by a second.
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                    
                    dispatch_after(delayTime, dispatch_get_main_queue(), {
                        self.performSegueWithIdentifier("createPost", sender: self)
                    })
                })
                
                
            }
        )
        

        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = self.feed.dequeueReusableCellWithIdentifier("gatePost") as PostCell
        
        if self.posts.count > indexPath.row {
            var post = self.posts[indexPath.row]
            
            cell.configureViews(post, gate: currentGate)
            
            cell.commentButton.addTarget(self, action: Selector("pressedCommentButton:"), forControlEvents: .TouchUpInside)
        }
        
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
        
        return cell
    }
    
    func pressedCommentButton(sender: AnyObject) {
        
        var buttonSuperview = (sender as UIButton).superview
        
        if buttonSuperview != nil {
            var post = (buttonSuperview!.superview as PostCell).post
            
            performSegueWithIdentifier("showComments", sender: post)
        }
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        var post = posts[indexPath.row]
        
        if cachedHeights[post.id] != nil {
            return cachedHeights[post.id]!
        } else {
            return 165
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
                requestPostsAndPopulateList(false, page: currentPage, completionHandler: nil)
            }
            
        }
        
    }
    
    func refresh() {
        requestPostsAndPopulateList(true, page: nil, completionHandler: nil)
    }
    
    func backgroundRefresh(completionHandler: (UIBackgroundFetchResult) -> Void) {
        requestPostsAndPopulateList(true, page: nil, completionHandler: completionHandler)
    }
    
    func requestPostsAndPopulateList(refreshing: Bool, page: Int?, completionHandler: ((UIBackgroundFetchResult) -> Void)?) {
        // Only care about the very first load of feed
        if !refreshing && page == nil {
            startLoading()
        }
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params : Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
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
        
        var requestUrl = "https://infinite-river-7560.herokuapp.com/api/v1/"
        
        if currentGate == nil {
            requestUrl += "aggregate.json"
        } else {
            requestUrl += "gates/\(currentGate!.id)/posts.json"
        }
        
        request.GET(requestUrl, parameters: params,
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
                    self.loadingIndicator.stopAnimating()
                    
                    if completionHandler != nil {
                        self.feed.setContentOffset(CGPointZero, animated: false)
                    }
                    
                    self.feed.reloadData()
                    
                    if self.posts.count == 0 {
                        self.noPostsText.text = "No posts yet"
                        self.noPostsText.alpha = 1.0
                    } else {
                        self.noPostsText.alpha = 0.0
                    }
                    
                    if refreshing {
                        self.currentPage = 2
                    }
                    
                    self.reachedEndOfCallback = true
                    
                    if completionHandler != nil {
                        completionHandler!(UIBackgroundFetchResult.NewData)
                    }
                })
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                self.refresher.endRefreshing()
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingIndicator.stopAnimating()
                    
                    if self.posts.count == 0 {
                        if response == nil {
                            self.noPostsText.text = "We couldn't connect to the internet"
                        } else {
                            self.noPostsText.text = "Something went wrong"
                        }
                        
                        self.noPostsText.alpha = 1.0
                    }
                    
                    if completionHandler != nil {
                        completionHandler!(UIBackgroundFetchResult.Failed)
                    } else {
                        iToast.makeText(" " + String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                    }
                })
                
            }
        )
        
    }
    
    func startLoading() {
        noPostsText.alpha = 0.0
        loadingIndicator.startAnimating()
    }
    
    func onAggregateAndGettingAggregate(gate: Gate?) -> Bool {
        return currentGate == nil && gate == nil
    }
    
    func onGateAndGettingSameGate(gate: Gate?) -> Bool {
        return currentGate != nil && gate != nil && currentGate!.id == gate!.id
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
