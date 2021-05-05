//
//  Alert.swift
//  Elonidas
//
//  Created by Ondrej Winter on 14.04.2021.
//

import Foundation
import UIKit

class Alert {
    
    public static func showAlert(viewController: UIViewController, title: String, message: String, actionTitle:String, style: UIAlertAction.Style ) {

    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

    alert.addAction(UIAlertAction(title: actionTitle, style: style, handler: nil))

    viewController.present(alert, animated: true)
        
    }
    
    
    
    
}
