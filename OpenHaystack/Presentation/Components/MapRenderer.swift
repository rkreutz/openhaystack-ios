//
//  MapRenderer.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 15/03/24.
//

import Foundation
import MapKit

protocol MapRenderer: AnyObject {
    func attach(to mapView: MKMapView)
}
