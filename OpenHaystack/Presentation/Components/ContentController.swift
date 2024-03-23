//
//  ContentController.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 14/03/24.
//

import UIKit

protocol ContentController where Self: UIViewController {
    var containerController: ContainerController? { get set }
    func mapRenderer() -> MapRenderer?
}
