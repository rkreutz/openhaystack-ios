//
//  AccessoriesRepository.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 20/03/24.
//

import Foundation
import CoreLocation
import Combine
import CryptoKit
import OSLog
import struct SwiftUI.Color

final class AccessoriesRepository {
    
    enum Error: Swift.Error {
        case invalidServerUrl
        case accessoryNotFound
    }
    
    enum Constants {
        static let accessoriesKey = "accessories"
    }
    
    private let storage: KeyValueStorage
    private let protectedStorage: ProtectedKeyValueStorage
    private let httpClient: HTTPClient
    private let serverConfigurationRepository: ServerConfigurationRepository
    private let reportsConfigurationRepository: ReportsConfigurationRepository
    init(
        storage: KeyValueStorage,
        protectedStorage: ProtectedKeyValueStorage,
        httpClient: HTTPClient,
        serverConfigurationRepository: ServerConfigurationRepository,
        reportsConfigurationRepository: ReportsConfigurationRepository
    ) {
        self.storage = storage
        self.protectedStorage = protectedStorage
        self.httpClient = httpClient
        self.serverConfigurationRepository = serverConfigurationRepository
        self.reportsConfigurationRepository = reportsConfigurationRepository
    }
    
    func createAccessory(name: String, imageName: String, color: Accessory.Color) -> Accessory? {
        guard
            let privateKey = BoringSSL.generateNewPrivateKey(),
            let publicKey = BoringSSL.derivePublicKey(fromPrivateKey: privateKey)
        else {
            os_log(.error, log: .default, "Failed to create EC pair for new accessory")
            return nil
        }
        
        let accessory = Accessory(
            id: publicKey[1 ..< 29].base64EncodedString(),
            name: name,
            imageName: imageName,
            color: color,
            locations: [],
            status: .inactive
        )
        
        save(accessories: fetchAccessories() + [accessory])
        protectedStorage.set(privateKey, forKey: accessory.id)
        
        return accessory
    }
    
    func importAccessories(from plistUrl: URL) throws -> [Accessory] {
        let dtos = try AccessoryPlistDTO.load(from: plistUrl)
            .filter { dto in
                assert(!dto.usesDerivation, "This app doesn't support accessories with key derivation yet.")
                return !dto.usesDerivation
            }
        let accessories = try dtos.map(Accessory.init(from:))
        
        save(accessories: fetchAccessories() + accessories)
        for (dto, accessory) in zip(dtos, accessories) {
            protectedStorage.set(dto.privateKey, forKey: accessory.id)
        }
        
        return accessories
    }
    
    func fetchAccessories() -> [Accessory] {
        if let accessoriesDto: [AccessoryLocalDTO] = storage.value(forKey: Constants.accessoriesKey) {
            return accessoriesDto.map(Accessory.init(from:))
        } else {
            return []
        }
    }
    
    func update(accessory: Accessory) throws {
        var accessories = fetchAccessories()
        guard let index = accessories.firstIndex(where: { $0.id == accessory.id }) else { throw Error.accessoryNotFound }
        accessories[index] = accessory
        save(accessories: accessories)
    }
    
    func removeAccessory(with id: String) {
        var accessories = fetchAccessories()
        accessories.removeAll(where: { $0.id == id })
        save(accessories: accessories)
        protectedStorage.set(nil, forKey: id)
    }
    
    func save(accessories: [Accessory]) {
        let dtos = accessories.map(AccessoryLocalDTO.init(from:))
        storage.set(value: dtos, forKey: Constants.accessoriesKey)
    }
    
    func fetchAccessoriesReportedLocations() -> AnyPublisher<[Accessory], Swift.Error> {
        Deferred { Just(self.fetchAccessories()) }
            .flatMap(fetchRecordsFromRemote())
            .eraseToAnyPublisher()
    }
    
    private func fetchRecordsFromRemote() -> ([Accessory]) -> AnyPublisher<[Accessory], Swift.Error> {
        { accessories in
            Future<Data, Swift.Error> { fulfill in
                let serverConfiguration = self.serverConfigurationRepository.serverConfiguration()
                let reportsConfiguration = self.reportsConfigurationRepository.reportsConfiguration()
                guard
                    let serverUrl = serverConfiguration.serverUrl,
                    let url = URL(string: serverUrl)
                else {
                    return fulfill(.failure(Error.invalidServerUrl))
                }
                
                let hashedKeys = accessories.compactMap { accessory -> String? in
                    guard let data = Data(base64Encoded: accessory.id) else { return nil }
                    var hash = SHA256()
                    hash.update(data: data)
                    return Data(hash.finalize()).base64EncodedString()
                }
                
                var headers: [HTTPHeader: String] = [
                    .accept: "application/json",
                    .contentType: "application/json",
                ]
                
                if case let .httpHeader(string) = serverConfiguration.authorizationType {
                    headers[.authorization] = string
                }
                
                let body = """
                {
                    "search": [
                        {
                            "ids": [\(hashedKeys.map { "\"\($0)\"" }.joined(separator: ","))],
                            "startDate": "\(UInt((Date().timeIntervalSince1970 - Double(reportsConfiguration.numberOfDays) * 24 * 60 * 60) * 1000))",
                            "endDate": "\(UInt(Date().timeIntervalSince1970 * 1000))"
                        }
                    ]
                }
                """
                
                let request = HTTPRequest(
                    url: url,
                    method: .post,
                    body: body.data(using: .utf8) ?? Data(),
                    headers: headers
                )

                self.httpClient.request(request) { result in
                    switch result {
                    case .failure(let error):
                        fulfill(.failure(error))
                    case .success(let data):
                        fulfill(.success(data))
                    }
                }
            }
            .tryMap(self.decodeRecordsFromRemote(for: accessories))
            .flatMap(self.reverseGeocodeLocations())
            .eraseToAnyPublisher()
        }
    }
    
