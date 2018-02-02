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
            let lastUpdate = Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: "lastUse"))
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
    
    var yearMonth: String {
        return self.startDate.toString(dateFormat: "YYYY MMMM")
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
        let startDateString = json.stringValue("startdate")
        let startIndexEnd = startDateString.index(startDateString.startIndex, offsetBy: 10)
        self.startDate = dateFormatter.date(from: startDateString.substring(to: startIndexEnd)) ?? Date()
        
        let endDateString = json.stringValue("enddate")
        let endIndexEnd = endDateString.index(endDateString.startIndex, offsetBy: 10)
        self.endDate = dateFormatter.date(from: endDateString.substring(to: endIndexEnd)) ?? Date()
        
        self.city = json.stringValue("city")
        self.address = json.stringValue("where")
        self.homepage = json.stringValue("homepage")
        self.country = json.stringValue("country")
        self.callForPaper = json.boolValue("callforpaper")
        self.emojiFlag = json.stringValue("emojiflag")
        self.twitter = json.stringValue("twitter")
        self.approved = json.boolValue("approved")
        self.lat = json.doubleValue("lat")
        self.lon = json.doubleValue("lon")

        let addedDateString = json.stringValue("added")
        let addedIndexEnd = addedDateString.index(addedDateString.startIndex, offsetBy: 10)
        self.added = dateFormatter.date(from: addedDateString.substring(to: addedIndexEnd)) ?? Date()
        
        // realm
        let realm = try! Realm()
        
        // categories
        for cat in json["category"].arrayValue {
            
            // find item
            if let catItem = realm.objects(Category.self).filter({ category -> Bool in
                return category.name == cat.stringValue
            }).first {
                // add to list
                self.category.append(catItem)
            }
            
        }
        
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
