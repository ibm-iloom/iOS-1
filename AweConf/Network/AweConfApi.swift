//
// Created by Matteo Crippa on 30/01/2018.
// Copyright (c) 2018 Matteo Crippa. All rights reserved.
//

import Alamofire
import Foundation

enum AweConfApi: URLRequestConvertible {
    case list()
    case categories()
    case submit(conference: Conference)

    static let baseURLString = "https://aweconf.herokuapps.com"

    var method: HTTPMethod {
        switch self {
            case .list:
                return .post
            case .categories:
                return .get
            case .submit:
                return .post
        }
    }

    var path: String {
        switch self {
            case .list:
                return "/conference"
            case .categories:
                return "/categories"
            case .submit:
                return "/conference/submit"
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = try AweConfApi.baseURLString.asURL()

        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue

        switch self {
            case .list:
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [:])
            case .categories:
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [:])
            case .submit(let conference):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: [:])
        }

        return urlRequest
    }
}
