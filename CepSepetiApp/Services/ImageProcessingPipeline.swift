//
//  ImageProcessingPipeline.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 20.04.2026.
//

import Foundation
import UIKit
import Network

final class ImageProcessingPipeline {
    
    private let ocrService = OCRService()
    private let geminiService = GeminiService()
    
    /// Görseli alır, ağ kontrolü yapar, OCR'dan geçirir ve yapay zekaya yorumlatır.
    func process(image: UIImage) async -> OCRResult {
        
        let isConnected = await checkConnection()
        guard isConnected else {
            return .failure(.networkUnavailable)
        }
        
        do {
            // Metni ayıkla
            let ocrText = try await ocrService.recognizeText(from: image)
            // Not: OCRService zaten metin bulamazsa kendi içinde error fırlatıyor,
            // bu yüzden catch bloğuna düşecek ve gereksiz Gemini isteği atılmayacak
            
            // Yapay zeka analizi
            let parsedResult = try await geminiService.parse(ocrText: ocrText)
            
            // Başarı
            return .success(parsedResult)
            
        } catch let error as OCRError {
            // Bizim tanımladığımız hatalar (İnternet yok, metin bulunamadı vb.)
            return .failure(error)
        } catch {
            // Bilinmeyen sistem hataları
            return .failure(.parsingFailed)
        }
    }
    // Apple'ın yerleşik kütüphanesiyle çalışan basit bir anlık internet kontrolcüsü
    private func checkConnection() async -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkCheck")
        
        // Swift 6 Strict Concurrency: Veri yarışını engellemek için Actor kullanıyoruz.
        // Continuation sadece bir kez tetiklenebilir, aksi halde uygulama çöker.
        actor ContinuationManager {
            private var isResumed = false
            
            func resume(with status: Bool, continuation: CheckedContinuation<Bool, Never>) {
                guard !isResumed else { return }
                isResumed = true
                continuation.resume(returning: status)
            }
        }
        
        let manager = ContinuationManager()
        
        return await withCheckedContinuation { continuation in
            monitor.pathUpdateHandler = { path in
                let status = path.status == .satisfied
                monitor.cancel() // İlk yanıtı aldık, dinlemeyi durdur
                
                // Actor'e asenkron olarak erişip continuation'ı güvenle tetikliyoruz
                Task {
                    await manager.resume(with: status, continuation: continuation)
                }
            }
            monitor.start(queue: queue)
        }
    }
}
