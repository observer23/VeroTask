//
//  Extensions.swift
//  BauBuddyApp
//
//  Created by Ekin Atasoy on 12.12.2024.
//

import Foundation
import UIKit
extension UIColor {
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
           // Remove any whitespace and # prefix
           let hex = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
               .replacingOccurrences(of: "#", with: "")
           
           // Ensure the hex string is valid
           guard hex.count == 3 || hex.count == 6 || hex.count == 8 else {
               self.init(red: 0, green: 0, blue: 0, alpha: 1.0)
               return
           }
           
           // Convert hex to integer
           var hexValue: UInt64 = 0
           Scanner(string: hex).scanHexInt64(&hexValue)
           
           // Handle different hex formats
           switch hex.count {
           case 3: // RGB (12-bit)
               let r = CGFloat((hexValue >> 8) & 0xF) / 15.0
               let g = CGFloat((hexValue >> 4) & 0xF) / 15.0
               let b = CGFloat(hexValue & 0xF) / 15.0
               self.init(red: r, green: g, blue: b, alpha: alpha)
               
           case 6: // RGB (24-bit)
               let r = CGFloat((hexValue >> 16) & 0xFF) / 255.0
               let g = CGFloat((hexValue >> 8) & 0xFF) / 255.0
               let b = CGFloat(hexValue & 0xFF) / 255.0
               self.init(red: r, green: g, blue: b, alpha: alpha)
               
           case 8: // ARGB (32-bit)
               let a = CGFloat((hexValue >> 24) & 0xFF) / 255.0
               let r = CGFloat((hexValue >> 16) & 0xFF) / 255.0
               let g = CGFloat((hexValue >> 8) & 0xFF) / 255.0
               let b = CGFloat(hexValue & 0xFF) / 255.0
               self.init(red: r, green: g, blue: b, alpha: a)
               
           default:
               self.init(red: 0, green: 0, blue: 0, alpha: 1.0)
           }
       }
}
// Extension to find first responder
extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }
        
        for subview in subviews {
            if let firstResponder = subview.findFirstResponder() {
                return firstResponder
            }
        }
        
        return nil
    }
}
