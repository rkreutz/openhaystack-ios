//
//  Accessory.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 15/03/24.
//

import Foundation
import CoreLocation

struct Accessory: Identifiable {
    enum Status: Equatable {
        case connected
        case active
        case inactive
    }
    
    struct Color: Equatable {
        var red: Double
        var green: Double
        var blue: Double
        var alpha: Double
    }
    
    var id: String
    var name: String
    var imageName: String
    var color: Color
    var locations: [Location]
    var status: Status
    
    var latestLocation: Location? {
        locations.first
    }
}

extension Accessory {
    fileprivate static var repository: AccessoriesRepository {
        AccessoriesRepository(
            storage: UserDefaults.standard,
            protectedStorage: KeychainStorage(),
            httpClient: URLSessionHTTPClient(session: .shared),
            serverConfigurationRepository: ServerConfigurationRepository(storage: UserDefaults.standard), 
            reportsConfigurationRepository: ReportsConfigurationRepository(storage: UserDefaults.standard)
        )
    }
    
    static func all() -> [Accessory] {
        repository.fetchAccessories()
    }
}

extension Array where Element == Accessory {
    func save() {
        Accessory.repository.save(accessories: self)
    }
}

extension Accessory {
    enum Constants {
        static let icons = [
            "creditcard.fill", 
            "briefcase.fill",
            "case.fill",
            "latch.2.case.fill",
            "key.fill",
            "mappin",
            "globe",
            "crown.fill",
            "gift.fill", 
            "car.fill",
            "bicycle",
            "figure.walk",
            "heart.fill", 
            "hare.fill",
            "tortoise.fill",
            "eye.fill",
        ]
        
        static let colors: [Accessory.Color] = [
            .init(red: 1.0, green: 0.25, blue: 0.25, alpha: 1.0),
            .init(red: 1.0, green: 0.7000000000000001, blue: 0.25, alpha: 1.0),
            .init(red: 0.8499999999999999, green: 1.0, blue: 0.25, alpha: 1.0),
            .init(red: 0.40000000000000013, green: 1.0, blue: 0.25, alpha: 1.0),
            .init(red: 0.25, green: 1.0, blue: 0.5500000000000003, alpha: 1.0),
            .init(red: 0.25, green: 1.0, blue: 1.0, alpha: 1.0),
            .init(red: 0.25, green: 0.5500000000000003, blue: 1.0, alpha: 1.0),
            .init(red: 0.39999999999999947, green: 0.25, blue: 1.0, alpha: 1.0),
            .init(red: 0.8500000000000005, green: 0.25, blue: 1.0, alpha: 1.0),
            .init(red: 1.0, green: 0.25, blue: 0.6999999999999997, alpha: 1.0),
            .init(red: 1, green: 1, blue: 1, alpha: 1),
            .init(red: 0, green: 0, blue: 0, alpha: 1)
        ]
    }
}

extension String {
    static func randomAccessoryName() -> String {
        let wordsFile = Bundle.main.url(forResource: "words", withExtension: "txt").unsafelyUnwrapped
        let words = try! String(contentsOf: wordsFile).components(separatedBy: .newlines)
        return words.randomElement().unsafelyUnwrapped.localizedCapitalized
    }
    
    static func randomAccessoryIcon() -> String {
        Accessory.Constants.icons.randomElement().unsafelyUnwrapped
    }
}

extension Accessory.Color {
    static func random() -> Accessory.Color {
        Accessory.Constants.colors.randomElement().unsafelyUnwrapped
    }
}
