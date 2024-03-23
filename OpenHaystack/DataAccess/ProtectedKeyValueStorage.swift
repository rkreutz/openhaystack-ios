//
//  ProtectedKeyValueStorage.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 20/03/24.
//

import Foundation

protocol ProtectedKeyValueStorage {
    func set(_ data: Data?, forKey key: String)
    func data(forKey key: String) -> Data?
}
