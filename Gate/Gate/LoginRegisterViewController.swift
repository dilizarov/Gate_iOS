//
//  LoginRegisterViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/23/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class LoginRegisterViewController: UIViewController, UITextFieldDelegate {
    
    enum ViewState {
        case Login, Register, ForgotPassword
    }
    
    var viewState: ViewState?
    
    @IBOutlet var email: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var name: UITextField!
    @IBOutlet var forgotPassword: UIButton!
    @IBOutlet var command: UIButton!
    @IBOutlet var toggle: UIButton!
    
    @IBAction func toggleRegisterLogin(sender: AnyObject) {
        
        if viewState == .Login {
            
            forgotPassword.alpha = 0.0
            forgotPassword.enabled = false
            
            command.setTitle("Register", forState: UIControlState.Normal)
            toggle.setTitle("Log In", forState: UIControlState.Normal)
            
            viewState = .Register
            
            self.name.enabled = true
            
            textFieldChanged()
            
            UIView.animateWithDuration(0.25, animations: {
                self.name.alpha = 1.0
            })
            
        } else {
            
            if viewState == .ForgotPassword {
                
                command.setTitle("Log In", forState: UIControlState.Normal)
                toggle.setTitle("Register", forState: UIControlState.Normal)
                forgotPassword.setTitle("Forgot your password?", forState: UIControlState.Normal)
                
                viewState = .Login
                
                self.password.enabled = true
                
                textFieldChanged()
                
                UIView.animateWithDuration(0.25, animations: {
                    self.password.alpha = 1.0
                })
                
            } else {
                
                command.setTitle("Log In", forState: UIControlState.Normal)
                toggle.setTitle("Register", forState: UIControlState.Normal)
                
                viewState = .Login
                
                self.forgotPassword.enabled = true
                
                textFieldChanged()
                
                UIView.animateWithDuration(0.25, animations: {
                    self.name.alpha = 0.0
                    self.name.enabled = false
                    self.forgotPassword.alpha = 1.0
                })
                
            }
            
        }
        
    }
    
    @IBAction func terms(sender: AnyObject) {
        let alertController = UIAlertController(title: "Terms", message: "Robots are hard at work getting these documents in order. They should be finished by the Beta version of Gate!", preferredStyle: .Alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alertController.addAction(defaultAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func toggleForgotPassword(sender: AnyObject) {
        
        if viewState == .Login {
            viewState = .ForgotPassword
            
            forgotPassword.setTitle("Remembered your password?", forState: UIControlState.Normal)
            toggle.setTitle("Log In", forState: UIControlState.Normal)
            command.setTitle("Send Email", forState: UIControlState.Normal)
            
            textFieldChanged()
            
            UIView.animateWithDuration(0.25, animations: {
                self.password.alpha = 0.0
                self.password.enabled = false
            })
        } else if viewState == .ForgotPassword {
            viewState = .Login
            
            forgotPassword.setTitle("Forgot your password?", forState: UIControlState.Normal)
            toggle.setTitle("Register", forState: UIControlState.Normal)
            command.setTitle("Log In", forState: UIControlState.Normal)
            
            password.enabled = true
            
            textFieldChanged()
            
            UIView.animateWithDuration(0.25, animations: {
                self.password.alpha = 1.0
            })
        }
        
    }
    
    @IBAction func processCommand(sender: AnyObject) {
        
        switch viewState! {
        case .Login:
            processLogin()
        case .Register:
            processRegistration()
        case .ForgotPassword:
            processForgotPassword()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewState = .Login
        
        email.addTarget(self, action: Selector("textFieldChanged"), forControlEvents: UIControlEvents.EditingChanged)
        
        password.addTarget(self, action: Selector("textFieldChanged"), forControlEvents: UIControlEvents.EditingChanged)
        
        name.addTarget(self, action: Selector("textFieldChanged"), forControlEvents: UIControlEvents.EditingChanged)
    
        // For proper keyboard return functionality
        email.delegate = self
        password.delegate = self
        name.delegate = self
        
        var last_email_used = NSUserDefaults.standardUserDefaults().objectForKey("last_used_email") as? String
        if last_email_used != nil {
            email.text = last_email_used
        }
    }
    
    func processLogin() {
        
        var request = HTTPTask()
        
        var emailText = strippedString(email.text)
        var passwordText = strippedString(password.text)
        
        var params = [String: AnyObject]()
        
        var user = [ "email" : emailText, "password" : passwordText ]
        
        params["user"] = user
        params["api_key"] = "09b19f4a-6e4d-475a-b7c8-a369c60e9f83"
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.POST("https://infinite-river-7560.herokuapp.com/api/v1/sessions.json", parameters: params,
            success: {(response: HTTPResponse) in

                self.storeSessionData(response.responseObject! as Dictionary<String, Dictionary<String, AnyObject>>)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.performSegueWithIdentifier("loginUser", sender: self)
                })
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                
                var message = ""
                
                if response != nil {
                    
                    let unwrappedResponse = response!
                    
                    if unwrappedResponse.statusCode! == 422 {
                        let errorsDict = unwrappedResponse.responseObject! as Dictionary<String, Array<String>>
                        var errors = errorsDict["errors"]
                        message = errors![0]
                    } else {
                        message = "We made a mistake somewhere. Robots are investigating."
                    }
                    
                } else {
                    message = "We couldn't connect to the internet"
                }
                
                let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
                
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                
                alertController.addAction(defaultAction)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(alertController, animated: true, completion: nil)
                })
        })
    }
    
    func processRegistration() {
        var request = HTTPTask()
        
        var emailText = strippedString(email.text)
        var passwordText = strippedString(password.text)
        var nameText = strippedString(name.text)
        
        var params = [String: AnyObject]()
        
        var user = [ "email" : emailText, "password" : passwordText, "name" : nameText ]
        
        params["user"] = user
        params["api_key"] = "09b19f4a-6e4d-475a-b7c8-a369c60e9f83"
        
        request.responseSerializer = JSONResponseSerializer()
        
        request.POST("https://infinite-river-7560.herokuapp.com/api/v1/registrations.json", parameters: params,
            success: {(response: HTTPResponse) in
                
                self.storeSessionData(response.responseObject! as Dictionary<String, Dictionary<String, AnyObject>>)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.performSegueWithIdentifier("loginUser", sender: self)
                })
                
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                
                var message = ""
                
                if response != nil {
                    
                    let unwrappedResponse = response!
                    
                    if unwrappedResponse.statusCode! == 422 {
                        let errorsDict = unwrappedResponse.responseObject as Dictionary<String, Array<String>>
                        
                        var errors = errorsDict["errors"]!
                        
                        for var i = 0; i < errors.count; i++ {
                            if i != 0 {
                                message += "\n"
                            }
                            
                            message += errors[i]
                        }
                    } else {
                        message = "We made a mistake somewhere. Robots are investigating."
                    }
                } else {
                    message = "We couldn't connect to the internet"
                }
                
                let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
                
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                
                alertController.addAction(defaultAction)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(alertController, animated: true, completion: nil)
                })
        })
        
    }
    
    func processForgotPassword() {
        var request = HTTPTask()
        
        var emailText = strippedString(email.text)
        
        var params = [ "email" : emailText ]
        
        request.GET("https://infinite-river-7560.herokuapp.com/forgot_password", parameters: params,
            success: {(response: HTTPResponse) in
                
                let alertController = UIAlertController(title: "Email Sent", message: nil, preferredStyle: .Alert)
                
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                
                alertController.addAction(defaultAction)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(alertController, animated: true, completion: nil)
                })
                
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                
                var message = ""
                
                if response != nil {
                
                    let unwrappedResponse = response!
                    
                    if unwrappedResponse.statusCode == 404 {
                        message = "Email not registered"
                    } else {
                        message = "We made a mistake somewhere. Robots are investigating."
                    }
                 
                } else {
                    message = "We couldn't connect to the internet"
                }
                

                let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
                
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                
                alertController.addAction(defaultAction)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(alertController, animated: true, completion: nil)
                })
                
            })
        
    
    }
    
    func textFieldChanged() {
        
        var emailChars = strippedString(email.text)
        
        var passwordChars = strippedString(password.text)
        
        var nameChars = strippedString(name.text)
        
        if emailChars.isEmpty ||
           !validateEmail(emailChars) ||
            (viewState != .ForgotPassword && passwordChars.isEmpty) ||
            (viewState == .Register && nameChars.isEmpty) {
                
                if command.enabled == true {
                    disableCommandButton()
                }
                
        } else if command.enabled == false {
            enableCommandButton()
        }
        
    }
    
    func disableCommandButton() {
        command.alpha = 0.3
        command.enabled = false
    }
    
    func enableCommandButton() {
        command.alpha = 1.0
        command.enabled = true
    }
    
    func strippedString(text: String) -> String {
        return text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
        
    func validateEmail(candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex)!.evaluateWithObject(candidate)
    }
    
    func storeSessionData(response: Dictionary<String, Dictionary<String, AnyObject>>) {
        
        var defaults = NSUserDefaults.standardUserDefaults()
        
        var user: Dictionary<String, AnyObject> = response["user"]!
        
        defaults.setObject(user["auth_token"], forKey: "auth_token")
        defaults.setObject(user["created_at"], forKey: "created_at")
        defaults.setObject(user["email"], forKey: "email")
        defaults.setObject(user["external_id"], forKey: "user_id")
        defaults.setObject(user["name"], forKey: "name")
        defaults.setObject(user["email"], forKey: "last_used_email")
        
        defaults.synchronize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
        self.view.endEditing(true)
        
    }
        
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
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
