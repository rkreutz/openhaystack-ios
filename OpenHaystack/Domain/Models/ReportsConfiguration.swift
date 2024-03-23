//
//  ReportsConfiguration.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 22/03/24.
//

import Foundation

struct ReportsConfiguration {
    var numberOfDays: Int
}

extension ReportsConfiguration {
    private static var repository: ReportsConfigurationRepository {
        ReportsConfigurationRepository(storage: UserDefaults.standard)
    }
    
    static func current() -> ReportsConfiguration {
        Self.repository.reportsConfiguration()
    }
    
    func saveAsCurrent() {
        Self.repository.save(reportsConfiguration: self)
    }
}
