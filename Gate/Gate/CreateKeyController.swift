//
//  createKeyController.swift
//  Gate
//
//  Created by David Ilizarov on 1/26/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

class CreateKeyController: UIViewController {

    var gates = [Gate]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        println(gates[0].name)
        
        // Do any additional setup after loading the view.
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
