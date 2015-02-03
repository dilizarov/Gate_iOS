//
//  CommentsViewController.swift
//  Gate
//
//  Created by David Ilizarov on 2/2/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

class CommentsViewController: UIViewController, PHFComposeBarViewDelegate {

    var post: Post!
    var creatingComment: Bool!
    var composeBarView: PHFComposeBarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBar()
        
        setupAddingComment()
    }
    
    func setupAddingComment() {
        var viewBounds = self.view.bounds
        var frame = CGRectMake(0, viewBounds.size.height - PHFComposeBarViewInitialHeight, view.bounds.width, PHFComposeBarViewInitialHeight)
        
        composeBarView = PHFComposeBarView(frame: frame)
        
        composeBarView.maxLinesCount = 6
        composeBarView.placeholder = "Add a comment..."
        composeBarView.delegate = self
        
        var red: CGFloat = 0.0862745
        var green: CGFloat = 0.258824
        var blue: CGFloat = 0.458824
        
        composeBarView.buttonTintColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        composeBarView.textView.backgroundColor = UIColor.whiteColor()
        
        self.view.addSubview(composeBarView)
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
        
        self.view.addSubview(navBar)
        
        navBar.pushNavigationItem(navigationItem, animated: false)
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
        self.view.endEditing(true)
        
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
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
