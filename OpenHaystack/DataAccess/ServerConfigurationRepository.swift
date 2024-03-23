//
//  ServerConfigurationRepository.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 20/03/24.
//

import Foundation

final class ServerConfigurationRepository {
    
    enum Constants {
        static let serverUrlKey = "server_url"
        static let authorizationTypeKey = "authorization_type"
        static let authorizationValueKey = "authorization_value"
        
        enum AuthorizationType {
            static let none = "none"
            static let httpHeader = "http_header"
        }
    }
    
    private let storage: KeyValueStorage
    init(storage: KeyValueStorage) {
        self.storage = storage
    }
    
    func serverConfiguration() -> ServerConfiguration {
        ServerConfiguration.init(
            serverUrl: storage.string(forKey: Constants.serverUrlKey),
            authorizationType: {
                if storage.string(forKey: Constants.authorizationTypeKey) == Constants.AuthorizationType.none {
                    return .none
                } else if storage.string(forKey: Constants.authorizationTypeKey) == Constants.AuthorizationType.httpHeader,
                       let header = storage.string(forKey: Constants.authorizationValueKey) {
                    return .httpHeader(header)
                } else {
                    return .none
                }
            }()
        )
    }
    
    func save(serverConfiguration: ServerConfiguration) {
        storage.set(serverConfiguration.serverUrl, forKey: Constants.serverUrlKey)
        switch serverConfiguration.authorizationType {
        case .none:
            storage.set(Constants.AuthorizationType.none, forKey: Constants.authorizationTypeKey)
            storage.set(nil as String?, forKey: Constants.authorizationValueKey)
        case .httpHeader(let header):
            storage.set(Constants.AuthorizationType.httpHeader, forKey: Constants.authorizationTypeKey)
            storage.set(header, forKey: Constants.authorizationValueKey)
        }
    }
}
