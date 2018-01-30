//
//  Awesome.swift
//  amcios
//
//  Created by Matteo Crippa on 01/10/2017.
//  Copyright © 2017 Matteo Crippa. All rights reserved.
//

import Foundation

struct Awesome: Codable {
    let title: String
    let header: String
    let header_contributing: String?
    let ios_app_link: String?
    let conferences: [Conference]
    let years: [Int]
}
