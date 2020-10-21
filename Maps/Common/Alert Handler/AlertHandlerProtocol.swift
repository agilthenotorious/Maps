//
//  AlertHandlerProtocol.swift
//  Maps
//
//  Created by Agil Madinali on 10/21/20.
//

import UIKit

enum AlertButton: String {
    case okay
    case cancel
    case delete
    case settings
}

protocol AlertHandlerProtocol: UIViewController {
    func showAlert(title: String, message: String, buttons: [AlertButton], completion: @escaping (UIAlertController, AlertButton) -> Void)
}

extension AlertHandlerProtocol {
    
    func showAlert(title: String, message: String, buttons: [AlertButton] = [.okay], completion: @escaping (UIAlertController, AlertButton) -> Void) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        buttons.forEach { button in
            let action = UIAlertAction(title: button.rawValue.capitalized, style: button == .delete ? .destructive : .default) { [alert, button] _ in
                completion(alert, button)
            }
            alert.addAction(action)
        }
        present(alert, animated: true, completion: nil)
    }
}
