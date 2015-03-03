//
//  CreatePostViewController.swift
//  Gate
//
//  Created by David Ilizarov on 2/5/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class CreatePostViewController: MyViewController, UITextViewDelegate {
    
    var currentGate: Gate?
    var gates = [Gate]()
    var selectedGate: Gate?
    
    var gatePicker: ActionSheetStringPicker?
    var cancelButton: UIBarButtonItem!
    
    var attemptedGate: Gate?
    var attemptedPostBody: String?
    var createPostErrorMessage: String?
    
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
            
            gatePicker = ActionSheetStringPicker(title: "Select a Gate", rows: names, initialSelection: index,
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

            var doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: nil, action: nil)
            doneButton.tintColor = UIColor.gateBlueColor()
            
            cancelButton = UIBarButtonItem(title: "Cancel", style: .Plain, target: nil, action: Selector("cancel"))
            cancelButton.tintColor = UIColor.gateBlueColor()
            
            gatePicker!.setDoneButton(doneButton)
            gatePicker!.setCancelButton(cancelButton)
            
            gatePicker!.showActionSheetPicker()
        } else {
            selectGateButton.setTitle("Loading Gates...", forState: .Normal)
            selectGateButton.enabled = false
                        
            loadGates(true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        
        if createPostErrorMessage != nil {
            iToast.makeText(" " + createPostErrorMessage!).setGravity(iToastGravityCenter).setDuration(3000).show()
        }
        
        if self.gates.isEmpty {
            selectGateButton.setTitle("Loading Gates...", forState: .Normal)
            selectGateButton.enabled = false
            
            loadGates(false)
        } else {
            // Attempted Gate gets precedence over current Gate
            if attemptedGate != nil {
                selectGateButton.setTitle(attemptedGate!.name, forState: .Normal)
                selectedGate = attemptedGate!
            } else if currentGate != nil {
                selectGateButton.setTitle(currentGate!.name, forState: .Normal)
                selectedGate = currentGate!
            } else {
                selectGate(selectGateButton)
            }
        }
        
        if attemptedPostBody != nil {
            postBody.text = attemptedPostBody
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
            
            // We pass in gates so that we don't have to load the gates again on a potential failed attempt. Further, if ambitious enough, we can just use these gates data now and populate the Gates page, but... not today :)
            
            self.delegate?.sendCreatePostRequest(postBody, gate: selectedGate!, gates: gates)
            
            dismiss()
        }
    }
    
    func loadGates(forceSelectGate: Bool) {
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
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
                        creator: (jsonGate["creator"] as Dictionary<String, String>)["name"]!,
                        generated: jsonGate["generated"] as Bool)
                    
                    self.gates.append(gate)
                }
                
                if self.gates.isEmpty {
                    let emptyGatesAlert = MyAlertController(title: "No Gates Unlocked", message: "Unlock a Gate so you can post", preferredStyle: .Alert)
                    
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
                dispatch_async(dispatch_get_main_queue(), {
                    iToast.makeText(" We couldn't load your Gates").setGravity(iToastGravityCenter).setDuration(3000).show()
                    
                    
                    self.selectGateButton.setTitle("Reload Gates", forState: .Normal)
                    
                    self.selectGateButton.enabled = true
                })
            }
        )

    }
    
    func dismiss() {
        (UIApplication.sharedApplication().delegate as AppDelegate).toggledViewController = nil
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func dismissViewControllerAnimated(flag: Bool, completion: (() -> Void)?) {
        if gatePicker != nil {
            dispatch_async(dispatch_get_main_queue(), {
                self.gatePicker!.hidePickerWithCancelAction()
            })
        }
        
        super.dismissViewControllerAnimated(flag, completion: completion)
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
