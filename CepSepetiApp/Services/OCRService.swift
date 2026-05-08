//
//  OCRService.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 19.04.2026.
//

import Foundation
import Vision
import UIKit

/// A service that uses Apple's Vision framework to perform Optical Character Recognition (OCR) locally on the device.
/// Cihaz üzerinde yerel olarak Optik Karakter Tanıma (OCR) gerçekleştirmek için Apple'ın Vision çerçevesini kullanan bir servis.
final class OCRService {
    
    /// Recognizes text from a given image using the Vision framework.
    /// Vision çerçevesini kullanarak verilen bir görüntüden metni tanır.
    /// - Parameter image: The source UIImage.
    /// - Returns: A single string containing all recognized text separated by newlines.
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.parsingFailed
        }
        
        // Execute the processing in a detached task to keep the main thread free and comply with concurrency rules.
        // Ana iş parçacığını serbest tutmak ve eşzamanlılık kurallarına uymak için işlemi bağımsız (detached) bir görevde yürütün.
        return try await Task.detached(priority: .userInitiated) {
            return try await withCheckedThrowingContinuation { continuation in
                
                // Initialize the text recognition request.
                // Metin tanıma isteğini başlatın.
                let request = VNRecognizeTextRequest { request, error in
                    if error != nil {
                        continuation.resume(throwing: OCRError.parsingFailed)
                        return
                    }
                    
                    // Filter and extract observations from the results.
                    // Sonuçlardan gözlemleri filtreleyin ve çıkarın.
                    guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                        continuation.resume(throwing: OCRError.noTextFound)
                        return
                    }
                    
                    // Map observations to their most likely string representations.
                    // Gözlemleri en olası dize temsilcileriyle eşleyin.
                    let recognizedStrings = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }
                    
                    let fullText = recognizedStrings.joined(separator: "\n")
                    
                    if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        continuation.resume(throwing: OCRError.noTextFound)
                    } else {
                        continuation.resume(returning: fullText)
                    }
                }
                
                // Configure request for high accuracy and specific languages.
                // İsteği yüksek doğruluk ve belirli diller için yapılandırın.
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["tr-TR", "en-US"]
                // Custom keywords to improve recognition of grocery-related terms.
                // Marketle ilgili terimlerin tanınmasını iyileştirmek için özel anahtar kelimeler.
                request.customWords = ["TL", "₺", "KDV", "Fiyatı", "Adet", "İndirim", "kg", "lt", "ml"]
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.parsingFailed)
                }
            }
        }.value
    }
}

/*
 SUMMARY:
 OCRService wraps the Vision framework's text recognition capabilities. 
 it provides a modern async/await interface for extracting text from images locally.
 It is the first step in the image processing pipeline.
 
 ÖZET:
 OCRService, Vision çerçevesinin metin tanıma yeteneklerini sarmalar.
 Görüntülerden yerel olarak metin çıkarmak için modern bir asenkron/bekleme (async/await) arayüzü sağlar.
 Görüntü işleme hattındaki ilk adımdır.
 */
