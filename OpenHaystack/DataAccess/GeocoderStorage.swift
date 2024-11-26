//
//  GeocoderStorage.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 25/11/24.
//

import Foundation
import CoreLocation

protocol GeocoderStorage {
    func reverseGeocodeLocation(_ location: CLLocation, withCacheFactor cacheFactor: Double) -> String?
    func save(address: String, for location: CLLocation, cacheFactor: Double)
}

struct GeocoderStorageImpl: GeocoderStorage {
    
    private let cache: MemoryCache<String, String>
    private static let queue = DispatchQueue(label: "com.rkreutz.GeocoderStorageImpl")
    
    init() {
        guard 
            let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appending(path: "\(Self.self)"),
            let savedData = try? Data(contentsOf: path),
            let dictionary = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: savedData)
        else {
            self.cache = .init()
            return
        }
        
        self.cache = .init(dictionary)
    }
    
    func reverseGeocodeLocation(_ location: CLLocation, withCacheFactor cacheFactor: Double) -> String? {
        return cache[generateKey(for: location, withFactor: cacheFactor)]
    }
    
    func save(address: String, for location: CLLocation, cacheFactor: Double) {
        cache[generateKey(for: location, withFactor: cacheFactor)] = address
        GeocoderStorageImpl.queue.async {
            guard
                let savedData = try? NSKeyedArchiver.archivedData(withRootObject: cache.asNSDictionary(), requiringSecureCoding: false),
                let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appending(path: "\(Self.self)")
            else { return }
            try? savedData.write(to: path, options: .noFileProtection)
        }
    }
    
    private func generateKey(for location: CLLocation, withFactor factor: Double) -> String {
        let factor = round(factor)
        let latitudeGrid = factor / 110_950.580_549_279_5
        let longitudeGrid = factor / (111_317.099_692_198_34 * cos(location.coordinate.latitude * .pi / 180))
        
        let latitudeKey = Int(round(location.coordinate.latitude / latitudeGrid))
        let longitudeKey = Int(round(location.coordinate.longitude / longitudeGrid))
        
        return "\(Int(factor))_\(latitudeKey)_\(longitudeKey)"
    }
}

private extension MemoryCache where Key: LosslessStringConvertible {
    func asNSDictionary() -> NSDictionary {
        NSDictionary.init(objects: values.map { $0 }, forKeys: keys.map { NSString(string: $0.description) })
    }
    
    convenience init(_ dictionary: NSDictionary) {
        self.init(
            uniqueKeysWithValues: dictionary.compactMap { key, value in
                guard
                    let rawKey = key as? String,
                    let key = Key(rawKey),
                    let value = value as? Value
                else { return nil }
                return (key, value)
            }
        )
    }
}
