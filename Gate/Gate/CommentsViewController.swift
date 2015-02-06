//
//  CommentsViewController.swift
//  Gate
//
//  Created by David Ilizarov on 2/2/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class CommentsViewController: UIViewController, PHFComposeBarViewDelegate, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var comments = [Comment]()

    var post: Post!
    var creatingComment: Bool!
    var composeBarView: PHFComposeBarView!
    
    var refreshButton: UIBarButtonItem!
    
    var bodyCutOff = 220
    
    @IBOutlet var postName: UILabel!
    @IBOutlet var postTimestamp: UILabel!
    @IBOutlet var postGateName: UILabel!
    @IBOutlet var postBody: UILabel!
    @IBOutlet var postLikesCount: UILabel!
    @IBOutlet var postCommentsCount: UILabel!
    @IBOutlet var postLikeButton: UIButton!
    
    @IBAction func likePost(sender: AnyObject) {
        toggleLikePost()
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params : Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "09b19f4a-6e4d-475a-b7c8-a369c60e9f83" ]
        
        if !post.liked { params["revert"] = true }
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/posts/\(post.id)/up.json", parameters: params,
            success: {(response: HTTPResponse) in
                // Don't do anything, because we preprocessed what happens.
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.toggleLikePost()
                })
            }
        )
    }
    
    @IBOutlet var scrollView: ClickThroughScrollView!
    
    @IBOutlet var commentsFeed: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        postName.text = post.name
        postTimestamp.text = post.timestamp
        postGateName.text = post.gateName
        
        if NSString(string: post.body).length >= bodyCutOff {
            var toIndex = bodyCutOff - 5
            var cutoffText: String = NSString(string: post.body).substringToIndex(toIndex) + "..."
            postBody.text = cutoffText
        } else {
            postBody.text = post.body
        }
        
        if post.likeCount > 0 {
            if post.likeCount > 1 {
                postLikesCount.text = "\(post.likeCount) likes"
            } else {
                postLikesCount.text = "1 like"
            }
            
            postLikesCount.alpha = 1.0
        } else {
            postLikesCount.alpha = 0.0
        }

        if post.commentCount > 0 {
            if post.commentCount > 1 {
                postCommentsCount.text = "\(post.commentCount) comments"
            } else {
                postCommentsCount.text = "1 comment"
            }
            
            postCommentsCount.alpha = 1.0
        } else {
            postCommentsCount.alpha = 0.0
        }
        
        if post.liked {
            self.postLikeButton.setTitle("Unlike", forState: .Normal)
        } else {
            self.postLikeButton.setTitle("Like", forState: .Normal)
        }
        
        setupNavBar()
        setupAddingComment()
    
        commentsFeed.rowHeight = UITableViewAutomaticDimension
        
        //Bring the scrollView up to the front so that we can see thee addComment.
        scrollView.layer.zPosition = 5000
        
        requestKeyboardNotifs()

        requestCommentsAndPopulateList(false)
    }
    
    func requestKeyboardNotifs() {
    
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardDidHide:"), name: UIKeyboardDidHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        scrollView.noClickThrough = true
    }
    
    func keyboardDidHide(notification: NSNotification) {
        scrollView.noClickThrough = false
    }
    
    func setupAddingComment() {
        var viewBounds = self.scrollView.bounds
        var frame = CGRectMake(0, viewBounds.size.height - PHFComposeBarViewInitialHeight, viewBounds.width, PHFComposeBarViewInitialHeight)
        
        composeBarView = PHFComposeBarView(frame: frame)
        
        composeBarView.maxLinesCount = 6
        composeBarView.placeholder = "Add a comment..."
        composeBarView.delegate = self
        
        composeBarView.buttonTintColor = UIColor.gateBlueColor()
        composeBarView.textView.backgroundColor = UIColor.whiteColor()
        
        self.scrollView.addSubview(composeBarView)
    }
    
    func composeBarViewDidPressButton(composeBarView: PHFComposeBarView!) {
        var comment = composeBarView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        composeBarView.text = ""
        composeBarView.endEditing(true)
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params : Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "09b19f4a-6e4d-475a-b7c8-a369c60e9f83" ]
        
        var commentJson = [String : AnyObject]()
        commentJson["body"] = comment
        
        params["comment"] = commentJson
        
        request.responseSerializer = JSONResponseSerializer()

        request.POST("https://infinite-river-7560.herokuapp.com/api/v1/posts/\(post.id)/comments.json", parameters: params,
            success: {(response: HTTPResponse) in
                
                var jsonComment = response.responseObject!["comment"] as Dictionary<String, AnyObject>
                
                var comment = Comment(id: jsonComment["external_id"] as String,
                    name: (jsonComment["user"] as Dictionary<String, AnyObject>)["name"] as String,
                    body: jsonComment["body"] as String,
                    likeCount: 0,
                    liked: false,
                    timeCreated: jsonComment["created_at"] as String)
                
                self.comments.append(comment)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.commentsFeed.reloadData()
                    
                    self.handleCommentCount(true)
                    self.scrollToBottomOfComments()
                })
            
            },
            failure: {(error: NSError, response: HTTPResponse?) in
            
            }
        )
        
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        if creatingComment! {
            composeBarView.becomeFirstResponder()
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
        navTitle.text = "Comments"
        
        navbarView.addSubview(navTitle)
        
        navBar.addSubview(navbarView)
        
        var navigationItem = UINavigationItem()
        
        var backButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: Selector("dismiss"))
        
        backButton.tintColor = UIColor.whiteColor()
        
        navigationItem.leftBarButtonItem = backButton
        
        refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: Selector("refresh"))
        
        refreshButton.tintColor = UIColor.whiteColor()
        
        navigationItem.rightBarButtonItem = refreshButton
        
        self.view.addSubview(navBar)
        
        navBar.pushNavigationItem(navigationItem, animated: false)
    }
    
    func requestCommentsAndPopulateList(refreshing: Bool) {
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "09b19f4a-6e4d-475a-b7c8-a369c60e9f83" ]
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/posts/\(post.id)/comments.json", parameters: params,
            success: {(response: HTTPResponse) in
                
                self.comments = []
                
                var jsonComments = response.responseObject!["comments"]
                
                let unwrappedComments = jsonComments as [Dictionary<String, AnyObject>]
                
                for var i = 0; i < unwrappedComments.count; i++ {
                    var jsonComment = unwrappedComments[i]
                    var comment = Comment(id: jsonComment["external_id"] as String,
                        name: (jsonComment["user"] as Dictionary<String, AnyObject>)["name"] as String,
                        body: jsonComment["body"] as String,
                        likeCount: jsonComment["up_count"] as Int,
                        liked: jsonComment["uped"] as Bool,
                        timeCreated: jsonComment["created_at"] as String)
                
                    self.comments.append(comment)
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.commentsFeed.reloadData()
                    
                    if refreshing && self.comments.count > 0 {
                        self.scrollToBottomOfComments()
                    }
                    
                    self.handleCommentCount(false)
                    self.refreshButton.enabled = true
                })
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                self.refreshButton.enabled = true
            }
        )
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = self.commentsFeed.dequeueReusableCellWithIdentifier("comment") as CommentCell
        
        if self.comments.count > indexPath.row {
            
            var comment = self.comments[indexPath.row]
            
            cell.configureViews(comment)

        }
        
        return cell
    }
    
    func toggleLikePost() {
        if post.liked {
            post.liked = false
            
            post.likeCount -= 1
            
            self.postLikeButton.setTitle("Like", forState: .Normal)
            
            if post.likeCount == 0 {
                UIView.animateWithDuration(0.25, animations: {
                    self.postLikesCount.alpha = 0.0
                })
            } else {
                var text = "\(post.likeCount) like"
                
                if post.likeCount != 1 { text += "s" }
                
                self.postLikesCount.text = text
            }
            
        } else {
            post.liked = true
            
            post.likeCount += 1
            
            self.postLikeButton.setTitle("Unlike", forState: .Normal)
            
            if post.likeCount == 1 {
                self.postLikesCount.text = "1 like"
                
                UIView.animateWithDuration(0.25, animations: {
                    self.postLikesCount.alpha = 1.0
                })
                
            } else {
                self.postLikesCount.text = "\(post.likeCount) likes"
            }
        }
    }
    
    func handleCommentCount(creating: Bool) {
        var wasCommentCountZero = post.commentCount == 0
        
        if creating {
            post.commentCount += 1
        } else {
            post.commentCount = comments.count
        }
        
        var text = "\(post.commentCount) comment"
        
        if post.commentCount != 1 { text += "s" }
        
        self.postCommentsCount.text = text
        
        if wasCommentCountZero && post.commentCount > 0 {
            UIView.animateWithDuration(0.25, animations: {
                self.postCommentsCount.alpha = 1.0
            })
        }
    }

    func scrollToBottomOfComments() {
        
        commentsFeed.layoutIfNeeded()
        
        var delayInSeconds = 0.25
        
        dispatch_after(dispatch_time_t(0.25), dispatch_get_main_queue(), {
            var lastRowNumber = self.commentsFeed.numberOfRowsInSection(0) - 1
            var indexPath = NSIndexPath(forRow: lastRowNumber, inSection: 0)
            self.commentsFeed.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        })
    }
    
    func refresh() {
        
        refreshButton.enabled = false
        
        requestCommentsAndPopulateList(true)
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
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
