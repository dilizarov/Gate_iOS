//
//  PostCell.swift
//  Gate
//
//  Created by David Ilizarov on 1/31/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import UIKit

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
    
        println("liked \(post.id)")
    
    }
    
    @IBAction func commentOnPost(sender: AnyObject) {
        println("commented on \(post.id)")
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
            self.likesCount.text = "\(post.likeCount) likes"
            
            self.likesCount.alpha = 1.0
            self.contentView.removeConstraint(constraints["likesCountGone"]!)
        } else {
            self.likesCount.alpha = 0.0
            self.contentView.addConstraint(constraints["likesCountGone"]!)
        }
        
        if post.commentCount > 0 {
            self.commentsCount.text = "\("
        } else {
            
        }

    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        constraints["gateNameGone"] = NSLayoutConstraint(item: gateName, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 0)
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
   
}
