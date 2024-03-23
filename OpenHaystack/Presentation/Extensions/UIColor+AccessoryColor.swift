//
//  UIColor+Hex.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 15/03/24.
//

import UIKit

extension UIColor {
    convenience init(_ color: Accessory.Color) {
        self.init(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: CGFloat(color.alpha))
    }
    
    func asAccessoryColor() -> Accessory.Color {
        .init(
            red: Double(cgColor.components?[0] ?? 0),
            green: Double(cgColor.components?[1] ?? 0),
            blue: Double(cgColor.components?[2] ?? 0),
            alpha: Double(cgColor.components?[3] ?? 0)
        )
    }
}
