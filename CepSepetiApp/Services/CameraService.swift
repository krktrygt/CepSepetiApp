//
//  CameraService.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 20.04.2026.
//

import Foundation
import AVFoundation
import UIKit

/// A helper class that handles the photo capture delegate callbacks and manages Swift concurrency continuations.
/// Fotoğraf yakalama delege geri çağırmalarını yöneten ve Swift eşzamanlılık devamlılıklarını (continuations) idare eden yardımcı sınıf.
nonisolated final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private var continuation: CheckedContinuation<UIImage, Error>?
    /// Callback triggered when the process is fully complete to allow for cleanup.
    /// İşlem tamamen bittiğinde temizlik yapılmasına izin vermek için tetiklenen geri çağırma.
    var onComplete: (() -> Void)? 
    
    init(continuation: CheckedContinuation<UIImage, Error>) {
        self.continuation = continuation
    }
    
    /// Delegate method called when the photo capture output has finished processing a photo.
    /// Fotoğraf yakalama çıktısı bir fotoğrafı işlemeyi bitirdiğinde çağrılan delege yöntemi.
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { onComplete?() } 
        
        guard let continuation = self.continuation else { return }
        self.continuation = nil // Ensure continuation is resumed only once
        // Devamlılığın (continuation) yalnızca bir kez sürdürüldüğünden emin olun
        
        if let error = error {
            continuation.resume(throwing: error)
            return
        }
        
        // Convert captured photo data to a UIImage
        // Yakalanan fotoğraf verilerini bir UIImage'e dönüştür
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            continuation.resume(throwing: NSError(domain: "CameraService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Photo could not be processed."]))
            return
        }
        
        continuation.resume(returning: image)
    }
}

/// A service that manages high-resolution photo capture for OCR purposes.
/// OCR amaçları için yüksek çözünürlüklü fotoğraf yakalamayı yöneten bir servis.
final class CameraService: NSObject {
    /// The capture session managing the camera stream.
    /// Kamera akışını yöneten yakalama oturumu.
    let session = AVCaptureSession()
    /// Output for capturing high-resolution photos.
    /// Yüksek çözünürlüklü fotoğraflar yakalamak için çıktı.
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "CepSepetiApp.CameraSessionQueue", qos: .userInitiated)
    private var isSessionRunning = false
    private var isShuttingDown = false
    /// Reference to the video input device.
    /// Video giriş cihazına referans.
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    /// Reference to the active processor to keep it in memory during the capture process.
    /// Yakalama işlemi sırasında bellekte tutmak için aktif işlemciye referans.
    private var activeProcessor: PhotoCaptureProcessor?
    
    override init() {
        super.init()
        setupSession()
    }
    
    /// Configures the capture session with inputs and outputs for photo capture.
    /// Yakalama oturumunu fotoğraf yakalama için giriş ve çıkışlarla yapılandırır.
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Step 1: Find and add the back camera as input
        // Adım 1: Arka kamerayı bul ve giriş olarak ekle
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            print("ERROR: Could not access back camera.")
            session.commitConfiguration()
            return
        }
        
        self.videoDeviceInput = videoDeviceInput
        session.addInput(videoDeviceInput)
        
        // Step 2: Add photo output
        // Adım 2: Fotoğraf çıktısını ekle
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            // Configure max photo dimensions for highest possible quality
            // Mümkün olan en yüksek kalite için maksimum fotoğraf boyutlarını yapılandır
            if let maxDimensions = videoDeviceInput.device.activeFormat.supportedMaxPhotoDimensions.last {
                photoOutput.maxPhotoDimensions = maxDimensions
            }
        }
        
        session.commitConfiguration()
    }
    
    /// Starts the capture session on a serial session queue.
    /// Yakalama oturumunu seri session kuyruğunda başlatır.
    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.isSessionRunning else { return }
            self.isShuttingDown = false
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
        }
    }
    
    /// Stops the capture session on a serial session queue.
    /// Yakalama oturumunu seri session kuyruğunda durdurır.
    func stop(completion: (() -> Void)? = nil) {
        sessionQueue.async { [weak self] in
            if let self {
                self.isShuttingDown = true
                self.disableTorchIfNeeded()

                if self.isSessionRunning {
                    self.session.stopRunning()
                    self.isSessionRunning = self.session.isRunning
                }
            }

            if let completion {
                DispatchQueue.main.async(execute: completion)
            }
        }
    }
    
    /// Toggles the camera's torch (flashlight).
    /// Kameranın fenerini (el feneri) açar/kapatır.
    /// - Parameter isOn: Boolean indicating whether the torch should be on or off.
    func toggleFlash(isOn: Bool) {
        sessionQueue.async { [weak self] in
            guard let self,
                  !self.isShuttingDown,
                  let device = self.videoDeviceInput?.device,
                  device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = isOn ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("Flash control error: \(error)")
            }
        }
    }

    private func disableTorchIfNeeded() {
        guard let device = videoDeviceInput?.device,
              device.hasTorch,
              device.torchMode != .off else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        } catch {
            print("Flash cleanup error: \(error)")
        }
    }
    
    /// Locks focus and exposure to the current state to ensure image clarity before capture.
    /// Yakalamadan önce görüntü netliğini sağlamak için odağı ve pozlamayı mevcut duruma kilitler.
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
            print("Could not lock focus/exposure: \(error)")
        }
    }
    
    /// Captures a high-resolution photo asynchronously.
    /// Asenkron olarak yüksek çözünürlüklü bir fotoğraf yakalar.
    /// - Returns: A captured UIImage.
    func capturePhoto() async throws -> UIImage {
        // Briefly wait for lens mechanics, while still allowing scanner dismissal to cancel capture.
        try await Task.sleep(nanoseconds: 300_000_000)
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self, self.isSessionRunning, !self.isShuttingDown else {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                self.lockFocusAndExposure()

                let processor = PhotoCaptureProcessor(continuation: continuation)
                processor.onComplete = { [weak self] in
                    self?.sessionQueue.async { [weak self] in
                        self?.activeProcessor = nil
                    }
                }

                self.activeProcessor = processor

                let settings = AVCapturePhotoSettings()
                settings.maxPhotoDimensions = self.photoOutput.maxPhotoDimensions
                self.photoOutput.capturePhoto(with: settings, delegate: processor)
            }
        }
    }
}

/*
 SUMMARY:
 CameraService provides a high-level API for capturing high-quality photos suitable for OCR.
 It handles session management, torch control, and hardware-level focus locking.
 It is used by ScannerView to capture images of price tags.
 
 ÖZET:
 CameraService, OCR için uygun yüksek kaliteli fotoğraflar yakalamak için üst düzey bir API sağlar.
 Oturum yönetimini, fener kontrolünü ve donanım düzeyinde odak kilitlemeyi idare eder.
 Fiyat etiketlerinin görüntülerini yakalamak için ScannerView tarafından kullanılır.
 */
