//
//  LoginRegisterViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/23/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

class LoginRegisterViewController: UIViewController {
    
    enum ViewState {
        case Login, Register, ForgotPassword
    }
    
    var viewState: ViewState?
    
    @IBOutlet var email: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var name: UITextField!
    @IBOutlet var forgotPassword: UIButton!
    @IBOutlet var command: UIButton!
    
    @IBAction func toggleRegisterLogin(sender: AnyObject) {
    
    }
    
    @IBAction func terms(sender: AnyObject) {
    
    }
    
    @IBAction func toggleForgotPassword(sender: AnyObject) {
    
    }
    
    @IBAction func processCommand(sender: AnyObject) {
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewState = .Login
        
        email.addTarget(self, action: Selector("textFieldChanged"), forControlEvents: UIControlEvents.EditingChanged)
        
        password.addTarget(self, action: Selector("textFieldChanged"), forControlEvents: UIControlEvents.EditingChanged)
        
        name.addTarget(self, action: Selector("textFieldChanged"), forControlEvents: UIControlEvents.EditingChanged)
    }
    
    
    func textFieldChanged() {
        
        var emailChars = email.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        var passwordChars = password.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        var nameChars = name.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if emailChars.isEmpty ||
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
