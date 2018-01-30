//
// Created by Matteo Crippa on 30/01/2018.
// Copyright (c) 2018 Matteo Crippa. All rights reserved.
//

import Foundation
import RealmSwift

class Topic: Object {
    @objc dynamic var name = ""
    let conferences = LinkingObjects(fromType: Conference.self, property: "topic")

    override static func primaryKey() -> String? {
        return "name"
    }

    convenience required init(name: String) {
        self.init()
        self.name = name
    }
}
