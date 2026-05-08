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
        // Step 1: Physically crop the image to the central square to eliminate outside noise
        // Adım 1: Dışarıdaki gürültüyü ortadan kaldırmak için görüntüyü fiziksel olarak ortadaki kareye kırpın
        guard let croppedImage = cropToCenter(image: image),
              let cgImage = croppedImage.cgImage else {
            throw OCRError.parsingFailed
        }
        
        let orientation = cgImageOrientation(from: croppedImage.imageOrientation)
        
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
                
                // We pass the exact orientation so Vision reads the text upright.
                // Vision'ın metni dik okuması için tam yönü iletiyoruz.
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
                
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.parsingFailed)
                }
            }
        }.value
    }
    
    // MARK: - Helpers
    
    /// Physically crops a UIImage to a central square corresponding to the visual UI cutout.
    /// UIImage'i, UI'daki görsel kesite karşılık gelen ortadaki bir kareye fiziksel olarak kırpar.
    private func cropToCenter(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        // The visual cutout is 70% of screen width. Because of aspectFill camera zoom, 
        // a tighter crop (around 40% of the shortest side) maps accurately to that UI square.
        // Görsel kesit ekran genişliğinin %70'idir. AspectFill kamera yakınlaştırması nedeniyle,
        // daha dar bir kırpma (kısa kenarın yaklaşık %40'ı) UI karesiyle tam olarak eşleşir.
        let cropSize = min(width, height) * 0.4
        
        let x = (width - cropSize) / 2.0
        let y = (height - cropSize) / 2.0
        let cropRect = CGRect(x: x, y: y, width: cropSize, height: cropSize)
        
        if let croppedCgImage = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedCgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        return nil
    }
    
    /// Maps UIImage.Orientation to CGImagePropertyOrientation required by Vision.
    /// UIImage.Orientation'ı Vision tarafından istenen CGImagePropertyOrientation'a eşler.
    private func cgImageOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
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
