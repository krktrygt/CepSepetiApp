//
//  CameraService.swift
//  HybridVisionPipeline
//

import Foundation
import AVFoundation
import UIKit

/// A service that encapsulates AVCaptureSession to provide clean async/await photo capture.
public final class CameraService: NSObject, @unchecked Sendable {
    public let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "HybridVision.CameraSessionQueue", qos: .userInitiated)
    private var isSessionRunning = false
    private var isShuttingDown = false
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var activeProcessor: PhotoCaptureProcessor?
    
    public override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            session.commitConfiguration()
            return
        }
        
        self.videoDeviceInput = videoDeviceInput
        session.addInput(videoDeviceInput)
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            if let maxDimensions = videoDeviceInput.device.activeFormat.supportedMaxPhotoDimensions.last {
                photoOutput.maxPhotoDimensions = maxDimensions
            }
        }
        
        session.commitConfiguration()
    }
    
    public func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.isSessionRunning else { return }
            self.isShuttingDown = false
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
        }
    }
    
    public func stop(completion: (@Sendable () -> Void)? = nil) {
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
    
    public func toggleFlash(isOn: Bool) {
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
                // Log or handle torch error
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
            // Ignored
        }
    }
    
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
            // Ignored
        }
    }
    
    public func capturePhoto() async throws -> UIImage {
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
