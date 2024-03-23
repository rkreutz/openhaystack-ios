//
//  UIColor+DrawImage.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 22/03/24.
//

import UIKit

extension UIColor {
    func drawCircle(diameter: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0); defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.saveGState()
        
        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        ctx.setFillColor(cgColor)
        ctx.fillEllipse(in: rect)
        
        ctx.restoreGState()
        let img = UIGraphicsGetImageFromCurrentImageContext()
        
        return img
    }
}
