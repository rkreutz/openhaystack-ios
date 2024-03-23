//
//  LocationDotLayer.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 23/03/24.
//

import UIKit

final class LocationDotLayer: CAShapeLayer {
    override init() {
        super.init()
        commonInit()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        fillColor = UIColor.systemGray.cgColor
        lineWidth = 3
        strokeColor = UIColor.white.cgColor
        path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 12, height: 12)).cgPath
    }
}
