//
//  ServerConfiguration.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 20/03/24.
//

import Foundation

struct ServerConfiguration {
    enum AuthorizationType {
        case none
        case httpHeader(String)
    }
    
    var serverUrl: String?
    var authorizationType: AuthorizationType
}

extension ServerConfiguration {
    private static var repository: ServerConfigurationRepository {
        ServerConfigurationRepository(storage: UserDefaults.standard)
    }
    
    static func current() -> ServerConfiguration {
        Self.repository.serverConfiguration()
    }
    
    func saveAsCurrent() {
        Self.repository.save(serverConfiguration: self)
    }
}
