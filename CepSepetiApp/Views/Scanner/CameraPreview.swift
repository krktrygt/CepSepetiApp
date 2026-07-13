//
//  CameraPreview.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import AVFoundation

/// A SwiftUI wrapper for UIKit's AVCaptureVideoPreviewLayer to provide a live camera feed.
/// Canlı bir kamera akışı sağlamak için UIKit'in AVCaptureVideoPreviewLayer'ı için bir SwiftUI sarmalayıcısı.
struct CameraPreview: UIViewRepresentable {
    /// The service providing the AVCaptureSession.
    /// AVCaptureSession'ı sağlayan servis.
    let cameraService: CameraService

    /// A custom UIView that hosts the AVCaptureVideoPreviewLayer.
    /// AVCaptureVideoPreviewLayer'ı barındıran özel bir UIView.
    class VideoPreviewView: UIView {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            configureView()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configureView()
        }

        private func configureView() {
            clipsToBounds = true
            backgroundColor = .black
            isUserInteractionEnabled = false
            videoPreviewLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(videoPreviewLayer)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            videoPreviewLayer.frame = bounds
            CATransaction.commit()
        }
    }

    /// Creates and configures the UIKit view.
    /// UIKit görünümünü oluşturur ve yapılandırır.
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()

        // Connect the session to the preview layer for rendering.
        // Oluşturma (rendering) için oturumu önizleme katmanına bağlayın.
        view.videoPreviewLayer.session = cameraService.session

        return view
    }

    /// Updates the view when state changes (unused but required by protocol).
    /// Durum değiştiğinde görünümü günceller (kullanılmıyor ancak protokol tarafından gerekli).
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.setNeedsLayout()
    }

    static func dismantleUIView(_ uiView: VideoPreviewView, coordinator: ()) {
        uiView.videoPreviewLayer.session = nil
        uiView.videoPreviewLayer.removeFromSuperlayer()
    }
}

/*
 SUMMARY:
 CameraPreview bridges UIKit and SwiftUI to display a live camera stream.
 It leverages the performance of AVCaptureVideoPreviewLayer to show the camera feed
 directly within the SwiftUI-based ScannerView.

 ÖZET:
 CameraPreview, canlı bir kamera akışını görüntülemek için UIKit ve SwiftUI arasında köprü kurar.
 Kamera akışını doğrudan SwiftUI tabanlı ScannerView içinde göstermek için AVCaptureVideoPreviewLayer'ın performansından yararlanır.
 */
