//
//  AccessoriesManager.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 20/03/24.
//

import Foundation
import Combine

protocol AccessoriesProvider {
    func accessories() -> AnyPublisher<[Accessory], Never>
}

protocol AccessoriesFetcher {
    func fetchAccessories(_ completion: @escaping (Result<[Accessory], Error>) -> Void)
    func isFetchingAccessories() -> AnyPublisher<Bool, Never>
}

protocol AccessoryModifier {
    func update(accessory: Accessory)
    func deleteAccessory(with id: String)
}

protocol AccessoryCreator {
    func createNewAccessory()
}

protocol AccessoriesImporter {
    func importAccessories(from plistUrl: URL)
}

final class AccessoriesManager: AccessoriesProvider, AccessoriesFetcher, AccessoryModifier, AccessoryCreator, AccessoriesImporter {
    @Published private var storedAccessories: [Accessory] = Accessory.all()
    
    private let repository: AccessoriesRepository
    private let scanner: BluetoothScanner
    private var cancellabels: Set<AnyCancellable> = []
    private var fetchPublisher: AnyPublisher<[Accessory], Error>?
    private let accessQueue = DispatchQueue(label: "serialQueue")
    private let isFetchingAccessoriesSubject = CurrentValueSubject<Bool, Never>(false)
    init(repository: AccessoriesRepository, scanner: BluetoothScanner) {
        self.repository = repository
        self.scanner = scanner
        
        scanner.advertisement
            .receive(on: accessQueue)
            .sink(receiveValue: { [weak self] advertisement in
                guard let index = self?.storedAccessories.firstIndex(where: { advertisement.isFrom($0) }) else { return }
                self?.storedAccessories[index].status = .connected
            })
            .store(in: &cancellabels)
    }
    
    func accessories() -> AnyPublisher<[Accessory], Never> {
        $storedAccessories.eraseToAnyPublisher()
    }
    
    func fetchAccessories(_ completion: @escaping (Result<[Accessory], Error>) -> Void) {
        accessQueue.sync {
            if let fetchPublisher {
                return fetchPublisher
            } else {
                self.fetchPublisher = repository.fetchAccessoriesReportedLocations()
                    .last()
                    .share()
                    .handleEvents(
                        receiveSubscription: { [weak self] _ in
                            self?.isFetchingAccessoriesSubject.send(true)
                        },
                        receiveCompletion: { [weak self] _ in
                            self?.accessQueue.async {
                                self?.fetchPublisher = nil
                                self?.isFetchingAccessoriesSubject.send(false)
                            }
                        }
                    )
                    .eraseToAnyPublisher()

                return self.fetchPublisher.unsafelyUnwrapped
            }
        }
        .sink(
            receiveCompletion: {
                guard case .failure(let error) = $0 else { return }
                completion(.failure(error))
            },
            receiveValue: { [weak self] accessories in
                self?.accessQueue.async {
                    self?.storedAccessories = accessories
                    completion(.success(accessories))
                }
            }
        )
        .store(in: &cancellabels)
    }
    
    func isFetchingAccessories() -> AnyPublisher<Bool, Never> {
        isFetchingAccessoriesSubject.eraseToAnyPublisher()
    }
    
    func update(accessory: Accessory) {
        accessQueue.async {
            do {
                try self.repository.update(accessory: accessory)
                guard let index = self.storedAccessories.firstIndex(where: { $0.id == accessory.id }) else { return }
                var updatedAccessory = self.storedAccessories[index]
                updatedAccessory.name = accessory.name
                updatedAccessory.color = accessory.color
                updatedAccessory.imageName = accessory.imageName
                self.storedAccessories[index] = updatedAccessory
            } catch {}
        }
    }
    
    func deleteAccessory(with id: String) {
        accessQueue.async {
            self.repository.removeAccessory(with: id)
            self.storedAccessories.removeAll(where: { $0.id == id })
        }
    }
    
    func createNewAccessory() {
        accessQueue.async {
            guard let accessory = self.repository.createAccessory(name: .randomAccessoryName(), imageName: .randomAccessoryIcon(), color: .random()) else { return }
            self.storedAccessories.append(accessory)
        }
    }
    
    func importAccessories(from plistUrl: URL) {
        accessQueue.async {
            guard let accessories = try? self.repository.importAccessories(from: plistUrl) else { return }
            self.storedAccessories.append(contentsOf: accessories)
        }
    }
}

private extension Advertisement {
    func isFrom(_ accessory: Accessory) -> Bool {
        guard let accessoryAdvertisementKey = Data(base64Encoded: accessory.id) else { return false }
        return Data(accessoryAdvertisementKey.suffix(Advertisement.publicKeyPayloadLength)) == publicKeyPayload
    }
}
