//
//  ContainerController.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 14/03/24.
//

import UIKit

protocol ContainerController where Self: UIViewController {
    var currentContentController: ContentController? { get set }

    func show(contentController: ContentController)
}
