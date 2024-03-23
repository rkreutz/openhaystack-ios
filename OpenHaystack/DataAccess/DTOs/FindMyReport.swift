//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

struct FindMyReportResults: Decodable {
    let results: [FindMyReport]
}

struct FindMyReport: Decodable {
    let datePublished: Date
    let payload: Data
    let id: String
    let statusCode: Int

    let confidence: UInt8
    let timestamp: Date

    enum CodingKeys: CodingKey {
        case datePublished
        case payload
        case id
        case statusCode
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let dateTimestamp = try values.decode(Double.self, forKey: .datePublished)
        // Convert from milis to time interval
        let dP = Date(timeIntervalSince1970: dateTimestamp / 1000)
        let df = DateFormatter()
        df.dateFormat = "YYYY-MM-dd"

        if dP < df.date(from: "2020-01-01")! {
            self.datePublished = Date(timeIntervalSince1970: dateTimestamp)
        } else {
            self.datePublished = dP
        }

        self.statusCode = try values.decode(Int.self, forKey: .statusCode)
        let payloadBase64 = try values.decode(String.self, forKey: .payload)

        guard let payload = Data(base64Encoded: payloadBase64) else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.payload, in: values, debugDescription: "")
        }
        self.payload = payload

        var timestampData = payload.subdata(in: 0..<4)
        let timestamp: Int32 = withUnsafeBytes(of: &timestampData) { (pointer) -> Int32 in
            // Convert the endianness
            pointer.load(as: Int32.self).bigEndian
        }

        // It's a cocoa time stamp (counting from 2001)
        self.timestamp = Date(timeIntervalSinceReferenceDate: TimeInterval(timestamp))
        self.confidence = payload[4]

        self.id = try values.decode(String.self, forKey: .id)
    }
}

struct FindMyLocationReport: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: UInt8
    let datePublished: Date
    let timestamp: Date?
    let confidence: UInt8?

    init(lat: Double, lng: Double, acc: UInt8, dP: Date, t: Date, c: UInt8) {
        self.latitude = lat
        self.longitude = lng
        self.accuracy = acc
        self.datePublished = dP
        self.timestamp = t
        self.confidence = c
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.latitude = try values.decode(Double.self, forKey: .latitude)
        self.longitude = try values.decode(Double.self, forKey: .longitude)

        do {
            let uAcc = try values.decode(UInt8.self, forKey: .accuracy)
            self.accuracy = uAcc
        } catch {
            let iAcc = try values.decode(Int8.self, forKey: .accuracy)
            self.accuracy = UInt8(bitPattern: iAcc)
        }

        self.datePublished = try values.decode(Date.self, forKey: .datePublished)
        self.timestamp = try? values.decode(Date.self, forKey: .timestamp)
        self.confidence = try? values.decode(UInt8.self, forKey: .confidence)
    }

}

enum FindMyError: Error {
    case decryptionError(description: String)
}
