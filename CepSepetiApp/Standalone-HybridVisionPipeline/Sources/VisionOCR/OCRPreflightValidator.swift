//
//  OCRPreflightValidator.swift
//  HybridVisionPipeline
//

import Foundation

public struct OCRPreflightResult: Sendable {
    public let canUseOCR: Bool
    public let message: String?
}

/// Performs quick validation on raw OCR text to decide if it's worth processing further.
public final class OCRPreflightValidator: Sendable {
    private let priceLikeRegex = try! NSRegularExpression(
        pattern: #"(?<!\d)\d{1,5}([,.]\d{1,2})?(?!\d)"#,
        options: []
    )
    
    public init() {}
    
    public func validate(_ rawText: String) -> OCRPreflightResult {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return OCRPreflightResult(canUseOCR: false, message: "Etiket okunamadı. Lütfen daha net tekrar çekin.")
        }
        
        let alphanumericCount = trimmed.filter { $0.isLetter || $0.isNumber }.count
        guard alphanumericCount > 2 else {
            return OCRPreflightResult(canUseOCR: false, message: "Okunan metin çok kısa. Lütfen etiketi daha yakından tekrar çekin.")
        }
        
        let hasLetter = trimmed.contains { $0.isLetter }
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        let hasPriceLikeNumber = priceLikeRegex.firstMatch(in: trimmed, options: [], range: range) != nil
        
        if !hasLetter && !hasPriceLikeNumber {
            return OCRPreflightResult(canUseOCR: false, message: "Etikette ürün veya fiyat bilgisi okunamadı. Lütfen tekrar çekin.")
        }
        
        return OCRPreflightResult(canUseOCR: true, message: nil)
    }
}
