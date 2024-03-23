//
//  AccessoryAnnotation.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 17/03/24.
//

import MapKit

final class AccessoryAnnotation: MKPointAnnotation, Identifiable {
    final class View: MKMarkerAnnotationView {
        static let reuseIdentifier = "accessory"
        
        override var annotation: MKAnnotation? {
            didSet {
                layoutAnnotation()
            }
        }
        
        override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
            super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
            layoutAnnotation()
            zPriority = .max
            selectedZPriority = .max
            focusGroupPriority = .prioritized
            displayPriority = .required
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func layoutAnnotation() {
            guard let annotation = annotation as? AccessoryAnnotation else { return }
            self.glyphImage = UIImage(systemName: annotation.accessory.imageName)
            self.markerTintColor = UIColor(annotation.accessory.color)
        }
    }
    
    var id: String { accessory.id }
    
    private(set) var accessory: Accessory
    
    init(accessory: Accessory) {
        self.accessory = accessory
        super.init()
        if let latestLocation = accessory.latestLocation {
            self.coordinate = CLLocationCoordinate2D(latitude: latestLocation.latitude, longitude: latestLocation.longitude)
        }
        self.title = accessory.name
    }
    
    func update(with accessory: Accessory) {
        self.accessory = accessory
        if let latestLocation = accessory.latestLocation {
            coordinate = CLLocationCoordinate2D(latitude: latestLocation.latitude, longitude: latestLocation.longitude)
        }
        title = accessory.name
    }
}
