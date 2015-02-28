//
//  CommentsViewController.swift
//  Gate
//
//  Created by David Ilizarov on 2/2/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class CommentsViewController: MyViewController, PHFComposeBarViewDelegate, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var comments = [Comment]()

    var post: Post!
    var creatingComment: Bool!
    var composeBarView: PHFComposeBarView!
    
    var refreshButton: UIBarButtonItem!
    
    var loadingIndicator: UIActivityIndicatorView!
    
    var bodyCutOff = 220
    
    // Handle notification
    var notification = false
    var postId: String?
    
    @IBOutlet var postName: UILabel!
    @IBOutlet var postTimestamp: UILabel!
    @IBOutlet var postGateName: UILabel!
    @IBOutlet var postBody: UILabel!
    @IBOutlet var postLikesCount: UILabel!
    @IBOutlet var postCommentsCount: UILabel!
    @IBOutlet var postLikeButton: UIButton!
    @IBOutlet var noCommentsText: UILabel!
    
    @IBAction func likePost(sender: AnyObject) {
        toggleLikePost()
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params : Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        if !post.liked { params["revert"] = true }
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/posts/\(post.id)/up.json", parameters: params,
            success: {(response: HTTPResponse) in
                // Don't do anything, because we preprocessed what happens.
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.toggleLikePost()
                    
                    iToast.makeText(" " + String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                })
            }
        )
    }
    
    @IBOutlet var scrollView: ClickThroughScrollView!
    
    @IBOutlet var commentsFeed: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if notification {
            hidePost()
        } else {
            populatePostViews()
        }
        
        setupNavBar()
        setupAddingComment()
    
        commentsFeed.rowHeight = UITableViewAutomaticDimension
        
        //Bring the scrollView up to the front so that we can see the addComment.
        scrollView.layer.zPosition = 5000
        
        requestKeyboardNotifs()

        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        
        // A bit hacky, but the constraint for no comment text is 264 from the bottom, so I'm positioning this on it.
        
        loadingIndicator.center = CGPointMake(self.view.center.x, self.view.bounds.height - 264 - loadingIndicator.bounds.height / 2)
        
        loadingIndicator.layer.zPosition = 5000
        
        self.view.addSubview(loadingIndicator)
        
        requestDataAndPopulate(false)
    }
    
    func populatePostViews() {
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
        
        if post.commentCount < comments.count {
            if comments.count > 0 {
                if comments.count > 1 {
                    postCommentsCount.text = "\(comments.count) comments"
                } else {
                    postCommentsCount.text = "1 comment"
                }
                
                postCommentsCount.alpha = 1.0
            }
        } else if post.commentCount > 0 {
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

    }
    
    func hidePost() {
        postName.alpha = 0.0
        postTimestamp.alpha = 0.0
        postGateName.alpha = 0.0
        postBody.alpha = 0.0
        postLikesCount.alpha = 0.0
        postCommentsCount.alpha = 0.0
        postLikeButton.alpha = 0.0
    }
    
    func showPost() {
        postName.alpha = 1.0
        postTimestamp.alpha = 1.0
        postGateName.alpha = 1.0
        postBody.alpha = 1.0
        postLikeButton.alpha = 1.0
        if post.likeCount > 0 {
            postLikesCount.alpha = 1.0
        }
        
        if post.commentCount > 0 {
            postCommentsCount.alpha = 1.0
        }
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
        composeBarView.maxCharCount = 500
        composeBarView.placeholder = "Add a comment..."
        composeBarView.delegate = self
        
        composeBarView.buttonTintColor = UIColor.gateBlueColor()
        composeBarView.textView.backgroundColor = UIColor.whiteColor()
        
        self.scrollView.addSubview(composeBarView)
    }
    
    func composeBarViewDidPressButton(composeBarView: PHFComposeBarView!) {
        startLoading()
        
        var comment = composeBarView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        composeBarView.text = ""
        composeBarView.endEditing(true)
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params : Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
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
                    self.loadingIndicator.stopAnimating()
                    self.commentsFeed.reloadData()
                    
                    self.handleCommentCount(true)
                    self.scrollToBottomOfComments()
                })
            
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingIndicator.stopAnimating()
                    if self.comments.count == 0 {
                        self.noCommentsText.alpha = 1.0
                    }
                    
                    self.composeBarView.text = comment
                    self.composeBarView.becomeFirstResponder()
                    
                    iToast.makeText(" " + String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()

                })
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
        
        var id: String
        
        if postId == nil {
            id = post.id
        } else {
            id = postId!
        }

        if refreshing || postId != nil {
            params["include_post"] = true
        }
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/posts/\(id)/comments.json", parameters: params,
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
                
                // For some reason I can't do response.responseObject!["meta"] != nil
                if (response.responseObject as Dictionary<String, AnyObject>)["meta"] != nil {
                    var jsonPost = (response.responseObject!["meta"] as Dictionary<String, AnyObject>)["post"] as Dictionary<String, AnyObject>
                    
                    self.post = Post(
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
                    
                    self.postId = nil
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingIndicator.stopAnimating()
                    
                    if self.comments.count == 0 {
                        self.noCommentsText.text = "No comments yet"
                        self.noCommentsText.alpha = 1.0
                    } else {
                        self.noCommentsText.alpha = 0.0
                    }
                    
                    self.populatePostViews()
                    self.showPost()
                    
                    self.commentsFeed.reloadData()
                    
                    if (refreshing || self.notification) && self.comments.count > 0 {
                        self.scrollToBottomOfComments()
                    }
                    
                    self.handleCommentCount(false)
                    self.refreshButton.enabled = true
                })
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadingIndicator.stopAnimating()
                    
                    if self.comments.count == 0 {
                        if response == nil {
                            self.noCommentsText.text = "We couldn't connect to the internet"
                        } else {
                            self.noCommentsText.text = "Something went wrong"
                        }
                        
                        self.noCommentsText.alpha = 1.0
                    }
                    
                    iToast.makeText(" " + String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                    
                    
                    self.refreshButton.enabled = true
                })
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
    
    func startLoading() {
        noCommentsText.alpha = 0.0
        loadingIndicator.startAnimating()
    }
    
    func handleCommentCount(creating: Bool) {
        // Only handle comment count whenever there is an actual post.
        if postId != nil {
            return
        }
        
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
        requestDataAndPopulate(true)
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
