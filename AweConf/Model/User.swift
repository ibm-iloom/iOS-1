//
//  User.swift
//  AweConf
//
//  Created by Matteo Crippa on 18/02/2018.
//  Copyright © 2018 Matteo Crippa. All rights reserved.
//

import Foundation
import RealmSwift

class User: Object {
    @objc dynamic var name = ""
    
    override static func primaryKey() -> String? {
        return "name"
    }
    
    convenience required init(name: String) {
        self.init()
        self.name = name
    }
}
