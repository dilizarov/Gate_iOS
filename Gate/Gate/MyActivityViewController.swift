//
//  MyActivityViewController.swift
//  Gate
//
//  Created by David Ilizarov on 2/27/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

class MyActivityViewController: UIActivityViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("dismissActivityForNotif"), name: "dismissActivityForNotif", object: nil)
        // Do any additional setup after loading the view.
    }

    func dismissActivityForNotif() {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "dismissActivityForNotif", object: nil)
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
