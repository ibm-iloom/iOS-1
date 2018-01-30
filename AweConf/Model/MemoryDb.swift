//
//  MemoryDb.swift
//  amcios
//
//  Created by Matteo Crippa on 01/10/2017.
//  Copyright © 2017 Matteo Crippa. All rights reserved.
//

import Foundation

class MemoryDb {
    /// Shared instance
    open static var shared = MemoryDb()
    private init() {}

    /// Contains data
    var data: Awesome? {
        didSet {
            lastUpdate = Date()
        }
    }
    
    /// Contains the headers for the list view
    var headers = [String]()

    /// Contains last update date
    var lastUpdate = Date()
}
