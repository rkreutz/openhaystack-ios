//
//  LocationAnnotation.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 18/03/24.
//

import MapKit

final class LocationAnnotation: MKPointAnnotation {
    final class View: MKAnnotationView {
        static let reuseIdentifier = "location"
        
        let dotLayer = LocationDotLayer()
        
        override var annotation: MKAnnotation? {
            didSet {
                layoutAnnotation()
            }
        }
        
        override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
            super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
            layoutAnnotation()
            canShowCallout = true
            layer.addSublayer(dotLayer)
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func layoutAnnotation() {
            guard let locationAnnotation = annotation as? LocationAnnotation else { return }
            zPriority = locationAnnotation.isLatest ? .max : .min
            displayPriority = locationAnnotation.isLatest ? .required : .defaultLow
            dotLayer.fillColor = locationAnnotation.isLatest ? UIColor.accent.cgColor : UIColor.systemGray.cgColor
        }
    }
    
    var id: String { location.id }
    private(set) var location: Location
    private(set) var isLatest: Bool
    
    init(location: Location, isLatest: Bool) {
        self.location = location
        self.isLatest = isLatest
        super.init()
        self.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        self.title = location.address ?? "\(location.latitude), \(location.longitude)"
    }
    
    func update(with location: Location, isLatest: Bool) -> Bool {
        guard
            location.id != self.location.id ||
            location.latitude != self.location.latitude ||
            location.longitude != self.location.longitude ||
            location.address != self.location.address ||
            isLatest != self.isLatest
        else { return false }
        
        self.location = location
        self.isLatest = isLatest
        self.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        self.title = location.address ?? "\(location.latitude), \(location.longitude)"

        return true
    }
}
