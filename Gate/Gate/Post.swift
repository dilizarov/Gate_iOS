//
//  Post.swift
//  Gate
//
//  Created by David Ilizarov on 1/28/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import Foundation

class Post {
    
    var id: String
    var name: String
    var body: String
    var gateId: String
    var gateName: String
    var commentCount: Int
    var likeCount: Int
    var liked: Bool
    var timestamp: String
    var timeCreated: NSDate
    
    init(id: String, name: String, body: String, gateId: String, gateName: String, commentCount: Int, likeCount: Int, liked: Bool, timeCreated: String) {
        self.id = id
        self.name = name
        self.body = body
        self.gateId = gateId
        self.gateName = gateName
        self.commentCount = commentCount
        self.likeCount = likeCount
        self.liked = liked
        self.timeCreated = timeCreated.toNSDate()
        self.timestamp = NSDate().offsetFrom(self.timeCreated)
    }
}
