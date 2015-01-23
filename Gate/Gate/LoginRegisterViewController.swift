//
//  LoginRegisterViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/23/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

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
    
    }
    
    @IBAction func terms(sender: AnyObject) {
    
    }
    
    @IBAction func toggleForgotPassword(sender: AnyObject) {
        
        if (viewState == .Login) {
            viewState = .ForgotPassword
            
            forgotPassword.setTitle("Remembered your password?", forState: UIControlState.Normal)
            toggle.setTitle("Log In", forState: UIControlState.Normal)
            command.setTitle("Send Email", forState: UIControlState.Normal)
            
            UIView.animateWithDuration(0.25, animations: {
                self.password.alpha = 0.0
            })
        } else if viewState == .ForgotPassword {
            viewState = .Login
            
            forgotPassword.setTitle("Forgot your password?", forState: UIControlState.Normal)
            toggle.setTitle("Register", forState: UIControlState.Normal)
            command.setTitle("Log In", forState: UIControlState.Normal)
            
            UIView.animateWithDuration(0.25, animations: {
                self.password.alpha = 1.0
            })
        }
        
    }
    
    @IBAction func processCommand(sender: AnyObject) {
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewState = .Login
        
        email.addTarget(self, action: Selector("textFieldChanged"), forControlEvents: UIControlEvents.EditingChanged)
        
        password.addTarget(self, action: Selector("textFieldChanged"), forControlEvents: UIControlEvents.EditingChanged)
        
        name.addTarget(self, action: Selector("textFieldChanged"), forControlEvents: UIControlEvents.EditingChanged)
    
        email.delegate = self
        password.delegate = self
        name.delegate = self
    }
    
    
    func textFieldChanged() {
        
        var emailChars = email.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        var passwordChars = password.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        var nameChars = name.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
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
    
    func validateEmail(candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex)!.evaluateWithObject(candidate)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
        self.view.endEditing(true)
        
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
