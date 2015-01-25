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
    
    init(id: String, name: String, usersCount: Int, creator: String) {
        self.id = id
        self.name = name
        self.usersCount = "\(usersCount)"
        self.creator = creator
    }
    
    
}