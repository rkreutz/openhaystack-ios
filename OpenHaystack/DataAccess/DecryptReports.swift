//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import CryptoKit
import Foundation

enum DecryptReports {
    
    static func decrypt(
        results: FindMyReportResults,
        with keys: [(keyId: SHA256Digest, privateKey: Data)]
    ) throws -> [SHA256Digest: [FindMyLocationReport]] {
        let accessQueue = DispatchQueue(label: "threadSafeAccess", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem)
        let encryptedResults: [SHA256Digest: [FindMyReport]] = Dictionary(
            grouping: results.results,
            by: { element in
                keys.first(where: { Data($0.keyId).base64EncodedString() == element.id })?.keyId ?? SHA256().finalize()
            }
        )
        var decryptedResults: [SHA256Digest: [FindMyLocationReport]] = Dictionary(
            uniqueKeysWithValues: encryptedResults.reduce(into: [(SHA256Digest, [FindMyLocationReport])]()) { partialResult, element in
                partialResult += [(element.key, [FindMyLocationReport](repeating: .init(lat: 0, lng: 0, acc: 0, dP: .init(), t: .init(), c: 0), count: element.value.count))]
            }
        )
        
        for (keyId, privateKey) in keys {
            DispatchQueue.concurrentPerform(iterations: encryptedResults[keyId]?.count ?? 0) { reportIndex in
                guard  let report = encryptedResults[keyId]?[reportIndex] else { return }
                
                do {
                    let locationReport = try DecryptReports.decrypt(report: report, with: privateKey)
                    accessQueue.async(flags: .barrier) {
                        decryptedResults[keyId]?[reportIndex] = locationReport
                    }
                } catch {
                    return
                }
            }
        }
        
        return accessQueue.sync { decryptedResults }
    }

    /// Decrypt a find my report with the according key.
    ///
    /// - Parameters:
    ///   - report: An encrypted FindMy Report
    ///   - key: A FindMyKey
    /// - Throws: Errors if the decryption fails
    /// - Returns: An decrypted location report
    static func decrypt(report: FindMyReport, with key: Data) throws -> FindMyLocationReport {
        let payloadData = report.payload
        let keyData = key

        let privateKey = keyData
        let ephemeralKey = payloadData.subdata(in: 5..<62)

        guard let sharedKey = BoringSSL.deriveSharedKey(fromPrivateKey: privateKey, andEphemeralKey: ephemeralKey) else {
            throw FindMyError.decryptionError(description: "Failed generating shared key")
        }

        let derivedKey = self.kdf(fromSharedSecret: sharedKey, andEphemeralKey: ephemeralKey)

        print("Derived key \(derivedKey.base64EncodedString())")

        let encData = payloadData.subdata(in: 62..<72)
        let tag = payloadData.subdata(in: 72..<payloadData.endIndex)

        let decryptedContent = try self.decryptPayload(payload: encData, symmetricKey: derivedKey, tag: tag)
        let locationReport = self.decode(content: decryptedContent, report: report)
        print(locationReport)
        return locationReport
    }

    /// Decrypt the payload.
    ///
    /// - Parameters:
    ///   - payload: Encrypted payload part
    ///   - symmetricKey: Symmetric key
    ///   - tag: AES GCM tag
    /// - Throws: AES GCM error
    /// - Returns: Decrypted error
    static func decryptPayload(payload: Data, symmetricKey: Data, tag: Data) throws -> Data {
        let decryptionKey = symmetricKey.subdata(in: 0..<16)
        let iv = symmetricKey.subdata(in: 16..<symmetricKey.endIndex)

        print("Decryption Key \(decryptionKey.base64EncodedString())")
        print("IV \(iv.base64EncodedString())")

        let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: iv), ciphertext: payload, tag: tag)
        let symKey = SymmetricKey(data: decryptionKey)
        let decrypted = try AES.GCM.open(sealedBox, using: symKey)

        return decrypted
    }

    static func decode(content: Data, report: FindMyReport) -> FindMyLocationReport {
        var longitude: Int32 = 0
        _ = withUnsafeMutableBytes(of: &longitude, { content.subdata(in: 4..<8).copyBytes(to: $0) })
        longitude = Int32(bigEndian: longitude)

        var latitude: Int32 = 0
        _ = withUnsafeMutableBytes(of: &latitude, { content.subdata(in: 0..<4).copyBytes(to: $0) })
        latitude = Int32(bigEndian: latitude)

        var accuracy: UInt8 = 0
        _ = withUnsafeMutableBytes(of: &accuracy, { content.subdata(in: 8..<9).copyBytes(to: $0) })

        let latitudeDec = Double(latitude) / 10000000.0
        let longitudeDec = Double(longitude) / 10000000.0

        return FindMyLocationReport(lat: latitudeDec, lng: longitudeDec, acc: accuracy, dP: report.datePublished, t: report.timestamp, c: report.confidence)
    }

    static func kdf(fromSharedSecret secret: Data, andEphemeralKey ephKey: Data) -> Data {

        var shaDigest = SHA256()
        shaDigest.update(data: secret)
        var counter: Int32 = 1
        let counterData = Data(Data(bytes: &counter, count: MemoryLayout.size(ofValue: counter)).reversed())
        shaDigest.update(data: counterData)
        shaDigest.update(data: ephKey)

        let derivedKey = shaDigest.finalize()

        return Data(derivedKey)
    }
}

//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//
//func decryptReports(completion: () -> Void) {
//    print("Decrypting reports")
//
//    // Iterate over all devices
//    for deviceIdx in 0..<devices.count {
//        devices[deviceIdx].decryptedReports = []
//        let device = devices[deviceIdx]
//
//        // Map the keys in a dictionary for faster access
//        guard let reports = device.reports else { continue }
//        let keyMap = device.keys.reduce(into: [String: FindMyKey](), { $0[$1.hashedKey.base64EncodedString()] = $1 })
//
//        let accessQueue = DispatchQueue(label: "threadSafeAccess", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
//        var decryptedReports = [FindMyLocationReport](repeating: FindMyLocationReport(lat: 0, lng: 0, acc: 0, dP: Date(), t: Date(), c: 0), count: reports.count)
//        DispatchQueue.concurrentPerform(iterations: reports.count) { (reportIdx) in
//            let report = reports[reportIdx]
//            guard let key = keyMap[report.id] else { return }
//            do {
//                // Decrypt the report
//                let locationReport = try DecryptReports.decrypt(report: report, with: key)
//                accessQueue.async(flags: .barrier) {
//                    decryptedReports[reportIdx] = locationReport
//                }
//            } catch {
//                return
//            }
//        }
//
//        accessQueue.sync {
//            devices[deviceIdx].decryptedReports = decryptedReports
//        }
//    }
//
//    completion()
//
//}
