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
        
        var annotations: [LocationAnnotation] = []
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
        
        accessoriesProvider.accessories()
            .map { [accessoryId] in $0.first(where: { $0.id == accessoryId }) }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { accessory in
                if let accessory {
                    mapView.removeAnnotations(annotations)
                    annotations = accessory.locations.map { LocationAnnotation(location: $0, isLatest: $0 == accessory.latestLocation) }
                    mapView.addAnnotations(annotations)
                    mapView.showAnnotations(
                        annotations,
                        withPadding: Constants.mapPadding,
                        animated: true
                    )
                } else {
                    mapView.removeAnnotations(annotations)
                    annotations = []
                }
            })
            .store(in: &cancellables)
        
        didTapLocation
            .removeDuplicates()
            .compactMap { location in
                annotations.first(where: { $0.location == location })
            }
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
