//
//  BaseViewController.swift
//  BauBuddyApp
//
//  Created by Ekin Atasoy on 12.12.2024.
//

import Foundation
import UIKit
import AVFoundation
class BaseViewController: UIViewController {

    var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupActivityIndicator()
        // Configure keyboard manager
        UniversalKeyboardManager.shared.config.shouldResignOnTouchOutside = true
        UniversalKeyboardManager.shared.config.keyboardDistanceFromTextField = 20
        UniversalKeyboardManager.shared.enableTouchOutsideToDismiss()
    }

    func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .gray
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }

    func startActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
            self.view.isUserInteractionEnabled = false
        }
    }

    func stopActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
    func showOfflineMessage() {
            let alert = UIAlertController(
                title: "Offline",
                message: "No internet connection. Showing cached tasks.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
        func showFethcErrorMessage() {
            let alert = UIAlertController(
                title: "Error",
                message: "Unable to fetch tasks. Please try again later.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    
    func showError(message: String, handler: (() -> Void)?) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            handler?()
        })
        present(alert, animated: true, completion: nil)
    }
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
    func redirectingAlert(title:String,message: String, handler: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            handler?()
        })
        present(alert, animated: true, completion: nil)
    }
    
    func showCameraError() {
        let alert = UIAlertController(title: "Camera Error", message: "Your device does not support scanning a QR code.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}
