//
//  MKMapView+ShowAnnotations.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 22/03/24.
//

import MapKit

extension MKMapView {
    func showAnnotations(_ annotations: [MKAnnotation], withPadding padding: UIEdgeInsets, animated: Bool) {
        guard !annotations.isEmpty else { return }
        let rect = annotations.reduce(MKMapRect.null) { partialResult, annotation in
            partialResult.union(MKMapRect(origin: MKMapPoint(annotation.coordinate), size: .init(width: 1, height: 1)))
        }
        
        setVisibleMapRect(rect, edgePadding: padding, animated: animated)
    }
}
