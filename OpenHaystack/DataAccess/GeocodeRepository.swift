//
//  GeocodeRepository.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 08/11/24.
//

import Foundation
import CoreLocation
import Combine
import Contacts

final class GeocodeRepository {
    
    enum Error: Swift.Error {
        case noPlacemark
    }
    
    private let rateLimiter = RateLimiter<String>(
        config: .init(
            concurrentLimit: 1,
            intervalLimit: 50,
            interval: .seconds(60)
        )
    )
    private let configurationRepository = ReportsConfigurationRepository(storage: UserDefaults.standard)
    private let storage: GeocoderStorage = GeocoderStorageImpl()
    
    func reverseGeocodeLocation(_ location: CLLocation) -> AnyPublisher<String, Swift.Error> {
        Deferred {
            if let placemark = self.storage.reverseGeocodeLocation(location, withCacheFactor: self.configurationRepository.reportsConfiguration().cacheFactor) {
                return Just(placemark)
                    .setFailureType(to: Swift.Error.self)
                    .eraseToAnyPublisher()
            } else {
                return self.remoteReverseGeocodeLocation(location)
                    .compactMap { $0.address() }
                    .handleEvents(receiveOutput: { self.storage.save(address: $0, for: location, cacheFactor: self.configurationRepository.reportsConfiguration().cacheFactor) })
                    .eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func remoteReverseGeocodeLocation(_ location: CLLocation) -> AnyPublisher<CLPlacemark, Swift.Error> {
        rateLimiter.throttle(
            withKey: "CLGeocoder.reverseGeocodeLocation",
            publisher: Future { fulfill in
                CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                    if let placemark = placemarks?.first {
                        fulfill(.success(placemark))
                    } else {
                        fulfill(.failure(error ?? Error.noPlacemark))
                    }
                }
            }
        )
    }
}

private extension CLPlacemark {
    static let formatter = CNPostalAddressFormatter()
    
    func address() -> String? {
        if let address = postalAddress.flatMap(CLPlacemark.formatter.string(from: )) {
            return address.replacingOccurrences(of: "\n", with: ", ")
        } else {
            return [name, thoroughfare, subLocality, locality]
                .compactMap { $0 }
                .joined(separator: ", ")
        }
    }
}
