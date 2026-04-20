//
//  CameraService.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 20.04.2026.
//

import Foundation
import AVFoundation
import UIKit

// Swift 6 strict concurrency kurallarına uygun olarak
// delegate (geri çağırma) işlemlerini izole eden yardımcı sınıf.
final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private var continuation: CheckedContinuation<UIImage, Error>?
    var onComplete: (() -> Void)? // İşlem bitince belleği temizlemek için
    
    init(continuation: CheckedContinuation<UIImage, Error>) {
        self.continuation = continuation
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { onComplete?() } // Scope kapanırken tetiklenir
        
        guard let continuation = self.continuation else { return }
        self.continuation = nil // Çift tetiklenmeyi önle (Veri yarışı kalkanı)
        
        if let error = error {
            continuation.resume(throwing: error)
            return
        }
        
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            continuation.resume(throwing: NSError(domain: "CameraService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Fotoğraf işlenemedi."]))
            return
        }
        
        continuation.resume(returning: image)
    }
}

final class CameraService: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    // Fotoğraf çekimi bitene kadar delegate nesnesini bellekte tutan referans
    private var activeProcessor: PhotoCaptureProcessor?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // 1. Arka kamerayı bul ve Input olarak ekle
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            print("HATA: Arka kameraya ulaşılamadı.")
            session.commitConfiguration()
            return
        }
        
        self.videoDeviceInput = videoDeviceInput
        session.addInput(videoDeviceInput)
        
        // 2. Fotoğraf Output'unu ekle
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            // Cihazın donanımsal olarak desteklediği en yüksek çözünürlük boyutunu bul ve ata
            if let maxDimensions = videoDeviceInput.device.activeFormat.supportedMaxPhotoDimensions.last {
                photoOutput.maxPhotoDimensions = maxDimensions
            }
        }
        
        session.commitConfiguration()
    }
    
    // AVCaptureSession başlatma/durdurma işlemleri Main Thread'i bloke etmemesi için
    // arka planda (background queue) yapılmak zorundadır.
    func start() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }
    
    // El feneri kontrolü
    func toggleFlash(isOn: Bool) {
        guard let device = videoDeviceInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = isOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Flaş kontrol hatası: \(error)")
        }
    }
    
    // Donanımsal Odak ve Pozlama Kilidi
    private func lockFocusAndExposure() {
        guard let device = videoDeviceInput?.device else { return }
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            if device.isExposureModeSupported(.autoExpose) {
                device.exposureMode = .autoExpose
            }
            device.unlockForConfiguration()
        } catch {
            print("Odak/Pozlama kilitlenemedi: \(error)")
        }
    }
    
    // Dışarıdan çağrılacak ana fonksiyon
    func capturePhoto() async throws -> UIImage {
        // 1. Görüntüyü sabitle
        lockFocusAndExposure()
        
        // 2. Lensin mekanik olarak odaklanması için ufak bir gecikme ver (300 ms)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // 3. Fotoğrafı çek ve async yapıya bağla
        return try await withCheckedThrowingContinuation { continuation in
            let processor = PhotoCaptureProcessor(continuation: continuation)
            
            processor.onComplete = { [weak self] in
                self?.activeProcessor = nil
            }
            
            self.activeProcessor = processor
            
            let settings = AVCapturePhotoSettings()
            settings.maxPhotoDimensions = self.photoOutput.maxPhotoDimensions
            // Eğer istersen settings.flashMode = .auto yapabilirsin
            
            self.photoOutput.capturePhoto(with: settings, delegate: processor)
        }
    }
}
