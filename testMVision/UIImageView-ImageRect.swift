//
//  UIImageView-ImageRect.swift
//  testMVision
//
//  Created by Tarek El Ghoul on 17/11/2019.
//  Copyright © 2019 Tarek El Ghoul. All rights reserved.
//

import UIKit

extension UIImageView {
    /// Calculates the rect of an image displayed in a `UIImageView` with the `scaleAspectFit` `contentMode`
    var imageRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }
        
        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }
        
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0
        
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}