    private func decodeRecordsFromRemote(for accessories: [Accessory]) -> (Data) throws -> [Accessory] {
        { data in
            let reportsConfiguration = self.reportsConfigurationRepository.reportsConfiguration()
            let report = try JSONDecoder().decode(FindMyReportResults.self, from: data)
            
            let decryptedReports = try DecryptReports.decrypt(
                results: report,
                with: accessories.compactMap { accessory -> (SHA256Digest, Data)? in
                    guard
                        let keyId = Data(base64Encoded: accessory.id),
                        let privateKey = self.protectedStorage.data(forKey: accessory.id)
                    else { return nil }
                    var hash = SHA256()
                    hash.update(data: keyId)
                    let digest = hash.finalize()
                    return (digest, privateKey)
                }
            )
            
            return accessories.compactMap { accessory -> Accessory? in
                guard let keyId = Data(base64Encoded: accessory.id) else { return nil }
                let hash = { var sha256 = SHA256(); sha256.update(data: keyId); return sha256.finalize() }()
                var accessory = accessory
                
                accessory.locations = (decryptedReports[hash] ?? [])
                    .compactMap { report in
                        guard let report = report else { return nil }
                        return Location(
                            latitude: report.latitude,
                            longitude: report.longitude,
                            address: nil,
                            timestamp: report.timestamp ?? report.datePublished,
                            accuracy: report.accuracy,
                            confidence: report.confidence
                        )
                    }
                    .filter { $0.timestamp >= Date().addingTimeInterval(-TimeInterval(reportsConfiguration.numberOfDays) * 24 * 60 * 60) }
                    .sorted(by: { $0.timestamp > $1.timestamp })
                accessory.status = accessory.locations.isEmpty ? .inactive : .active
                
                return accessory
            }
        }
    }
    
    // TODO: Backpressure this to throtle 50 requests per minute
    private func reverseGeocodeLocations() -> ([Accessory]) -> AnyPublisher<[Accessory], Swift.Error> {
        { accessories in
            let dispatchGroup = DispatchGroup()
            let accessQueue = DispatchQueue(label: "syncQueue")
            return Future<[Accessory], Swift.Error> { fulfill in
                var accessories = accessories
                for (accessoryIndex, accessory) in accessories.enumerated() {
                    for (locationIndex, location) in accessory.locations.enumerated() {
                        dispatchGroup.enter()
                        CLGeocoder().reverseGeocodeLocation(CLLocation(from: location)) { placemarks, error in
                            defer { dispatchGroup.leave() }
                            guard let placemark = placemarks?.first else { return }
                            accessQueue.sync {
                                accessories[accessoryIndex].locations[locationIndex].address = placemark.name ?? placemark.thoroughfare ?? placemark.subLocality ?? placemark.locality
                            }
                        }
                    }
                }
                
                dispatchGroup.notify(queue: DispatchQueue.global()) {
                    fulfill(.success(accessories))
                }
            }
            .eraseToAnyPublisher()
        }
    }
}

private extension Accessory {
    init(from dto: AccessoryLocalDTO) {
        self.init(
            id: dto.id,
            name: dto.name,
            imageName: dto.imageName,
            color: Color(from: dto.color),
            locations: [],
            status: .inactive
        )
    }
    
    init(from dto: AccessoryPlistDTO) throws {
        self.init(
            id: try dto.getAdvertisementKey().base64EncodedString(),
            name: dto.name,
            imageName: dto.icon,
            color: Color(from: dto.color),
            locations: [],
            status: dto.isActive ? .active : .inactive
        )
    }
}

private extension AccessoryLocalDTO {
    init(from model: Accessory) {
        self.init(
            id: model.id,
            name: model.name,
            imageName: model.imageName,
            color: .init(from: model.color)
        )
    }
}

private extension Accessory.Color {
    init(from dto: AccessoryLocalDTO.Color) {
        self.init(
            red: dto.red,
            green: dto.green,
            blue: dto.blue,
            alpha: dto.alpha
        )
    }
    
    init(from color: Color) {
        guard 
            let components = color.resolve(in: .init()).cgColor.components,
            components.count == 4
        else {
            self = .random()
            return
        }

        self.init(
            red: components[0],
            green: components[1],
            blue: components[2],
            alpha: components[3]
        )
    }
}

private extension AccessoryLocalDTO.Color {
    init(from model: Accessory.Color) {
        self.init(
            red: model.red,
            green: model.green,
            blue: model.blue,
            alpha: model.alpha
        )
    }
}

private extension CLLocation {
    convenience init(from location: Location) {
        self.init(
            coordinate: .init(latitude: location.latitude, longitude: location.longitude),
            altitude: -1,
            horizontalAccuracy: -1,
            verticalAccuracy: -1,
            timestamp: location.timestamp
        )
    }
}
