//
//  ImageViewExtension.swift
//  Elonidas
//
//  Created by Ondrej Winter on 16.05.2021.
//

import Foundation
import UIKit

extension UIImageView {

   func setRounded() {
    self.layer.cornerRadius = self.frame.height / 2
    self.clipsToBounds = true
   }
}
