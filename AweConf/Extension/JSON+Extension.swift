//
//  JSON+Extension.swift
//  AweConf
//
//  Created by Matteo Crippa on 30/01/2018.
//  Copyright © 2018 Matteo Crippa. All rights reserved.
//

import Foundation
import SwiftyJSON

extension JSON {
    func stringValue(_ name: String) -> String {
        return self[name].stringValue
    }
    
    func intValue(_ name: String) -> Int {
        return self[name].intValue
    }
    
    func doubleValue(_ name: String) -> Double {
        return self[name].doubleValue
    }
    
    func boolValue(_ name: String) -> Bool {
        return self[name].boolValue
    }
    
    func getJSONArray(_ name: String) -> Array<Any> {
        return self[name].arrayValue
    }
}
