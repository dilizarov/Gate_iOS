//
//  CameraViewController.swift
//  Gate
//
//  Created by David Ilizarov on 3/14/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    let captureSession = AVCaptureSession()
    
    var captureDevice: AVCaptureDevice?
    
    @IBOutlet var actionsView: UIView!
    
    @IBOutlet var gridButton: UIButton!
    @IBOutlet var frontBackToggleButton: UIButton!
    @IBOutlet var flashButton: UIButton!
    @IBOutlet var takePictureButton: UIButton!
    @IBOutlet var galleryButton: UIButton!
    
    @IBOutlet var cameraNotSupported: UILabel!
    
    
    @IBAction func viewGallery(sender: AnyObject) {
    }
    
    @IBAction func toggleGrid(sender: AnyObject) {
        
    }
    
    @IBAction func toggleFrontBack(sender: AnyObject) {
    }
    
    @IBAction func adjustFlash(sender: AnyObject) {
    }
    
    
    @IBAction func takePictureAction(sender: AnyObject) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        actionsView.layer.zPosition = 5000
        
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        
        var devices = AVCaptureDevice.devices()
        
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                if (device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if captureDevice != nil {
            beginSession()
        } else {
            cameraNotSupported.alpha = 1.0
        }
        
    }
    
    func setupNavBar() {
        var navBar: UINavigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, 64))
        
        navBar.barTintColor = UIColor.blackColor()
        
        navBar.layer.zPosition = 5000
        
        navBar.alpha = 0.9
        
        var navigationItem = UINavigationItem()
        
        var backButton = UIBarButtonItem(image: UIImage(named: "Back"), style: .Plain, target: self, action: Selector("dismiss"))
        
        backButton.tintColor = UIColor.whiteColor()
        
        navigationItem.leftBarButtonItem = backButton
                
        self.view.addSubview(navBar)
        
        navBar.pushNavigationItem(navigationItem, animated: false)
    }

    func beginSession() {
        var err: NSError? = nil
        
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            device.torchMode = .On
            device.focusMode = .ContinuousAutoFocus
            device.unlockForConfiguration()
        }
        
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        
        previewLayer.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
            
        captureSession.startRunning()
    }
    
    func dismiss() {
        (UIApplication.sharedApplication().delegate as AppDelegate).toggledViewController = nil
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
