//
//  BarcodeScannerService.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation
import AVFoundation

final class BarcodeScannerService: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    //Görüntü akışını yönetir
    let captureSession = AVCaptureSession()
    
    //Barkod bulunduğunda UI'a haber verecek
    var onBarcodeScanned: ((String) -> Void)?
    
    //Uygulamanın donmaması için işlemleri arkaplana alacak kuyruk
    private let sessionQueue = DispatchQueue(label: "com.cepsepeti.cameraQueue")
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func configureCameraFocus(device: AVCaptureDevice){
        do{
            // Donanım ayarlarını değiştirmek için cihazı kilitle
            try device.lockForConfiguration()
            
            // Odak noktasını ekranın tam ortasına (X: 0.5, Y: 0.5) sabitle
            if device.isFocusPointOfInterestSupported{
                device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }
            // Sürekli otomatik odaklama destekleniyorsa aktif et
            if device.isFocusModeSupported(.continuousAutoFocus){
                device.focusMode = .continuousAutoFocus
            }
            let recommendedZoom: CGFloat = 2.0
            device.videoZoomFactor = min(recommendedZoom, device.activeFormat.videoMaxZoomFactor)
            
            // 4. Ayarlar bittikten sonra kilidi aç
            device.unlockForConfiguration()
        } catch {
            print("Hata: Kamera odak ayarı yapılamadı. \(error.localizedDescription)")
        }
        
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            // 1. Girdi (Input): Arka kamerayı bul ve ekle
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
                print("Hata: Arka kameraya erişilemiyor veya bulunamadı.")
                self.captureSession.commitConfiguration()
                return
            }
            
            self.configureCameraFocus(device: videoCaptureDevice)
            
            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
            } else {
                print("Hata: Kamera input'u session'a eklenemedi.")
                self.captureSession.commitConfiguration()
                return
            }
            
            // 2. Çıktı (Output): Sadece Metadata (Barkod) arayacağımızı belirtiyoruz
            let metadataOutput = AVCaptureMetadataOutput()
            
            if self.captureSession.canAddOutput(metadataOutput) {
                self.captureSession.addOutput(metadataOutput)
                
                // Barkod bulunduğunda bu sınıfı (self) tetikle
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                // Hangi barkod tiplerini arayacağız? (Market ürünleri EAN13, EAN8 ve UPC kullanır)
                metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce]
            } else {
                print("Hata: Metadata output session'a eklenemedi.")
                self.captureSession.commitConfiguration()
                return
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    func startScanning(){
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopScanning(){
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Gelen veri okunabilir bir barkod mu kontrol et
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // Aynı barkodu saniyede 30 kere okumaması için kamerayı durdur
                self.stopScanning()
                // Titreşim (Haptic Feedback) ile kullanıcıya okunduğunu hissettir
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                // Bulunan barkodu UI tarafına gönder
                self.onBarcodeScanned?(stringValue)
            }
        }
    }
}

