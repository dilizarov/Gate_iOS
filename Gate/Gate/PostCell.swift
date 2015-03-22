//
//  PostCell.swift
//  Gate
//
//  Created by David Ilizarov on 1/31/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class PostCell: UITableViewCell {
    
    var constraints = [String : NSLayoutConstraint ]()
    
    var post: Post!
    var gate: Gate?
    
    @IBOutlet var name: UILabel!
    @IBOutlet var timestamp: UILabel!
    @IBOutlet var postBody: UILabel!
    @IBOutlet var gateName: UILabel!
    @IBOutlet var likesCount: UILabel!
    @IBOutlet var commentsCount: UILabel!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var commentButton: UIButton!
    
    @IBAction func likePost(sender: AnyObject) {
        toggleLikePost()
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params : Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        if !post.liked { params["revert"] = true }
                
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/posts/\(post.id)/up.json", parameters: params,
            success: {(response: HTTPResponse) in
                // Don't do anything, because we preprocessed what happens.
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.toggleLikePost()
                    
                    iToast.makeText(String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                })
            }
        )
    }
        
    func configureViews(post: Post, gate: Gate?) {
        
        self.post = post
        self.gate = gate
        
        self.name.text = post.name
        self.timestamp.text = post.timestamp
        self.postBody.text = post.body
        
        if gate == nil {
            self.gateName.text = post.gateName
            
            self.gateName.alpha = 1.0
            self.contentView.removeConstraint(constraints["gateNameGone"]!)
        } else {
            self.gateName.alpha = 0.0
            self.contentView.addConstraint(constraints["gateNameGone"]!)
        }
        
        if post.likeCount > 0 {
            var text = "\(post.likeCount) like"
            
            if post.likeCount != 1 { text += "s" }
            
            self.likesCount.text = text

            self.likesCount.alpha = 1.0
        } else {
            self.likesCount.alpha = 0.0
        }
        
        UIView.setAnimationsEnabled(false)
        if post.liked {
            self.likeButton.setTitle("Unlike", forState: .Normal)
        } else {
            self.likeButton.setTitle("Like", forState: .Normal)
        }
        // Trick for system buttons when trying to set title without animation.
        self.likeButton.layoutIfNeeded()
        
        UIView.setAnimationsEnabled(true)
        
        if post.commentCount > 0 {
            var text = "\(post.commentCount) comment"
            
            if post.commentCount != 1 { text += "s" }
            
            self.commentsCount.text = text
            
            self.commentsCount.alpha = 1.0
        } else {
            self.commentsCount.alpha = 0.0
        }

    }
    
    func toggleLikePost() {
        if post.liked {
            post.liked = false
            
            post.likeCount -= 1
            
            self.likeButton.setTitle("Like", forState: .Normal)
            
            if post.likeCount == 0 {
                UIView.animateWithDuration(0.25, animations: {
                    self.likesCount.alpha = 0.0
                })
            } else {
                var text = "\(post.likeCount) like"
                
                if post.likeCount != 1 { text += "s" }
                
                self.likesCount.text = text
            }
            
        } else {
            post.liked = true
            
            post.likeCount += 1
            
            self.likeButton.setTitle("Unlike", forState: .Normal)
            
            if post.likeCount == 1 {
                self.likesCount.text = "1 like"
                
                UIView.animateWithDuration(0.25, animations: {
                    self.likesCount.alpha = 1.0
                })
                
            } else {
                self.likesCount.text = "\(post.likeCount) likes"
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        constraints["gateNameGone"] = NSLayoutConstraint(item: gateName, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 0)
        
        self.layoutIfNeeded()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
   
}
