//
//  CGRect+Pad.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 23/03/24.
//

import UIKit

extension CGRect {
    func pad(by insets: UIEdgeInsets) -> CGRect {
        var rect = offsetBy(dx: insets.left, dy: insets.top)
        rect.size.width += insets.left + insets.right
        rect.size.height += insets.top + insets.bottom
        return rect
    }
    
    func padBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        pad(by: .init(top: dy, left: dx, bottom: dy, right: dx))
    }
}
