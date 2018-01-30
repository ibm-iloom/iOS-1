//
//  Conference.swift
//  amcios
//
//  Created by Matteo Crippa on 01/10/2017.
//  Copyright © 2017 Matteo Crippa. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

class Conference: Object {

    @objc dynamic var id = ""
    @objc dynamic var title = ""
    @objc dynamic var year = 0
    @objc dynamic var startDate = Date()
    @objc dynamic var endDate = Date()
    @objc dynamic var city = ""
    @objc dynamic var country = ""
    @objc dynamic var address = ""
    @objc dynamic var homepage = ""
    @objc dynamic var callForPaper = false
    @objc dynamic var emojiFlag = ""
    @objc dynamic var twitter = ""
    @objc dynamic var approved = false
    @objc dynamic var lat: Double = 0.0
    @objc dynamic var lon: Double = 0.0
    @objc dynamic var added = Date()
    let topic = List<Topic>()
    let category = List<Category>()

    override static func primaryKey() -> String? {
        return "id"
    }

    var isNew: Bool {
        get {
            let lastUpdate = Date(timeIntervalSince1970: Double(UserDefaults.standard.float(forKey: "lastUpdate")))
            return self.added > lastUpdate
        }
    }

    var isFavorite: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "FAV/"+self.id)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "FAV/"+self.id)
            UserDefaults.standard.synchronize()
        }
    }
    
    convenience required init(json: JSON) {
        self.init()
        mapping(json)
    }
    
    private func mapping(_ json: JSON) {
        // date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // populate date
        self.id = json.stringValue("_id")
        self.title = json.stringValue("title")
        self.year = json.intValue("year")
        self.startDate = dateFormatter.date(from: json.stringValue("startdate")) ?? Date()
        self.endDate = dateFormatter.date(from: json.stringValue("enddate")) ?? Date()
        self.city = json.stringValue("city")
        self.address = json.stringValue("where")
        self.homepage = json.stringValue("homepage")
        self.callForPaper = json.boolValue("callforpaper")
        self.emojiFlag = json.stringValue("emojiflag")
        self.twitter = json.stringValue("twitter")
        self.approved = json.boolValue("approved")
        self.lat = json.doubleValue("lat")
        self.lon = json.doubleValue("lon")
        self.added = dateFormatter.date(from: json.stringValue("added")) ?? Date()

        // categories
        for cat in json.getJSONArray("category") {
            
        }
        /*for (cat in json.getJSONArray("category").arrayOfString()) {
            Category().queryFirst { query -> query.equalTo("name", cat) }?.let {
                self.category.add(it)
            }
        }*/

        // topic
        for topic in json.getJSONArray("topic") {
            
        }
        /*for (topic in json.getJSONArray("topic").arrayOfString()) {
            Topic().queryFirst { query -> query.equalTo("name", topic) }?.let {
                self.topic.add(it)
            }
        }*/
    }

}

