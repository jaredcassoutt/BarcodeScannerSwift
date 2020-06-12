//
//  ViewController.swift
//  BarcodeScanner
//
//  Created by Jared Cassoutt on 6/12/20.
//  Copyright © 2020 Jared Cassoutt. All rights reserved.
//

import Vision
import AVFoundation
import UIKit

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: - Variables
    
        @IBOutlet weak private var previewView: UIView!
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var detectionOverlay: CALayer! = nil
        var rootLayer: CALayer! = nil
        var barcodeFrameView:CALayer?
    
    // MARK: - View Setup and Failure Support
    
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = UIColor.black
            captureSession = AVCaptureSession()
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
            let videoInput: AVCaptureDeviceInput
            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                return
            }
            if (captureSession.canAddInput(videoInput)) {
                captureSession.addInput(videoInput)
            } else {
                unsupportedCamera()
                return
            }
            let metadataOutput = AVCaptureMetadataOutput()
            if (captureSession.canAddOutput(metadataOutput)) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417]
            } else {
                unsupportedCamera()
                return
            }
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            captureSession.startRunning()
        }
    
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .portrait
        }

        func unsupportedCamera() {
//            action taken if camera is un able to scan barcodes on device
            self.errorAlert(title: "Cannot Support Scanning", message: "Your device is un able to scan barcodes.")
            captureSession = nil
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if (captureSession?.isRunning == false) {
                captureSession.startRunning()
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if (captureSession?.isRunning == true) {
                captureSession.stopRunning()
            }
        }
    
    // MARK: - Barcode Found
    
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
//            this is what happens when a bar code is successfully found
            captureSession.stopRunning()
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                createBox(metadataObject: metadataObject)
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                self.createAlert(title: "The Barcode Is:", message: stringValue, barcode: stringValue)
            }
        }
    
    func createBox(metadataObject: AVMetadataObject) {
//        this creates the green box that surrounds successful barcode scans
        barcodeFrameView = CALayer()
        if let barcodeFrameView = barcodeFrameView {
            barcodeFrameView.borderColor = UIColor.green.cgColor
            barcodeFrameView.borderWidth = 5
            barcodeFrameView.cornerRadius = 7
            self.view.layer.addSublayer(barcodeFrameView)
        }
        let barCodeObject = previewLayer?.transformedMetadataObject(for: metadataObject)
        barcodeFrameView?.frame = barCodeObject!.bounds
        barcodeFrameView?.frame.origin.y = (barcodeFrameView?.frame.origin.y)! - (barcodeFrameView?.frame.width)!/3
        barcodeFrameView?.frame.size.height = 2/3*(barcodeFrameView?.frame.width)!
    }

    // MARK: - Alerts and barcodeFound()

    func createAlert(title: String, message: String, barcode: String) {
//        displays an alert to the user when barcode is found
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Okay", style: .default, handler: { alert -> Void in
            self.barcodeFound(barcode: barcode)
            self.view.layer.sublayers?.removeLast()
            self.captureSession.startRunning()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            self.view.layer.sublayers?.removeLast()
            self.captureSession.startRunning()
        })
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        alertController.preferredAction = saveAction
        self.present(alertController, animated: true, completion: nil)
    }
    
    func errorAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default))
        present(alertController, animated: true)
    }
    
    func barcodeFound(barcode: String){
//        this is where you put any code you want excecuted once a barcode is found and "Okay" is selected
        
    }
}



