//
//  MyViewController.swift
//  Gate
//
//  Created by David Ilizarov on 2/27/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

class MyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("dismissForNotif"), name: "dismissForNotif", object: nil)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func dismissForNotif() {
        if self is MainViewController {
            NSNotificationCenter.defaultCenter().postNotificationName("handleNotification", object: nil)
        } else {
            self.dismissViewControllerAnimated(true, completion: {
                if self.parentViewController? is MainViewController {
                    NSNotificationCenter.defaultCenter().postNotificationName("handleNotification", object: nil)
                }
            })
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "dismissForNotif", object: nil)
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
