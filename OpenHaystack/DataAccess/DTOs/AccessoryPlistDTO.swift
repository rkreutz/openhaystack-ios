//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import CoreLocation
import CryptoKit
import Foundation
import Security
import SwiftUI

struct AccessoryPlistDTO: Codable {

    var name: String
    let id: Int
    let privateKey: Data
    let symmetricKey: Data
    var usesDerivation: Bool
    var oldestRelevantSymmetricKey: Data
    var lastDerivationTimestamp: Date
    var updateInterval: TimeInterval
    var locations: [FindMyLocationReport]?
    var color: Color
    var icon: String
    var lastLocation: CLLocation?
    var locationTimestamp: Date?
    var isDeployed: Bool {
        didSet(wasDeployed) {
            // Reset active status if deployed
            if !wasDeployed && isDeployed {
                self.isActive = false
                self.usesDerivation = false
            } else if wasDeployed && !isDeployed {
                self.usesDerivation = false
                self.updateInterval = TimeInterval(60 * 60 * 24)
            }
        }
    }
    /// Whether the accessory is correctly advertising.
    var isActive: Bool = false
    /// Whether this accessory is currently nearby.
    var isNearby: Bool = false {
        didSet {
            if isNearby {
                self.isActive = true
            }
        }
    }
    var lastAdvertisement: Date?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.id = try container.decode(Int.self, forKey: .id)
        self.privateKey = try container.decode(Data.self, forKey: .privateKey)
        let symmetricKey = (try? container.decode(Data.self, forKey: .symmetricKey)) ?? SymmetricKey(size: .bits256).withUnsafeBytes { return Data($0) }
        self.symmetricKey = symmetricKey
        self.usesDerivation = (try? container.decode(Bool.self, forKey: .usesDerivation)) ?? false
        self.oldestRelevantSymmetricKey = (try? container.decode(Data.self, forKey: .oldestRelevantSymmetricKey)) ?? symmetricKey
        self.lastDerivationTimestamp = (try? container.decode(Date.self, forKey: .lastDerivationTimestamp)) ?? Date()
        self.updateInterval = (try? container.decode(TimeInterval.self, forKey: .updateInterval)) ?? TimeInterval(60 * 60 * 24)
        self.icon = (try? container.decode(String.self, forKey: .icon)) ?? ""
        self.isDeployed = (try? container.decode(Bool.self, forKey: .isDeployed)) ?? false
        self.isActive = (try? container.decode(Bool.self, forKey: .isActive)) ?? false

        if var colorComponents = try? container.decode([CGFloat].self, forKey: .colorComponents),
            let spaceName = try? container.decode(String.self, forKey: .colorSpaceName),
            let cgColor = CGColor(colorSpace: CGColorSpace(name: spaceName as CFString)!, components: &colorComponents)
        {
            self.color = Color(cgColor)
        } else {
            self.color = Color.white
        }

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.privateKey, forKey: .privateKey)
        try container.encode(self.symmetricKey, forKey: .symmetricKey)
        try container.encode(self.usesDerivation, forKey: .usesDerivation)
        try container.encode(self.oldestRelevantSymmetricKey, forKey: .oldestRelevantSymmetricKey)
        try container.encode(self.lastDerivationTimestamp, forKey: .lastDerivationTimestamp)
        try container.encode(self.updateInterval, forKey: .updateInterval)
        try container.encode(self.icon, forKey: .icon)
        try container.encode(self.isDeployed, forKey: .isDeployed)
        try container.encode(self.isActive, forKey: .isActive)

        if let colorComponents = self.color.cgColor?.components,
            let colorSpace = self.color.cgColor?.colorSpace?.name
        {
            try container.encode(colorComponents, forKey: .colorComponents)
            try container.encode(colorSpace as String, forKey: .colorSpaceName)
        }

    }

    func getAdvertisementKey() throws -> Data {
        guard var publicKey = BoringSSL.derivePublicKey(fromPrivateKey: self.privateKey) else {
            throw KeyError.keyDerivationFailed
        }
        // Drop the first byte to just have the 28 bytes version
        publicKey = publicKey.dropFirst()
        assert(publicKey.count == 28)
        guard publicKey.count == 28 else { throw KeyError.keyDerivationFailed }

        return publicKey
    }

    enum CodingKeys: String, CodingKey {
        case name
        case id
        case privateKey
        case usesDerivation
        case symmetricKey
        case oldestRelevantSymmetricKey
        case lastDerivationTimestamp
        case updateInterval
        case colorComponents
        case colorSpaceName
        case icon
        case isDeployed
        case isActive
    }
}

extension AccessoryPlistDTO {
    static func load(from plistUrl: URL) throws -> [AccessoryPlistDTO] {
        try PropertyListDecoder().decode([AccessoryPlistDTO].self, from: Data(contentsOf: plistUrl))
    }
}

enum KeyError: Error {
    case keyDerivationFailed
}
