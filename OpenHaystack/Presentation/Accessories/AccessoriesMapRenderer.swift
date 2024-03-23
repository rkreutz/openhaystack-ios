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
                guard let annotation = annotations[accessory.id] else { return }
                mapView.selectedAnnotations = [annotation]
            })
            .store(in: &cancellables)
        
        accessoriesProvider.accessories()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { accessories in
                for accessory in accessories {
                    if let annotation = annotations[accessory.id] {
                        if accessory.latestLocation != nil {
                            annotation.update(with: accessory)
                            mapView.layoutAnnotationView(for: annotation)
                        } else {
                            mapView.removeAnnotation(annotation)
                            annotations.removeValue(forKey: accessory.id)
                        }
                    } else if accessory.latestLocation != nil {
                        let annotation = AccessoryAnnotation(accessory: accessory)
                        mapView.addAnnotation(annotation)
                        annotations[accessory.id] = annotation
                    }
                }
                
                for annotationId in annotations.keys {
                    guard !accessories.contains(where: { $0.id == annotationId }) else { continue }
                    if let annotation = annotations.removeValue(forKey: annotationId) {
                        mapView.removeAnnotation(annotation)
                    }
                }
                
                mapView.showAnnotations(
                    annotations.values.map { $0 },
                    withPadding: Constants.mapPadding,
                    animated: true
                )
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
