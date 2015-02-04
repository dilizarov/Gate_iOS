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
    
    var bodyCutOff = 220
    
    @IBOutlet var postName: UILabel!
    @IBOutlet var postTimestamp: UILabel!
    @IBOutlet var postGateName: UILabel!
    @IBOutlet var postBody: UILabel!
    @IBOutlet var postLikesCount: UILabel!
    @IBOutlet var postCommentsCount: UILabel!
    @IBOutlet var postLikeButton: UIButton!
    
    @IBAction func likePost(sender: AnyObject) {
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
        
        postLikesCount.text = "\(post.likeCount) likes"
        postCommentsCount.text = "\(post.commentCount) comments"
        
        setupNavBar()
        setupAddingComment()
    
        commentsFeed.rowHeight = UITableViewAutomaticDimension
        commentsFeed.estimatedRowHeight = 88
        
//        for var i = 0; i < 10; i++ {
//            
//            var body = ""
//            
//            for var j = 0; j < ((i + 1) * 5); j++ {
//                body += "body body body body body "
//            }
//            
//            self.comments.append(Comment(id: "\(i)", name: "User \(i)", body: body, likeCount: i, liked: i % 2 == 0, timeCreated: NSDate().stringFromDate()))
//        }
     
        
        //Bring the scrollView up to the front so that we can see the addComment.
        scrollView.layer.zPosition = 5000
        
        requestKeyboardNotifs()
        
        requestCommentsAndPopulateList()
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
        
        var red: CGFloat = 0.0862745
        var green: CGFloat = 0.258824
        var blue: CGFloat = 0.458824
        
        composeBarView.buttonTintColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        composeBarView.textView.backgroundColor = UIColor.whiteColor()
        
        self.scrollView.addSubview(composeBarView)
    }
    
    func composeBarViewDidPressButton(composeBarView: PHFComposeBarView!) {
        println("Send a comment")
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
        
        var refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: Selector("refresh"))
        
        refreshButton.tintColor = UIColor.whiteColor()
        
        navigationItem.rightBarButtonItem = refreshButton
        
        self.view.addSubview(navBar)
        
        navBar.pushNavigationItem(navigationItem, animated: false)
    }
    
    func requestCommentsAndPopulateList() {
        
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
                })
            },
            failure: {(error: NSError, response: HTTPResponse?) in
            }
        )
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = self.commentsFeed.dequeueReusableCellWithIdentifier("comment") as CommentCell
        
        var comment = self.comments[indexPath.row]
        
        cell.configureViews(comment)
        
        return cell
    }
    
    func refresh() {
        println("Heehehehe")
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
