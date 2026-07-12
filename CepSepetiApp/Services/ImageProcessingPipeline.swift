//
//  ImageProcessingPipeline.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 20.04.2026.
//

import Foundation
import UIKit
import Network
import SwiftData

/// Orchestrates the end-to-end flow of capturing an image, extracting text, and analyzing it via AI.
/// Bir görüntüyü yakalama, metni çıkarma ve yapay zeka aracılığıyla analiz etme işlemlerinin uçtan uca akışını koordine eder.
final class ImageProcessingPipeline {

    private let ocrService = OCRService()
    private let geminiService = GeminiService()
    private let localParserService = LocalOCRParserService()

    /// Processes an image: checks connectivity, performs OCR, and analyzes results with Gemini AI.
    /// Bir görüntüyü işler: bağlantıyı kontrol eder, OCR gerçekleştirir ve sonuçları Gemini AI ile analiz eder.
    /// - Parameters:
    ///   - image: The source UIImage to process.
    ///   - context: The SwiftData ModelContext for logging.
    /// - Returns: An OCRResult indicating success with data or failure with an error.
    func process(image: UIImage, context: ModelContext) async -> OCRResult {
        do {
            let scanResult = try await processScan(image: image, context: context)
            let data = PriceTagData(
                productName: scanResult.productName,
                price: scanResult.price,
                brand: scanResult.brand,
                rawOCRText: scanResult.rawOCRText,
                confidenceScore: scanResult.confidence
            )

            switch scanResult.source {
            case .ai, .manual:
                return .success(data)
            case .localOffline:
                return .localFallback(data)
            }
        } catch let error as OCRError {
            return .failure(error)
        } catch {
            return .failure(.parsingFailed)
        }
    }

    func processScan(image: UIImage, context: ModelContext) async throws -> ScanProcessingResult {

        var rawText: String = ""

        do {
            // Step 1: Extract text using local Vision framework OCR.
            // Adım 1: Yerel Vision çerçevesi OCR'ını kullanarak metni çıkar.
            rawText = try await ocrService.recognizeText(from: image)

            print("\n📝 --- RAW OCR TEXT ---")
            print(rawText)
            print("------------------------\n")

            // Step 2: Use Local Parser as a fast candidate producer.
            // Adım 2: Yerel Ayrıştırıcıyı hızlı aday üretici olarak kullan.
            let localResult = localParserService.parse(ocrText: rawText)
            let confidence = localResult.confidenceScore ?? 0.0

            print("🔍 Local Parser Confidence: \(confidence)")

            // Step 3: Use AI as the final verifier whenever network is available.
            // Adım 3: İnternet varsa nihai doğrulayıcı olarak AI kullan.
            let isConnected = await checkConnection()
            guard isConnected else {
                print("⚠️ No network. Using Local Parser Result.")

                logOCR(rawText: rawText, success: false, context: context)

                return ScanProcessingResult(
                    productName: localResult.productName,
                    brand: localResult.brand,
                    price: localResult.price,
                    rawOCRText: rawText,
                    localResult: localResult,
                    source: .localOffline,
                    confidence: confidence,
                    needsReview: true
                )
            }

            print("☁️ Sending OCR and local candidate to Gemini AI...")
            do {
                let parsedResult = try await geminiService.parse(ocrText: rawText, localCandidate: localResult)

                print("✅ Using Gemini AI Result:")
                print("   Product: \(parsedResult.productName)")
                print("   Brand: \(parsedResult.brand ?? "None")")
                print("   Price: \(parsedResult.price)\n")

                logOCR(rawText: rawText, success: true, context: context)

                return ScanProcessingResult(
                    productName: parsedResult.productName,
                    brand: parsedResult.brand,
                    price: parsedResult.price,
                    rawOCRText: rawText,
                    localResult: localResult,
                    source: .ai,
                    confidence: parsedResult.confidenceScore ?? 1.0,
                    needsReview: false
                )
            } catch {
                print("⚠️ Gemini AI failed. Error: \(error.localizedDescription)")
                print("🚀 Falling back to Local Parser Result as a safety measure.")

                logOCR(rawText: rawText, success: false, context: context)

                return ScanProcessingResult(
                    productName: localResult.productName,
                    brand: localResult.brand,
                    price: localResult.price,
                    rawOCRText: rawText,
                    localResult: localResult,
                    source: .localOffline,
                    confidence: confidence,
                    needsReview: true
                )
            }

        } catch let error as OCRError {
            logOCR(rawText: rawText, success: false, context: context)
            throw error
        } catch {
            logOCR(rawText: rawText, success: false, context: context)
            throw OCRError.parsingFailed
        }
    }

    /// Logs the OCR attempt to SwiftData.
    /// OCR girişimini SwiftData'ya kaydeder.
    private func logOCR(rawText: String, success: Bool, context: ModelContext) {
        let log = OCRLog(rawText: rawText, success: success)
        context.insert(log)
        try? context.save()
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
