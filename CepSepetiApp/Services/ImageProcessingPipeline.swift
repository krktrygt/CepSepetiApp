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
    private let localParserService = LocalOCRParserService()
    
    // Threshold below which we fallback to Gemini
    private let confidenceThreshold: Double = 0.7
    
    /// Processes an image: checks connectivity, performs OCR, and analyzes results with Gemini AI.
    /// Bir görüntüyü işler: bağlantıyı kontrol eder, OCR gerçekleştirir ve sonuçları Gemini AI ile analiz eder.
    /// - Parameter image: The source UIImage to process.
    /// - Returns: An OCRResult indicating success with data or failure with an error.
    func process(image: UIImage) async -> OCRResult {
        
        do {
            // Step 1: Extract text using local Vision framework OCR.
            // Adım 1: Yerel Vision çerçevesi OCR'ını kullanarak metni çıkar.
            let ocrText = try await ocrService.recognizeText(from: image)
            
            print("\n📝 --- RAW OCR TEXT ---")
            print(ocrText)
            print("------------------------\n")
            
            // Step 2: Use Local Parser as primary extractor
            // Adım 2: Yerel Ayrıştırıcıyı birincil çıkarıcı olarak kullan
            let localResult = localParserService.parse(ocrText: ocrText)
            let confidence = localResult.confidenceScore ?? 0.0
            
            print("🔍 Local Parser Confidence: \(confidence)")
            
            if confidence >= confidenceThreshold {
                print("✅ Using Local Parser Result:")
                print("   Product: \(localResult.productName)")
                print("   Brand: \(localResult.brand ?? "None")")
                print("   Price: \(localResult.price)\n")
                return .success(localResult)
            }
            
            // Step 3: Fallback to Gemini if local confidence is low
            // Adım 3: Yerel güven düşükse Gemini'ye geri dön (fallback)
            let isConnected = await checkConnection()
            guard isConnected else {
                // Even with low confidence, returning local result is better than failing completely without network
                print("⚠️ Low confidence (\(confidence)), but no network. Using Local Result.")
                return .success(localResult)
            }
            
            print("☁️ Falling back to Gemini AI due to low confidence...")
            let parsedResult = try await geminiService.parse(ocrText: ocrText)
            
            print("✅ Using Gemini AI Result:")
            print("   Product: \(parsedResult.productName)")
            print("   Brand: \(parsedResult.brand ?? "None")")
            print("   Price: \(parsedResult.price)\n")
            
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
