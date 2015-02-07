//
//  MainViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/23/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class MainViewController: UIViewController, UIScrollViewDelegate {
    
    var scrollView:UIScrollView!
    var pageControl:UIPageControl!
    var navbarView:UIView!
    
    var buttonLeft:UIBarButtonItem!
    var buttonRight:UIBarButtonItem!
    
    var navTitleLabel1:UILabel!
    var navTitleLabel2:UILabel!
    
    var feedViewController: FeedViewController!
    var gatesViewController: GatesViewController!
    
    var view1:UIView!
    var view2:UIView!
    
    var enterKeyAlert: UIAlertController!
    var enteredKey: UITextField!
    // Used to keep track of length before editing
    // To take care of deleting -'s
    var beforeEditKeyString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var navBar: UINavigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, 64))
        
        navBar.barTintColor = UIColor.blackColor()
        navBar.translucent = false
        
        //Creating some shorthand for these values
        var wBounds = self.view.bounds.width
        var hBounds = self.view.bounds.height
        
        // This houses all of the UIViews / content
        scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.frame = self.view.frame
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.bounces = false
        self.view.addSubview(scrollView)
        
        self.scrollView.contentSize = CGSize(width: self.view.bounds.size.width * 2, height: hBounds)
        
        //Putting a subview in the navigationbar to hold the titles and page dots
        navbarView = UIView()
        
        //Paging control is added to a subview in the uinavigationcontroller
        pageControl = UIPageControl()
        pageControl.frame = CGRect(x: 0, y: 35, width: 0, height: 0)
        pageControl.pageIndicatorTintColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = UIColor.whiteColor()
        pageControl.numberOfPages = 2
        pageControl.currentPage = 0
        self.navbarView.addSubview(pageControl)
        
        //Titles for the nav controller (also added to a subview in the uinavigationcontroller)
        //Setting size for the titles. FYI changing width will break the paging fades/movement
        navTitleLabel1 = UILabel()
        navTitleLabel1.frame = CGRect(x: 0, y: 8, width: wBounds, height: 20)
        navTitleLabel1.textColor = UIColor.whiteColor()
        navTitleLabel1.textAlignment = NSTextAlignment.Center
        navTitleLabel1.text = "Aggregate"
        self.navbarView.addSubview(navTitleLabel1)
        
        navTitleLabel2 = UILabel()
        navTitleLabel2.alpha = 0.0
        navTitleLabel2.frame = CGRect(x: 100, y: 8, width: wBounds, height: 20)
        navTitleLabel2.textColor = UIColor.whiteColor()
        navTitleLabel2.textAlignment = NSTextAlignment.Center
        navTitleLabel2.text = "Gates"
        self.navbarView.addSubview(navTitleLabel2)
        
        //Views for the scrolling view
        //This is where the content of your views goes (or you can subclass these and add them to ScrollView)
        
        feedViewController = storyboard?.instantiateViewControllerWithIdentifier("FeedController") as FeedViewController
        
        view1 = feedViewController.view
        
        addChildViewController(feedViewController)
        feedViewController.didMoveToParentViewController(self)
        
        view1.frame = CGRectMake(0, 0, wBounds, hBounds)
        self.scrollView.addSubview(view1)
        self.scrollView.bringSubviewToFront(view1)
        
        //Notice the x position increases per number of views
        
        gatesViewController = storyboard?.instantiateViewControllerWithIdentifier("GatesController") as GatesViewController
        
        view2 = gatesViewController.view
        
        addChildViewController(gatesViewController)
        gatesViewController.didMoveToParentViewController(self)
        
        view2.frame = CGRectMake(wBounds, 0, wBounds, hBounds)
        self.scrollView.addSubview(view2)
        self.scrollView.bringSubviewToFront(view2)
        
        navBar.addSubview(navbarView)
        self.view.addSubview(navBar)
        
        buttonLeft = UIBarButtonItem(image: UIImage(named: "CreateKey"), style: .Plain, target: self, action: Selector("showCreateKey"))
        
        buttonLeft.tintColor = UIColor.whiteColor()
        
        buttonRight = UIBarButtonItem(image: UIImage(named: "Unlock"), style: .Plain, target: self, action: Selector("enterKey"))
        
        buttonRight.tintColor = UIColor.whiteColor()
        
        var navigationItem = UINavigationItem()
        navigationItem.leftBarButtonItems = NSArray(array: [buttonLeft, buttonRight])

        var settingsButton = UIBarButtonItem(image: UIImage(named: "Settings"), style: .Plain, target: self, action: Selector("bringUpSettings"))
        
        settingsButton.tintColor = UIColor.whiteColor()
        
        var font = UIFont(name: "Helvetica", size: 24.0)
        var attributes = [NSFontAttributeName : font!] as NSDictionary!
        settingsButton.setTitleTextAttributes(attributes, forState: UIControlState.Normal)
        
        navigationItem.rightBarButtonItem = settingsButton
        
        navBar.pushNavigationItem(navigationItem, animated: false)
    }
    
    func bringUpSettings() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let logoutAction = UIAlertAction(title: "Log out", style: .Destructive, handler: {(alert: UIAlertAction!) -> Void in
            
            self.logout()
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showFeed(gate: Gate?) {
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        pageControl.currentPage = 0
        
        if gate == nil {
            navTitleLabel1.text = "Aggregate"
        } else {
            navTitleLabel1.text = gate!.name
        }
        
        feedViewController.showFeed(gate)
    }
    
    func showCreateKey() {
        performSegueWithIdentifier("createKey", sender: self)
    }
    
    func enterKey() {
        enterKeyAlert = UIAlertController(title: "Enter key", message: nil, preferredStyle: .Alert)
        
        enterKeyAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        enterKeyAlert.addTextFieldWithConfigurationHandler({
            (textField: UITextField!) in
            
            textField.placeholder = "Key"
            textField.clearButtonMode = .WhileEditing
            textField.spellCheckingType = .No
            textField.keyboardType = .NumberPad
            
            textField.addTarget(self, action: "keyTextChanged:", forControlEvents: .EditingChanged)
            
            self.enteredKey = textField
        })
        
        presentViewController(enterKeyAlert, animated: true, completion: nil)
    }

    func keyTextChanged(sender: AnyObject) {
        let textField = sender as UITextField
        
        var plausableKey = textField.text.stringByReplacingOccurrencesOfString("-", withString: "", options: nil, range: nil)

        var stringLength = NSString(string: textField.text).length
        
        if NSString(string: plausableKey).length == 16 {
            enterKeyAlert.dismissViewControllerAnimated(true, completion: nil)
            
            processKey(plausableKey)
            
        } else if stringLength >= NSString(string: beforeEditKeyString).length && (stringLength == 4 || stringLength == 9 || stringLength == 14) {
            
            textField.text = textField.text + "-"
        } else if stringLength < NSString(string: beforeEditKeyString).length && (stringLength == 4 || stringLength == 9 || stringLength == 14) {
            
            textField.text = textField.text.substringWithRange(Range<String.Index>(start: textField.text.startIndex, end: advance(textField.text.endIndex, -1)))
        }
        
        beforeEditKeyString = textField.text
    }
    
    func processKey(key: String) {
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "09b19f4a-6e4d-475a-b7c8-a369c60e9f83" ]
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.POST("https://infinite-river-7560.herokuapp.com/api/v1/keys/" + key + "/process.json", parameters: params,
            success: {(response: HTTPResponse) in
                                
                var jsonGates = response.responseObject!["gates"]
                
                let unwrappedGates = jsonGates as [Dictionary<String, AnyObject>]
                
                var newGates = [Gate]()
                
                for var i = 0; i < unwrappedGates.count; i++ {
                    var jsonGate = unwrappedGates[i]
                    var gate = Gate(id: jsonGate["external_id"] as String,
                        name: jsonGate["name"] as String,
                        usersCount: jsonGate["users_count"] as Int,
                        creator: (jsonGate["creator"] as Dictionary<String, String>)["name"]!)
                    
                    newGates.append(gate)
                }
                
                newGates.sort({
                    $0.name.caseInsensitiveCompare($1.name) == NSComparisonResult.OrderedAscending
                })
                
                if !unwrappedGates.isEmpty {
                    self.gatesViewController.addGatesToArray(newGates)
                }
                
                //Prepare message for UIAlertController
                var alertTitle = ""
                var alertMessage = ""
                
                if unwrappedGates.isEmpty {
                    alertTitle += "You already have all those gates unlocked"
                } else {
                    var meta = response.responseObject!["meta"] as Dictionary<String, AnyObject>
                    var data = meta["data"] as Dictionary<String, AnyObject>
                    var gatekeeper = data["gatekeeper"] as String
                    
                    var gatesString = ""
                    
                    if newGates.count == 1 {
                        gatesString += newGates[0].name as String
                    } else if newGates.count == 2 {
                        gatesString += (newGates[0].name as String) + " and " + (newGates[1].name as String)
                    } else if newGates.count > 2 {
                        for var i = 0; i < newGates.count; i++ {
                            if i != 0 {
                                gatesString += ", "
                            }
                            
                            if i == newGates.count - 1 {
                                gatesString += "and "
                            }
                            
                            gatesString += newGates[i].name as String
                        }
                    }

                    
                    alertTitle += "You've unlocked Gates"
                    alertMessage += gatekeeper + " granted you access to " + gatesString
                }
                
                
                var meta = response.responseObject!["meta"] as Dictionary<String, AnyObject>
                var data = meta["data"] as Dictionary<String, AnyObject>
                var gatekeeper = data["gatekeeper"] as String
                
                
                dispatch_async(dispatch_get_main_queue(), {
                    if !unwrappedGates.isEmpty {
                        self.gatesViewController.gatesTable.reloadData()
                    }
                    
                    let unlockedGatesAlert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
                    
                    let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    
                    unlockedGatesAlert.addAction(alertAction)
                    
                    self.presentViewController(unlockedGatesAlert, animated: true, completion: nil)
                })
                
            },
            failure: {(error: NSError, response: HTTPResponse?) in
            
            }
        )
    }
    
    func logout() {
        var defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.removeObjectForKey("auth_token")
        defaults.removeObjectForKey("created_at")
        defaults.removeObjectForKey("email")
        defaults.removeObjectForKey("user_id")
        defaults.removeObjectForKey("name")
        
        defaults.synchronize()
        
        performSegueWithIdentifier("logoutUser", sender: self)
    }
    
    func getGates() -> [Gate] {
        return gatesViewController.gates
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "createKey" {
            var destination = segue.destinationViewController as CreateKeyViewController
            
            destination.gates = gatesViewController.gates
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        navbarView.frame = CGRect(x: 0, y: 20, width: self.view.bounds.width, height: 44)
    }
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        var xOffset: CGFloat = scrollView.contentOffset.x
        
        //Setup some math to position the elements where we need them when the view is scrolled
        
        var wBounds = self.view.bounds.width
        var widthOffset = wBounds / 100
        var offsetPosition = 0 - xOffset/widthOffset
        
        //Apply the positioning values created above to the frame's position based on user's scroll
        
        navTitleLabel1.frame = CGRectMake(offsetPosition, 8, wBounds, 20)
        navTitleLabel2.frame = CGRectMake(offsetPosition + 100, 8, wBounds, 20)
        
        //Change the alpha values of the titles as they are scrolled
        
        navTitleLabel1.alpha = 1 - xOffset / wBounds
        
        if (xOffset <= wBounds) {
            navTitleLabel2.alpha = xOffset / wBounds
        } else {
            navTitleLabel2.alpha = 1 - (xOffset - wBounds) / wBounds
        }
        
    }
    
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        var xOffset: CGFloat = scrollView.contentOffset.x
        
        //Change the pageControl dots depending on the page / offset values
        
        if (xOffset < 1.0) {
            pageControl.currentPage = 0
        } else if (xOffset < self.view.bounds.width + 1) {
            pageControl.currentPage = 1
        }
        
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
