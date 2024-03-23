//
//  MapAnnotation.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 15/03/24.
//

import CoreLocation

protocol MapAnnotation: Identifiable where ID == String {
    var coordinates: CLLocationCoordinate2D { get }
    var title: String? { get }
    var subtitle: String? { get }
}
