//
//  AccessoriesMapRenderer.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 15/03/24.
//

import MapKit
import UIKit
import Combine

final class AccessoriesMapRenderer: NSObject, MapRenderer {
    enum Constants {
        static let mapPadding = UIEdgeInsets(top: 200, left: 100, bottom: 200, right: 100)
    }
    
    private let accessoriesProvider: AccessoriesProvider
    private let didSelectAccessory: PassthroughSubject<Accessory, Never>
    private var cancellables: Set<AnyCancellable> = []
    
    init(
        accessoriesProvider: AccessoriesProvider,
        didSelectAccessory: PassthroughSubject<Accessory, Never>
    ) {
        self.accessoriesProvider = accessoriesProvider
        self.didSelectAccessory = didSelectAccessory
        super.init()
    }
    
    func attach(to mapView: MKMapView) {
        mapView.delegate = self
        mapView.register(AccessoryAnnotation.View.self, forAnnotationViewWithReuseIdentifier: AccessoryAnnotation.View.reuseIdentifier)
        mapView.selectedAnnotations = []
        let syncQueue = DispatchQueue(label: "com.rkreutz.OpenHaystack.AccessoriesMapRenderer")
        var hasCentered = false
        
        var annotations: [String: AccessoryAnnotation] = [:]
        for annotation in mapView.annotations {
            guard let annotation = annotation as? AccessoryAnnotation else {
                mapView.removeAnnotation(annotation)
                continue
            }
            annotations[annotation.id] = annotation
        }
        
        didSelectAccessory
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { accessory in
                guard let annotation = syncQueue.sync(execute: { annotations[accessory.id] }) else { return }
                mapView.selectedAnnotations = [annotation]
            })
            .store(in: &cancellables)
        
        accessoriesProvider.accessories()
            .removeDuplicates(by: { lhs, rhs -> Bool in
                guard lhs.count == rhs.count else { return false }
                return lhs.allSatisfy { lhs in
                    guard let rhs = rhs.first(where: { $0.id == lhs.id }) else { return false }
                    return lhs.name == rhs.name
                    && lhs.color == rhs.color
                    && lhs.imageName == rhs.imageName
                    && lhs.latestLocation?.latitude == rhs.latestLocation?.latitude
                    && lhs.latestLocation?.longitude == rhs.latestLocation?.longitude
                }
            })
            .map { accessories in
                var annotationsToBeAdded: [AccessoryAnnotation] = []
                var annotationsToBeUpdated: [AccessoryAnnotation] = []
                var annotationsToBeRemoved: [AccessoryAnnotation] = []
                for accessory in accessories {
                    if let annotation = syncQueue.sync(execute: { annotations[accessory.id] }) {
                        if accessory.latestLocation != nil {
                            if annotation.update(with: accessory) {
                                annotationsToBeUpdated.append(annotation)                                
                            }
                        } else {
                            annotationsToBeRemoved.append(annotation)
                        }
                    } else if accessory.latestLocation != nil {
                        annotationsToBeAdded.append(AccessoryAnnotation(accessory: accessory))
                    }
                }
                
                for annotationId in annotations.keys {
                    guard !accessories.contains(where: { $0.id == annotationId }) else { continue }
                    if let annotation = annotations.removeValue(forKey: annotationId) {
                        annotationsToBeRemoved.append(annotation)
                    }
                }
                
                return (annotationsToBeAdded, annotationsToBeUpdated, annotationsToBeRemoved)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { (annotationsToBeAdded: [AccessoryAnnotation], annotationsToBeUpdated: [AccessoryAnnotation], annotationsToBeRemoved: [AccessoryAnnotation]) in
                annotationsToBeUpdated.forEach(mapView.layoutAnnotationView(for:))
                mapView.addAnnotations(annotationsToBeAdded)
                mapView.removeAnnotations(annotationsToBeRemoved)
                syncQueue.sync {
                    annotationsToBeAdded.forEach { annotations[$0.id] = $0 }
                    annotationsToBeRemoved.forEach { annotations.removeValue(forKey: $0.id) }
                }
                
                if !hasCentered, !annotations.isEmpty {
                    hasCentered = true
                    mapView.showAnnotations(
                        annotations.values.map { $0 },
                        withPadding: Constants.mapPadding,
                        animated: true
                    )
                }
            })
            .store(in: &cancellables)
    }
}

extension AccessoriesMapRenderer: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        mapView.dequeueReusableAnnotationView(withIdentifier: AccessoryAnnotation.View.reuseIdentifier, for: annotation)
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        guard let annotation = annotation as? AccessoryAnnotation else { return }
        didSelectAccessory.send(annotation.accessory)
    }
}
