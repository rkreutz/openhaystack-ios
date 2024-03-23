//
//  URLSessionHTTPClient.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 20/03/24.
//

import Foundation

final class URLSessionHTTPClient: HTTPClient {
    enum Error: Swift.Error {
        case invalidRequest
        case invalidResponse
        case errorResponse(Data)
    }
    
    private let session: URLSession
    init(session: URLSession) {
        self.session = session
    }
    
    func request(_ request: HTTPRequest, completion: @escaping (Result<Data, Swift.Error>) -> Void) {
        guard let request = URLRequest(from: request) else {
            completion(.failure(Error.invalidRequest))
            return
        }
        
        session
            .dataTask(with: request) { data, response, error in
                guard error == nil else {
                    completion(.failure(error.unsafelyUnwrapped))
                    return
                }
                
                guard let response = response as? HTTPURLResponse else {
                    completion(.failure(Error.invalidResponse))
                    return
                }
                
                switch response.statusCode {
                case 200 ... 299:
                    completion(.success(data ?? Data()))
                case 300 ... 399:
                    completion(.success(Data()))
                default:
                    completion(.failure(Error.errorResponse(data ?? Data())))
                }
            }
            .resume()
    }
}

private extension URLRequest {
    init?(from request: HTTPRequest) {
        let urlComponents = URLComponents(string: request.url.absoluteString, encodingInvalidCharacters: true)
        guard let url = urlComponents?.url else { return nil }
        self.init(url: url)
        self.httpMethod = request.method.rawValue
        self.httpBody = request.body
        for (key, value) in request.headers {
            self.setValue(value, forHTTPHeaderField: key.rawValue)
        }
    }
}
