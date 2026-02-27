//
//  CameraPreviewView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import AVFoundation

// 1. UIKit'in kendi içindeki layer yönetimini ezen özel bir View sınıfı
class VideoPreviewView: UIView {
    // Bu View'in standart bir katman yerine kamera katmanı kullanmasını zorluyoruz
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        
        // Arka plan siyah olsun (Kamera açılana kadar sırıtmaması için)
        view.backgroundColor = .black
        
        // Session'ı katmana bağla ve ekranı orantılı doldurmasını söyle
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // UI güncellemeleri burada yapılır. (Şu an ihtiyacımız yok)
    }
}

#Preview {
    let session = AVCaptureSession()
    return CameraPreviewView(session: session)
}
