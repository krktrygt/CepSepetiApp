//
//  CameraPreview.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let cameraService: CameraService
    
    // Apple'ın AVFoundation için önerdiği özel UIView alt sınıfı
    class VideoPreviewView: UIView {
        // Bu View'un ana katmanının standart bir layer değil,
        // VideoPreviewLayer olacağını iOS'e söylüyoruz.
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        
        // Session'ı doğrudan bu özel katmana bağlıyoruz
        view.videoPreviewLayer.session = cameraService.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // Artık boyut güncellemeleriyle uğraşmamıza gerek yok.
        // View kendi boyutunu otomatik olarak kamera katmanına uydurur.
    }
}


/*
#Preview {
    let session = AVCaptureSession()
    return CameraPreviewView(session: session)
}
*/

