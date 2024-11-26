//
//  KeyValueStorage.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 20/03/24.
//

import Foundation

protocol KeyValueStorage {
    func set(_ string: String?, forKey key: String)
    func set(_ integer: Int?, forKey key: String)
    func set(_ double: Double?, forKey key: String)
    func set<T: Encodable>(value: T, forKey key: String)
    
    func string(forKey key: String) -> String?
    func integer(forKey key: String) -> Int?
    func double(forKey key: String) -> Double?
    func value<T: Decodable>(forKey key: String) -> T?
}

extension UserDefaults: KeyValueStorage {
    func set(_ string: String?, forKey key: String) {
        set(string as Any?, forKey: key)
    }
    
    func set(_ integer: Int?, forKey key: String) {
        set(integer as Any?, forKey: key)
    }
    
    func set(_ double: Double?, forKey key: String) {
        set(double as Any?, forKey: key)
    }
    
    func set<T>(value: T, forKey key: String) where T: Encodable {
        set(try? JSONEncoder().encode(value), forKey: key)
    }
    
    func integer(forKey key: String) -> Int? {
        object(forKey: key) as? Int
    }
    
    func double(forKey key: String) -> Double? {
        object(forKey: key) as? Double
    }
    
    func value<T>(forKey key: String) -> T? where T: Decodable {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
