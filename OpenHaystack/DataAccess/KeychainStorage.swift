//
//  KeychainStorage.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 21/03/24.
//

import Foundation

final class KeychainStorage: ProtectedKeyValueStorage {
    func set(_ data: Data?, forKey key: String) {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrLabel: "Private key for '\(key)'",
            kSecAttrService: key,
        ]
        
        guard let data = data else {
            query[kSecMatchLimit] = kSecMatchLimitOne
            SecItemDelete(query as CFDictionary)
            return
        }
        
        var attributes = query
        attributes[kSecValueData] = data

        let status = SecItemAdd(attributes as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        }
    }
    
    func data(forKey key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrLabel: "Private key for '\(key)'",
            kSecAttrService: key,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true,
        ]

        var result: CFTypeRef?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
}
