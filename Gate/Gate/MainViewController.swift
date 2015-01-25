//
//  MainViewController.swift
//  Gate
//
//  Created by David Ilizarov on 1/23/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UIScrollViewDelegate {
    
    var scrollView:UIScrollView!
    var pageControl:UIPageControl!
    var navbarView:UIView!
    
    var navTitleLabel1:UILabel!
    var navTitleLabel2:UILabel!
    
    var feedViewController: FeedViewController!
    var gatesViewController: GatesViewController!
    
    var view1:UIView!
    var view2:UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var navBar: UINavigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, 64))
        
        navBar.barTintColor = UIColor.blackColor()
        navBar.translucent = false
        
        self.view.backgroundColor = UIColor.lightGrayColor()
        
        //Creating some shorthand for these values
        var wBounds = self.view.bounds.width
        var hBounds = self.view.bounds.height
        
        // This houses all of the UIViews / content
        scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.frame = self.view.frame
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.bounces = false
        self.view.addSubview(scrollView)
        
        self.scrollView.contentSize = CGSize(width: self.view.bounds.size.width * 2, height: hBounds/2)
        
        //Putting a subview in the navigationbar to hold the titles and page dots
        navbarView = UIView()
        
        //Paging control is added to a subview in the uinavigationcontroller
        pageControl = UIPageControl()
        pageControl.frame = CGRect(x: 0, y: 35, width: 0, height: 0)
        pageControl.pageIndicatorTintColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        pageControl.currentPageIndicatorTintColor = UIColor.whiteColor()
        pageControl.numberOfPages = 2
        pageControl.currentPage = 0
        self.navbarView.addSubview(pageControl)
        
        
        //Titles for the nav controller (also added to a subview in the uinavigationcontroller)
        //Setting size for the titles. FYI changing width will break the paging fades/movement
        
        navTitleLabel1 = UILabel()
        navTitleLabel1.frame = CGRect(x: 0, y: 8, width: wBounds, height: 20)
        navTitleLabel1.textColor = UIColor.whiteColor()
        navTitleLabel1.textAlignment = NSTextAlignment.Center
        navTitleLabel1.text = "Aggregate"
        self.navbarView.addSubview(navTitleLabel1)
        
        navTitleLabel2 = UILabel()
        navTitleLabel2.alpha = 0.0
        navTitleLabel2.frame = CGRect(x: 100, y: 8, width: wBounds, height: 20)
        navTitleLabel2.textColor = UIColor.whiteColor()
        navTitleLabel2.textAlignment = NSTextAlignment.Center
        navTitleLabel2.text = "Gates"
        self.navbarView.addSubview(navTitleLabel2)
        
        //Views for the scrolling view
        //This is where the content of your views goes (or you can subclass these and add them to ScrollView)
        
        feedViewController = storyboard?.instantiateViewControllerWithIdentifier("FeedController") as FeedViewController
        
        view1 = feedViewController.view
        
        addChildViewController(feedViewController)
        feedViewController.didMoveToParentViewController(self)
        
        view1.frame = CGRectMake(0, 0, wBounds, hBounds)
        self.scrollView.addSubview(view1)
        self.scrollView.bringSubviewToFront(view1)
        
        //Notice the x position increases per number of views
        
        gatesViewController = storyboard?.instantiateViewControllerWithIdentifier("GatesController") as GatesViewController
        
        view2 = gatesViewController.view
        
        addChildViewController(gatesViewController)
        gatesViewController.didMoveToParentViewController(self)
        
        view2.frame = CGRectMake(wBounds, 0, wBounds, hBounds)
        self.scrollView.addSubview(view2)
        self.scrollView.bringSubviewToFront(view2)
        
        navBar.addSubview(navbarView)
        self.view.addSubview(navBar)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        navbarView.frame = CGRect(x: 0, y: 20, width: self.view.bounds.width, height: 64)
    }
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        var xOffset: CGFloat = scrollView.contentOffset.x
        
        //Setup some math to position the elements where we need them when the view is scrolled
        
        var wBounds = self.view.bounds.width
        var hBounds = self.view.bounds.height
        var widthOffset = wBounds / 100
        var offsetPosition = 0 - xOffset/widthOffset
        
        //Apply the positioning values created above to the frame's position based on user's scroll
        
        navTitleLabel1.frame = CGRectMake(offsetPosition, 8, wBounds, 20)
        navTitleLabel2.frame = CGRectMake(offsetPosition + 100, 8, wBounds, 20)
        
        //Change the alpha values of the titles as they are scrolled
        
        navTitleLabel1.alpha = 1 - xOffset / wBounds
        
        if (xOffset <= wBounds) {
            navTitleLabel2.alpha = xOffset / wBounds
        } else {
            navTitleLabel2.alpha = 1 - (xOffset - wBounds) / wBounds
        }
        
    }
    
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        var xOffset: CGFloat = scrollView.contentOffset.x
        
        //Change the pageControl dots depending on the page / offset values
        
        if (xOffset < 1.0) {
            pageControl.currentPage = 0
        } else if (xOffset < self.view.bounds.width + 1) {
            pageControl.currentPage = 1
        }
        
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
