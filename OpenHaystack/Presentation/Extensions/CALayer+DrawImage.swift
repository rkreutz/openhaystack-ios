//
//  CALayer+DrawImage.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 23/03/24.
//

import UIKit

extension CALayer {
    func drawImage(frame: CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, isOpaque, 0); defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.translateBy(x: frame.origin.x, y: frame.origin.y)
        render(in: ctx)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        return outputImage
    }
}
