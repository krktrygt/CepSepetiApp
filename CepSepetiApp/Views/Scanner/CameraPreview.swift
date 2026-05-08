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
        // Specify that the main layer of this view should be a preview layer.
        // Bu görünümün ana katmanının bir önizleme katmanı (preview layer) olması gerektiğini belirtin.
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        /// Accesses the underlying layer cast as AVCaptureVideoPreviewLayer.
        /// AVCaptureVideoPreviewLayer olarak atanmış (cast) temel katmana erişir.
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    /// Creates and configures the UIKit view.
    /// UIKit görünümünü oluşturur ve yapılandırır.
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        
        // Connect the session to the preview layer for rendering.
        // Oluşturma (rendering) için oturumu önizleme katmanına bağlayın.
        view.videoPreviewLayer.session = cameraService.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        return view
    }
    
    /// Updates the view when state changes (unused but required by protocol).
    /// Durum değiştiğinde görünümü günceller (kullanılmıyor ancak protokol tarafından gerekli).
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
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
