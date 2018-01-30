//
// Created by Matteo Crippa on 30/01/2018.
// Copyright (c) 2018 Matteo Crippa. All rights reserved.
//

import Foundation

class AMCApi {
    class func getData() -> Data? {
        do {
            let data = try Data(contentsOf: URL(string: "https://raw.githubusercontent.com/AwesomeMobileConferences/awesome-mobile-conferences/master/contents.json")!)
            return data
        } catch (let error) {
            print("🙅 \(error)")
            return nil
        }
    }

}