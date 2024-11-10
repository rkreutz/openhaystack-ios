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
    
    // TODO: Backpressure this to throtle 50 requests per minute
    func reverseGeocodeLocation(_ location: CLLocation) -> AnyPublisher<CLPlacemark, Swift.Error> {
        Future { fulfill in self.remoteReverseGeocodeLocation(location) { fulfill($0) } }
            .delay(for: .init(integerLiteral: Int.random(in: 0 ..< 10)), scheduler: DispatchQueue.main)
            .catch { error in
                switch error {
                case let error as CLError where error.code == CLError.Code.network:
                    print("possibly rate limited")
                    return Just(Void())
                        .delay(for: 60, scheduler: DispatchQueue.main)
                        .flatMap { _ in self.reverseGeocodeLocation(location) }
                        .eraseToAnyPublisher()
                default:
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func remoteReverseGeocodeLocation(_ location: CLLocation, completion: @escaping (Result<CLPlacemark, Swift.Error>) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                completion(.success(placemark))
            } else {
                completion(.failure(error ?? Error.noPlacemark))
            }
        }
    }
}
