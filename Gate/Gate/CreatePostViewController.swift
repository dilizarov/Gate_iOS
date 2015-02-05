//
//  CreatePostViewController.swift
//  Gate
//
//  Created by David Ilizarov on 2/5/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

class CreatePostViewController: UIViewController {
    
    var currentGate: Gate?
    var gates = [Gate]()
    var selectedGate: Gate!
    
    var postButton: UIBarButtonItem!
    
    @IBOutlet var selectGateButton: UIButton!
    
    @IBAction func selectGate(sender: UIButton) {
        
        var names = gates.map({ (var gate) -> String in
            return gate.name
        })
        
        var picker = ActionSheetStringPicker(title: "Select a Gate", rows: names, initialSelection: 0,
            doneBlock: {(picker, index, value) in
                self.selectedGate = self.gates[index]
                self.selectGateButton.setTitle(value as NSString, forState: .Normal)
            },
            cancelBlock: {(picker) in
                return
            }, origin: sender)
        
        picker.showActionSheetPicker()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        setupNavBar()
        if currentGate != nil {
            selectGateButton.setTitle(currentGate!.name, forState: .Normal)
            selectedGate = currentGate!
        } else {
            selectGate(selectGateButton)
        }
        
        // Do any additional setup after loading the view.
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
        navTitle.text = "Write a post"
        
        navbarView.addSubview(navTitle)
        
        navBar.addSubview(navbarView)
        
        var navigationItem = UINavigationItem()
        
        var backButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: Selector("dismiss"))
        
        backButton.tintColor = UIColor.whiteColor()
        
        navigationItem.leftBarButtonItem = backButton
        
        postButton = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: Selector("compose"))
        
        postButton.tintColor = UIColor.whiteColor()
        
        postButton.enabled = false
        
        navigationItem.rightBarButtonItem = postButton

        self.view.addSubview(navBar)
        
        navBar.pushNavigationItem(navigationItem, animated: false)
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
