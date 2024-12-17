//
//  UniversalKeyboardManager.swift
//  BauBuddyApp
//
//  Created by Ekin Atasoy on 12.12.2024.
//

import Foundation
import UIKit
class UniversalKeyboardManager {
    // Singleton instance
    static let shared = UniversalKeyboardManager()
    
    // Configuration options
    struct Configuration {
        var isEnabled = true
        var shouldResignOnTouchOutside = true
        var keyboardDistanceFromTextField: CGFloat = 10
        var enableAutoToolbar = true
        var shouldShowToolbarPlaceholder = true
        var previousNextDisplayMode: ToolbarMode = .default
    }
    
    // Toolbar mode for previous/next navigation
    enum ToolbarMode {
        case `default`
        case fixed
        case flexible
    }
    
    // Configuration instance
    var config = Configuration()
    
    // Private initializer
    private init() {
        setupKeyboardNotifications()
    }
    
    // Setup keyboard notifications
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // Keyboard show handler
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard config.isEnabled else { return }
        
        adjustKeyboardForActiveTextField(notification: notification)
    }
    
    // Keyboard hide handler
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard config.isEnabled else { return }
        
        resetViewPosition()
    }
    
    // Adjust view for active text field
    private func adjustKeyboardForActiveTextField(notification: Notification) {
        guard let activeTextField = findActiveTextField(),
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let window = UIApplication.shared.windows.first else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        let textFieldAbsoluteFrame = activeTextField.convert(activeTextField.bounds, to: window)
        let screenHeight = window.frame.height
        
        // Calculate overlap
        let overlap = textFieldAbsoluteFrame.maxY - (screenHeight - keyboardHeight - config.keyboardDistanceFromTextField)
        
        if overlap > 0 {
            UIView.animate(withDuration: duration) {
                if let scrollView = self.findParentScrollView(of: activeTextField) {
                    scrollView.contentOffset.y += overlap
                } else {
                    window.frame.origin.y = -overlap
                }
            }
        }
    }
    
    // Reset view position
    private func resetViewPosition() {
        guard let window = UIApplication.shared.windows.first else { return }
        
        UIView.animate(withDuration: 0.3) {
            window.frame.origin.y = 0
        }
    }
    
    // Find active text field
    private func findActiveTextField() -> UITextField? {
        return UIApplication.shared.windows.first?.rootViewController?.view.findFirstResponder() as? UITextField
    }
    
    // Find parent scroll view
    private func findParentScrollView(of view: UIView) -> UIScrollView? {
        var parentView = view.superview
        while parentView != nil {
            if let scrollView = parentView as? UIScrollView {
                return scrollView
            }
            parentView = parentView?.superview
        }
        return nil
    }
    
    // Setup toolbar for text fields
    private func setupToolbar(for textField: UITextField) {
        guard config.enableAutoToolbar else { return }
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.barStyle = .default
        
        // Previous button
        let previousButton = UIBarButtonItem(
            title: "Previous",
            style: .plain,
            target: self,
            action: #selector(moveToPreviousTextField)
        )
        
        // Next button
        let nextButton = UIBarButtonItem(
            title: "Next",
            style: .plain,
            target: self,
            action: #selector(moveToNextTextField)
        )
        
        // Flexible space
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Done button
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissKeyboard)
        )
        
        // Set toolbar items based on configuration
        switch config.previousNextDisplayMode {
        case .default:
            toolbar.items = [previousButton, nextButton, flexSpace, doneButton]
        case .fixed:
            toolbar.items = [previousButton, nextButton, doneButton]
        case .flexible:
            toolbar.items = [flexSpace, previousButton, nextButton, flexSpace, doneButton]
        }
        
        textField.inputAccessoryView = toolbar
    }
    
    // Navigate to previous text field
    @objc private func moveToPreviousTextField() {
        // Implementation to move to previous text field
    }
    
    // Navigate to next text field
    @objc private func moveToNextTextField() {
        // Implementation to move to next text field
    }
    
    // Dismiss keyboard
    @objc private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Enable touch outside to dismiss keyboard
    func enableTouchOutsideToDismiss() {
        guard config.shouldResignOnTouchOutside else { return }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        
        UIApplication.shared.windows.first?.rootViewController?.view.addGestureRecognizer(tapGesture)
    }
    
    // Deinit to remove observers
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
