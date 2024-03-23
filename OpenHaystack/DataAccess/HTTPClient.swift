//
//  HTTPClient.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 20/03/24.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum HTTPHeader: String {
    case authorization = "Authorization"
    case contentType = "Content-Type"
    case accept = "Accept"
}

struct HTTPRequest {
    var url: URL
    var method: HTTPMethod = .get
    var body: Data = Data()
    var headers: [HTTPHeader: String] = [
        .contentType: "application/json",
        .accept: "application/json"
    ]
}

protocol HTTPClient {
    func request(_ request: HTTPRequest, completion: @escaping (Result<Data, Error>) -> Void)
}
