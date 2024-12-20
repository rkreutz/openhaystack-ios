//
//  ReportsConfigurationRepository.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 22/03/24.
//

import Foundation

final class ReportsConfigurationRepository {
    
    enum Constants {
        static let numberOfDaysKey = "number_of_days"
        static let cacheFactorKey = "cache_factor_key"
    }
    
    private let storage: KeyValueStorage
    init(storage: KeyValueStorage) {
        self.storage = storage
    }
    
    func reportsConfiguration() -> ReportsConfiguration {
        ReportsConfiguration(
            numberOfDays: storage.integer(forKey: Constants.numberOfDaysKey) ?? 7,
            cacheFactor: storage.value(forKey: Constants.cacheFactorKey) ?? 10
        )
    }
    
    func save(reportsConfiguration: ReportsConfiguration) {
        storage.set(reportsConfiguration.numberOfDays, forKey: Constants.numberOfDaysKey)
    }
}
