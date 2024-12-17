//
//  QRScanViewController.swift
//  BauBuddyApp
//
//  Created by Ekin Atasoy on 12.12.2024.
//
// Delegate protocol for QR code scanning

import Foundation
import UIKit
import AVFoundation
protocol QRCodeScannerDelegate: AnyObject {
    func qrCodeScanner(_ scanner: QRCodeScannerViewController, didScanCode code: String)
    func qrCodeScannerDidFailWithError(_ scanner: QRCodeScannerViewController, error: Error?)
    func qrCodeScannerDidCancel(_ scanner: QRCodeScannerViewController)
}

class QRCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    // MARK: - Properties
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Delegate for handling QR code scanning events
    weak var delegate: QRCodeScannerDelegate?
    
    // Cancel button
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelScanning), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScanner()
    }
    
    private func setupView() {
        view.backgroundColor = .black
        
        // Add cancel button
        view.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Scanner Setup
    private func setupScanner() {
        captureSession = AVCaptureSession()
        
        checkCameraAuthorization { [weak self] authorized in
            guard let self = self, authorized else {
                self?.handleCameraAccessDenied()
                return
            }
            self.configureCaptureSession()
        }
    }
    
    private func configureCaptureSession() {
        guard let captureSession = captureSession else { return }
        
        do {
            // Setup input
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
                throw NSError(domain: "QRScannerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to create capture input"])
            }
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // Setup metadata output
            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }
            
            // Setup preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = view.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }
            
            // Start capture session
            DispatchQueue.global(qos: .background).async {
                captureSession.startRunning()
            }
        } catch {
            // Notify delegate about setup failure
            delegate?.qrCodeScannerDidFailWithError(self, error: error)
        }
    }
    
    // MARK: - Camera Authorization
    private func checkCameraAuthorization(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - Error Handling
    private func handleCameraAccessDenied() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please grant camera access in Settings to scan QR codes.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.delegate?.qrCodeScannerDidCancel(self!)
        })
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - User Actions
    @objc private func cancelScanning() {
        delegate?.qrCodeScannerDidCancel(self)
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Stop scanning
        captureSession?.stopRunning()
        
        // Process first metadata object
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue {
            // Notify delegate with scanned code
            delegate?.qrCodeScanner(self, didScanCode: stringValue)
        }
    }
    
    // MARK: - Cleanup
    deinit {
        captureSession?.stopRunning()
    }
}
