//
//  BluetoothScanner.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 22/03/24.
//

import UIKit
import CoreBluetooth
import Combine

final class BluetoothScanner {

    var advertisement: PassthroughSubject<Advertisement, Never> { delegate.advertisement }
    
    private let delegate: Delegate
    private let scanner: CBCentralManager
    private var cancellables: Set<AnyCancellable> = []

    init() {
        delegate = .init()
        scanner = CBCentralManager(delegate: delegate, queue: DispatchQueue.global())
        
        // Bluetooth scanning BLE beacons from Find My network on iOS
        // doesn't yield any results, apparently only Macs can handle
        // these kind of beacons.
        if ProcessInfo.processInfo.isiOSAppOnMac {
            delegate.state
                .sink(receiveValue: { [scanner] in
                    guard $0 == .poweredOn else { return }
                    scanner.scanForPeripherals(withServices: nil)
                })
                .store(in: &cancellables)
            
            NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
                .sink(receiveValue: { [scanner] _ in scanner.stopScan() })
                .store(in: &cancellables)
            
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
                .filter { [delegate] _ in delegate.state.value == .poweredOn }
                .sink(receiveValue: { [scanner] _ in scanner.scanForPeripherals(withServices: nil) })
                .store(in: &cancellables)
        }
    }
    
    private final class Delegate: NSObject, CBCentralManagerDelegate {
        
        let state = CurrentValueSubject<CBManagerState, Never>(.unknown)
        let advertisement = PassthroughSubject<Advertisement, Never>()

        public func centralManagerDidUpdateState(_ central: CBCentralManager) {
            state.send(central.state)
        }

        public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
            guard let adv = Advertisement(fromAdvertisementData: advertisementData) else { return }
            advertisement.send(adv)
        }
    }
}
