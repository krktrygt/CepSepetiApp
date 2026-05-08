//
//  ImageProcessingPipeline.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 20.04.2026.
//

import Foundation
import UIKit
import Network

/// Orchestrates the end-to-end flow of capturing an image, extracting text, and analyzing it via AI.
/// Bir görüntüyü yakalama, metni çıkarma ve yapay zeka aracılığıyla analiz etme işlemlerinin uçtan uca akışını koordine eder.
final class ImageProcessingPipeline {
    
    private let ocrService = OCRService()
    private let geminiService = GeminiService()
    
    /// Processes an image: checks connectivity, performs OCR, and analyzes results with Gemini AI.
    /// Bir görüntüyü işler: bağlantıyı kontrol eder, OCR gerçekleştirir ve sonuçları Gemini AI ile analiz eder.
    /// - Parameter image: The source UIImage to process.
    /// - Returns: An OCRResult indicating success with data or failure with an error.
    func process(image: UIImage) async -> OCRResult {
        
        // Step 1: Check for internet connection as AI analysis requires it.
        // Adım 1: Yapay zeka analizi gerektirdiği için internet bağlantısını kontrol et.
        let isConnected = await checkConnection()
        guard isConnected else {
            return .failure(.networkUnavailable)
        }
        
        do {
            // Step 2: Extract text using local Vision framework OCR.
            // Adım 2: Yerel Vision çerçevesi OCR'ını kullanarak metni çıkar.
            let ocrText = try await ocrService.recognizeText(from: image)
            
            // Step 3: Send extracted text to Gemini AI for semantic analysis.
            // Adım 3: Çıkarılan metni anlamsal analiz için Gemini AI'ya gönder.
            let parsedResult = try await geminiService.parse(ocrText: ocrText)
            
            return .success(parsedResult)
            
        } catch let error as OCRError {
            return .failure(error)
        } catch {
            return .failure(.parsingFailed)
        }
    }

    /// Checks the device's internet connectivity status using NWPathMonitor.
    /// NWPathMonitor kullanarak cihazın internet bağlantı durumunu kontrol eder.
    /// - Returns: Boolean indicating whether internet is available.
    private func checkConnection() async -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkCheck")
        
        // Manager to ensure the continuation is resumed exactly once in a thread-safe manner.
        // Devamlılığın (continuation) iş parçacığı güvenli bir şekilde tam olarak bir kez sürdürülmesini sağlayan yönetici.
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
                monitor.cancel() 
                
                Task {
                    await manager.resume(with: status, continuation: continuation)
                }
            }
            monitor.start(queue: queue)
        }
    }
}

/*
 SUMMARY:
 ImageProcessingPipeline is the central coordinator for the app's OCR features.
 It chains together OCRService (local vision) and GeminiService (cloud AI) while 
 ensuring environmental requirements like network connectivity are met.
 
 ÖZET:
 ImageProcessingPipeline, uygulamanın OCR özellikleri için merkezi koordinatördür.
 Ağ bağlantısı gibi çevresel gereksinimlerin karşılanmasını sağlarken, OCRService (yerel vizyon) ve 
 GeminiService'i (bulut yapay zeka) birbirine bağlar.
 */
