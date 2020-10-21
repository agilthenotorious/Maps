//
//  UIApplication+Ext.swift
//  Maps
//
//  Created by Agil Madinali on 10/21/20.
//

import UIKit

extension UIApplication {
    
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url) { status in
                print("Settings Opened \(status)")
            }
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}
