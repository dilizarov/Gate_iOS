//
//  Comment.swift
//  Gate
//
//  Created by David Ilizarov on 2/3/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import Foundation

class Comment {
    
    var id: String
    var name: String
    var body: String
    var likeCount: Int
    var liked: Bool
    var timestamp: String
    var timeCreated: NSDate
    
    init(id: String, name: String, body: String, likeCount: Int, liked: Bool, timeCreated: String) {
        self.id = id
        self.name = name
        self.body = body
        self.likeCount = likeCount
        self.liked = liked
        self.timeCreated = timeCreated.toNSDate()
        self.timestamp = NSDate().offsetFrom(self.timeCreated)
    }
}