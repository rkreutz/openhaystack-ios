//
//  Location.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 15/03/24.
//

import Foundation

struct Location: Equatable, Identifiable {
    var id: String { "\(timestamp)\(latitude)\(longitude)" }
    var latitude: Double
    var longitude: Double
    var address: String?
    var timestamp: Date
    var accuracy: UInt8
    var confidence: UInt8?
}
