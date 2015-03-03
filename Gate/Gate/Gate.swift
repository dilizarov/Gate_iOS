//
//  Gate.swift
//  Gate
//
//  Created by David Ilizarov on 1/25/15.
//  Copyright (c) 2015 David Ilizarov. All rights reserved.
//

import Foundation

class Gate {
    
    var id: String
    var name: String
    var usersCount: String
    var creator: String
    var generated: Bool
    
    //NOTE:
    // This is used when showing appropriate feed based on Gate from notification.
    // I don't pass in the usersCount nor the creator. usersCount isn't used in FeedFragment
    // and creator isn't used at all right now. This might get probablematic later when more updates
    // come, but at that time, the notification infrastructure can be edited.
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
        self.usersCount = ""
        self.creator = ""
        self.generated = false
    }
    
    init(id: String, name: String, usersCount: Int, creator: String, generated: Bool) {
        self.id = id
        self.name = name
        self.usersCount = "\(usersCount)"
        self.creator = creator
        self.generated = generated
    }
    
    
}