//
//  CommentCell.swift
//  Gate
//
//  Created by David Ilizarov on 2/3/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit
import SwiftHTTP

class CommentCell: UITableViewCell {
    
    var comment: Comment!
    
    @IBOutlet var name: UILabel!
    @IBOutlet var timestamp: UILabel!
    @IBOutlet var commentBody: UILabel!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var likesCount: UILabel!
    
    @IBAction func likeComment(sender: AnyObject) {
        toggleLikeComment()
        
        var request = HTTPTask()
        
        var userInfo = NSUserDefaults.standardUserDefaults()
        
        var params : Dictionary<String, AnyObject> = [ "user_id" : userInfo.objectForKey("user_id") as String, "auth_token" : userInfo.objectForKey("auth_token") as String, "api_key" : "91b75c9e-6a00-4fa9-bf65-610c12024bab" ]
        
        if !comment.liked { params["revert"] = true }
        
        request.GET("https://infinite-river-7560.herokuapp.com/api/v1/comments/\(comment.id)/up.json", parameters: params,
            success: {(response: HTTPResponse) in
                // Don't do anything, because we preprocessed what happens.
            },
            failure: {(error: NSError, response: HTTPResponse?) in
                dispatch_async(dispatch_get_main_queue(), {
                    self.toggleLikeComment()
                    
                    iToast.makeText(" " + String.prettyErrorMessage(response)).setGravity(iToastGravityCenter).setDuration(3000).show()
                })
            }
        )
    }
    
    func configureViews(comment: Comment) {
        
        self.comment = comment
        
        self.name.text = comment.name
        self.timestamp.text = comment.timestamp
        self.commentBody.text = comment.body
        
        if comment.likeCount > 0 {
            var text = "\(comment.likeCount) like"
            
            if comment.likeCount != 1 { text += "s" }
            
            self.likesCount.text = text
            
            self.likesCount.alpha = 1.0
        } else {
            self.likesCount.alpha = 0.0
        }
        
        UIView.setAnimationsEnabled(false)
        if comment.liked {
            self.likeButton.setTitle("Unlike", forState: .Normal)
        } else {
            self.likeButton.setTitle("Like", forState: .Normal)
        }
        UIView.setAnimationsEnabled(true)
        
    }
    
    func toggleLikeComment() {
        if comment.liked {
            comment.liked = false
            
            comment.likeCount -= 1
            
            self.likeButton.setTitle("Like", forState: .Normal)
            
            if comment.likeCount == 0 {
                UIView.animateWithDuration(0.25, animations: {
                    self.likesCount.alpha = 0.0
                })
            } else {
                var text = "\(comment.likeCount) like"
                
                if comment.likeCount != 1 { text += "s" }
                
                self.likesCount.text = text
            }
        } else {
            comment.liked = true
            
            comment.likeCount += 1
            
            self.likeButton.setTitle("Unlike", forState: .Normal)
            
            if comment.likeCount == 1 {
                self.likesCount.text = "1 like"
                
                UIView.animateWithDuration(0.25, animations: {
                    self.likesCount.alpha = 1.0
                })
            
            } else {
                self.likesCount.text = "\(comment.likeCount) likes"
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.layoutIfNeeded()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
