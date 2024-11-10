//
//  AccessoryHistoryMapRenderer.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 18/03/24.
//

import MapKit
import UIKit
import Combine

final class AccessoryHistoryMapRenderer: NSObject, MapRenderer {
    enum Constants {
        static let mapPadding = UIEdgeInsets(top: 100, left: 50, bottom: 100, right: 50)
    }
    
    private let accessoryId: String
    private let accessoriesProvider: AccessoriesProvider
    private let didTapLocation: PassthroughSubject<Location, Never>
    private var cancellables: Set<AnyCancellable> = []
    
    init(
        accessoryId: String,
        accessoriesProvider: AccessoriesProvider,
        didTapLocation: PassthroughSubject<Location, Never>
    ) {
        self.accessoryId = accessoryId
        self.accessoriesProvider = accessoriesProvider
        self.didTapLocation = didTapLocation
        super.init()
    }
    
    func attach(to mapView: MKMapView) {
        mapView.delegate = self
        mapView.register(LocationAnnotation.View.self, forAnnotationViewWithReuseIdentifier: LocationAnnotation.View.reuseIdentifier)
        let syncQueue = DispatchQueue(label: "com.rkreutz.OpenHaystack.AccessoryHistoryMapRenderer")
        
        var annotations: [String: LocationAnnotation] = [:]
        mapView.removeAnnotations(mapView.annotations)
        var hasCentered = false
        
        accessoriesProvider.accessories()
            .map { [accessoryId] in $0.first(where: { $0.id == accessoryId }) }
            .removeDuplicates(by: { $0?.locations == $1?.locations })
            .map { accessory -> ([LocationAnnotation], [LocationAnnotation], [LocationAnnotation]) in
                var annotationsToBeAdded: [LocationAnnotation] = []
                var annotationsToBeUpdated: [LocationAnnotation] = []
                var annotationsToBeRemoved: [LocationAnnotation] = []
                guard let accessory else {
                    annotationsToBeRemoved = syncQueue.sync { annotations.values.map { $0 } }
                    return (annotationsToBeAdded, annotationsToBeUpdated, annotationsToBeRemoved)
                }
                
                for location in accessory.locations {
                    if let annotation = syncQueue.sync(execute: { annotations[location.id] }) {
                        if annotation.update(with: location, isLatest: location != accessory.latestLocation) {
                            annotationsToBeUpdated.append(annotation)
                        }
                    } else {
                        annotationsToBeAdded.append(LocationAnnotation(location: location, isLatest: location == accessory.latestLocation))
                    }
                }
                
                for annotationId in annotations.keys {
                    guard !accessory.locations.contains(where: { $0.id == annotationId }) else { continue }
                    if let annotation = annotations.removeValue(forKey: annotationId) {
                        annotationsToBeRemoved.append(annotation)
                    }
                }
                
                return (annotationsToBeAdded, annotationsToBeUpdated, annotationsToBeRemoved)
                
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { (annotationsToBeAdded: [LocationAnnotation], annotationsToBeUpdated: [LocationAnnotation], annotationsToBeRemoved: [LocationAnnotation]) in
                annotationsToBeUpdated.forEach(mapView.layoutAnnotationView(for:))
                mapView.addAnnotations(annotationsToBeAdded)
                mapView.removeAnnotations(annotationsToBeRemoved)
                syncQueue.sync {
                    annotationsToBeAdded.forEach { annotations[$0.id] = $0 }
                    annotationsToBeRemoved.forEach { annotations.removeValue(forKey: $0.id) }
                }
                
                if !hasCentered {
                    hasCentered = true
                    mapView.showAnnotations(
                        annotations.values.map { $0 },
                        withPadding: Constants.mapPadding,
                        animated: true
                    )
                }
            })
            .store(in: &cancellables)
        
        didTapLocation
            .removeDuplicates()
            .compactMap { annotations[$0.id] }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                mapView.setRegion(.init(center: $0.coordinate, latitudinalMeters: 200, longitudinalMeters: 200), animated: true)
                mapView.selectedAnnotations = [$0]
            })
            .store(in: &cancellables)
    }
}

extension AccessoryHistoryMapRenderer: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case _ as AccessoryAnnotation:
            return mapView.dequeueReusableAnnotationView(withIdentifier: AccessoryAnnotation.View.reuseIdentifier, for: annotation)
        case _ as LocationAnnotation:
            return mapView.dequeueReusableAnnotationView(withIdentifier: LocationAnnotation.View.reuseIdentifier, for: annotation)
        default:
            return nil
        }
    }
}
