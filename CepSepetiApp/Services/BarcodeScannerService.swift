//
//  BarcodeScannerService.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation
import AVFoundation

/// A service responsible for managing the camera session and detecting barcodes (EAN-8, EAN-13, UPC-E).
/// Kamera oturumunu yönetmekten ve barkodları (EAN-8, EAN-13, UPC-E) algılamaktan sorumlu bir servis.
final class BarcodeScannerService: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    /// The capture session that manages the data flow from the camera hardware to the outputs.
    /// Kamera donanımından çıktılara veri akışını yöneten yakalama oturumu.
    let captureSession = AVCaptureSession()
    
    /// A closure that is triggered when a valid barcode is successfully scanned.
    /// Geçerli bir barkod başarıyla tarandığında tetiklenen bir closure.
    var onBarcodeScanned: ((String) -> Void)?
    
    /// A private background queue to handle session configuration and lifecycle without blocking the main UI thread.
    /// Ana UI iş parçacığını engellemeden oturum yapılandırmasını ve yaşam döngüsünü yönetmek için özel bir arka plan kuyruğu.
    private let sessionQueue = DispatchQueue(label: "com.cepsepeti.cameraQueue")
    
    override init() {
        super.init()
        setupCamera()
    }
    
    /// Configures the camera hardware settings such as focus and zoom.
    /// Odak ve yakınlaştırma gibi kamera donanım ayarlarını yapılandırır.
    /// - Parameter device: The capture device to configure.
    private func configureCameraFocus(device: AVCaptureDevice){
        do {
            try device.lockForConfiguration()
            
            // Set focus point to the center of the screen
            // Odak noktasını ekranın merkezine ayarla
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }
            // Enable continuous auto-focus if supported
            // Destekleniyorsa sürekli otomatik odağı etkinleştir
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            // Set a default zoom factor for better barcode recognition
            // Daha iyi barkod tanıma için varsayılan bir yakınlaştırma faktörü ayarla
            let recommendedZoom: CGFloat = 2.0
            device.videoZoomFactor = min(recommendedZoom, device.activeFormat.videoMaxZoomFactor)
            
            device.unlockForConfiguration()
        } catch {
            print("Error: Could not configure camera focus. \(error.localizedDescription)")
        }
    }
    
    /// Initializes the capture session by setting up inputs and outputs.
    /// Girişleri ve çıkışları ayarlayarak yakalama oturumunu başlatır.
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            // Step 1: Find and add the back camera as input
            // Adım 1: Arka kamerayı bul ve giriş olarak ekle
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
                print("Error: Back camera not accessible.")
                self.captureSession.commitConfiguration()
                return
            }
            
            self.configureCameraFocus(device: videoCaptureDevice)
            
            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
            } else {
                print("Error: Camera input could not be added to session.")
                self.captureSession.commitConfiguration()
                return
            }
            
            // Step 2: Add metadata output for barcode detection
            // Adım 2: Barkod algılama için meta veri çıktısı ekle
            let metadataOutput = AVCaptureMetadataOutput()
            
            if self.captureSession.canAddOutput(metadataOutput) {
                self.captureSession.addOutput(metadataOutput)
                
                // Set the delegate to handle scanned results on the main queue
                // Taranan sonuçları ana kuyrukta işlemek için delegeyi ayarla
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                // Define the types of barcodes to scan
                // Taranacak barkod türlerini tanımla
                metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce]
            } else {
                print("Error: Metadata output could not be added to session.")
                self.captureSession.commitConfiguration()
                return
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    /// Starts the camera session on a background thread.
    /// Kamera oturumunu bir arka plan iş parçacığında başlatır.
    func startScanning() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    /// Stops the camera session on a background thread.
    /// Kamera oturumunu bir arka plan iş parçacığında durdurur.
    func stopScanning() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    /// Delegate method triggered when the camera detects metadata objects (barcodes).
    /// Kamera meta veri nesnelerini (barkodlar) algıladığında tetiklenen delege yöntemi.
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Extract the first readable barcode string
        // İlk okunabilir barkod dizesini çıkar
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // Stop scanning immediately to prevent duplicate scans
                // Yinelenen taramaları önlemek için taramayı hemen durdur
                self.stopScanning()
                // Provide haptic feedback to notify the user
                // Kullanıcıyı bilgilendirmek için haptik geri bildirim sağla
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                // Pass the scanned barcode to the UI layer
                // Taranan barkodu UI katmanına ilet
                self.onBarcodeScanned?(stringValue)
            }
        }
    }
}

/*
 SUMMARY:
 BarcodeScannerService leverages AVFoundation to provide real-time barcode scanning capabilities.
 It configures the camera hardware for optimal scanning and filters for specific market barcode types.
 It interacts with ScannerView to provide the camera feed and with HomeViewModel/ScannerViewModel to process results.
 
 ÖZET:
 BarcodeScannerService, gerçek zamanlı barkod tarama yetenekleri sağlamak için AVFoundation'dan yararlanır.
 Kamera donanımını en uygun tarama için yapılandırır ve belirli market barkod türleri için filtreleme yapar.
 Kamera akışını sağlamak için ScannerView ile ve sonuçları işlemek için HomeViewModel/ScannerViewModel ile etkileşime girer.
 */
