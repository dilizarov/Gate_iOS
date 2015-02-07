//
//  CreatePostViewController.swift
//  Gate
//
//  Created by David Ilizarov on 2/5/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class CreatePostViewController: UIViewController, UITextViewDelegate {
    
    var currentGate: Gate?
    var gates = [Gate]()
    var selectedGate: Gate?
    
    var postButton: UIBarButtonItem!
    
    var delegate : CreatePostViewControllerDelegate?
    
    @IBOutlet var selectGateButton: UIButton!
    @IBOutlet var postBody: UITextView!
    
    @IBAction func selectGate(sender: UIButton) {
        
        
        if !self.gates.isEmpty {
            
            var names = gates.map({ (var gate) -> String in
                return gate.name
            })
            
            var index = 0
            
            if selectedGate != nil {
                for var i = 0; i < gates.count; i++ {
                    if selectedGate!.id == gates[i].id {
                        index = i
                        break
                    }
                }
            }
            
            var picker = ActionSheetStringPicker(title: "Select a Gate", rows: names, initialSelection: index,
                doneBlock: {(picker, index, value) in
                    
                    if !self.gates.isEmpty {
                        self.selectedGate = self.gates[index]
                        self.selectGateButton.setTitle(value as NSString, forState: .Normal)
                        if self.selectGateButton.alpha == 0.7 {
                            UIView.animateWithDuration(1.0, {
                                self.selectGateButton.alpha = 1.0
                            })
                        }
                    }
                    
                    self.checkPostRequirements()
                },
                cancelBlock: {(picker) in
                    return
                },
                origin: sender)
            
            picker.showActionSheetPicker()

        } else {
            selectGateButton.setTitle("Loading Gates...", forState: .Normal)
            selectGateButton.enabled = false
                        
            loadGates(true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        
        if self.gates.isEmpty {
            selectGateButton.setTitle("Loading Gates...", forState: .Normal)
            selectGateButton.enabled = false
            
            loadGates(false)
        } else {
            if currentGate != nil {
                selectGateButton.setTitle(currentGate!.name, forState: .Normal)
                selectedGate = currentGate!
            } else {
                selectGate(selectGateButton)
            }

        }
        
        postBody.delegate = self
        
        checkPostRequirements()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        postBody.becomeFirstResponder()
    }
    
    func checkPostRequirements() {
        if selectedGate != nil && !postBody.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).isEmpty {
            postButton.enabled = true
        } else {
            postButton.enabled = false
        }
        
    }
    
    func textViewDidChange(textView: UITextView) {
        checkPostRequirements()
        
        if !textView.text.isEmpty && selectedGate == nil && selectGateButton.alpha == 1.0 {
            
            UIView.animateWithDuration(1.0, {
                self.selectGateButton.alpha = 0.7
            })
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
        navTitle.text = "Write a post"
        
        navbarView.addSubview(navTitle)
        
        navBar.addSubview(navbarView)
        
        var navigationItem = UINavigationItem()
        
        var backButton = UIBarButtonItem(image: UIImage(named: "Back"), style: .Plain, target: self, action: Selector("dismiss"))
        
        backButton.tintColor = UIColor.whiteColor()
        
        navigationItem.leftBarButtonItem = backButton
        
        postButton = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: Selector("compose"))
        
        postButton.tintColor = UIColor.whiteColor()
        
        postButton.enabled = false
        
        navigationItem.rightBarButtonItem = postButton

        self.view.addSubview(navBar)
        
        navBar.pushNavigationItem(navigationItem, animated: false)
    }
    
    func compose() {
        if selectedGate != nil {
            
            var postBody = self.postBody.text.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
            
            self.delegate?.sendCreatePostRequest(postBody, gate: selectedGate!)
            
            dismiss()
        }
    }
    
    func loadGates(forceSelectGate: Bool) {
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "09b19f4a-6e4d-475a-b7c8-a369c60e9f83" ]
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/gates.json", parameters: params,
            success: {(response: HTTPResponse) in
                
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
                }
                
                if self.gates.isEmpty {
                    let emptyGatesAlert = UIAlertController(title: "No Gates Unlocked", message: "Unlock a Gate so you can post", preferredStyle: .Alert)
                    
                    let confirmAction = UIAlertAction(title: "OK", style: .Default,
                        handler: {(alert) in
                            self.dismiss()
                        }
                    )
                    
                    emptyGatesAlert.addAction(confirmAction)
                    
                    dispatch_async(dispatch_get_main_queue(), {
                    
                       self.presentViewController(emptyGatesAlert, animated: true, completion: nil)
                        
                    })
                    
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.selectGateButton.setTitle("Select a Gate", forState: .Normal)
                        
                        self.selectGateButton.enabled = true
                        
                        if forceSelectGate {
                            self.selectGate(self.selectGateButton)
                        }
                    })
                }
                
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                
                let failedLoad = UIAlertController(title: "Unable to load Gates", message: "We had trouble connecting to the Internet", preferredStyle: .Alert)
                
                let confirmAction = UIAlertAction(title: "OK", style: .Default,
                    handler: {(alert) in
                    
                        self.selectGateButton.setTitle("Reload Gates", forState: .Normal)
                    
                        self.selectGateButton.enabled = true
                    }
                )
                
                failedLoad.addAction(confirmAction)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(failedLoad, animated: true, completion: nil)
                })
                
                //Tell them we couldn't load the gates. Button becomes retry so we could retry loading the buttons.
                
            }
        )

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
