//
//  OCRService.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 19.04.2026.
//

import Foundation
import Vision
import UIKit

final class OCRService {
    
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.parsingFailed
        }
        
        // Ana thread'i dondurmamak için işlemimizi tamamen bağımsız (detached)
        // bir arka plan görevine atıyoruz.
        return try await Task.detached(priority: .userInitiated) {
            return try await withCheckedThrowingContinuation { continuation in
                
                // 1. DİKKAT: Vision objelerini DIŞARIDA değil, arka plan görevinin
                // tam İÇİNDE oluşturuyoruz. Böylece Sendable kuralını ihlal etmiyoruz.
                let request = VNRecognizeTextRequest { request, error in
                    // Apple çerçevesinden gelen dahili hatalar
                    if error != nil {
                        continuation.resume(throwing: OCRError.parsingFailed)
                        return
                    }
                    
                    // Sonuçların alınması ve boş olup olmadığının kontrolü
                    guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                        continuation.resume(throwing: OCRError.noTextFound)
                        return
                    }
                    
                    // Okunan metin kutularının (bounding boxes) içindeki en güvenilir (.topCandidates(1)) verileri string olarak çekiyoruz
                    let recognizedStrings = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }
                    
                    // Alt alta duran metinleri birleştirip tek bir metin bloğu haline getiriyoruz
                    let fullText = recognizedStrings.joined(separator: "\n")
                    
                    // Eğer sadece boşluklardan oluşan anlamsız bir şey döndüyse hata fırlat
                    if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        continuation.resume(throwing: OCRError.noTextFound)
                    } else {
                        continuation.resume(returning: fullText)
                    }
                }
                
                // Konfigürasyonlar
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["tr-TR", "en-US"]
                request.customWords = ["TL", "₺", "KDV", "Fiyatı", "Adet", "İndirim", "kg", "lt", "ml"]
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                // 2. Zaten Task.detached sayesinde arka planda olduğumuz için
                // tekrar DispatchQueue kullanmamıza gerek kalmıyor. Doğrudan çalıştırıyoruz.
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.parsingFailed)
                }
            }
        }.value
    }
}
