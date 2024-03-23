//
//  MKMapView+LayoutAnnotationView.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 22/03/24.
//

import MapKit

extension MKMapView {
    func layoutAnnotationView(for annotation: MKAnnotation) {
        view(for: annotation)?.annotation = annotation
    }
}
