//
//  GeocodeRepository.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 08/11/24.
//

import Foundation
import CoreLocation
import Combine

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
    
    // TODO: add disk cache of reverse geocode locations to the nearest 5/10 meters
    func reverseGeocodeLocation(_ location: CLLocation) -> AnyPublisher<CLPlacemark, Swift.Error> {
        remoteReverseGeocodeLocation(location)
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
