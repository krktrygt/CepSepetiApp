//
//  AIResultValidator.swift
//  HybridVisionPipeline
//

import Foundation

public struct AIValidationResult: Sendable {
    public let isAcceptable: Bool
    public let needsReview: Bool
    public let warnings: [String]
}

/// Validates LLM outputs to detect hallucinations, invalid numbers, or malformed product names.
public final class AIResultValidator: Sendable {
    private let maxReasonablePrice = Decimal(100_000)
    
    public init() {}
    
    public func validate(_ result: ExtractedProductData) -> AIValidationResult {
        var warnings: [String] = []
        var isAcceptable = true
        var needsReview = false
        
        let productName = result.productName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerName = productName.lowercased(with: Locale(identifier: "tr-TR"))
        
        if productName.isEmpty {
            warnings.append("Ürün adı boş.")
            isAcceptable = false
            needsReview = true
        } else if productName.allSatisfy({ $0.isNumber || $0.isWhitespace }) {
            warnings.append("Ürün adı yalnızca rakamlardan oluşuyor.")
            isAcceptable = false
            needsReview = true
        } else if productName.count < 3 {
            warnings.append("Ürün adı çok kısa.")
            needsReview = true
        }
        
        let invalidNameFragments = ["error", "exception", "json", "undefined", "null", "api key"]
        if invalidNameFragments.contains(where: { lowerName.contains($0) }) {
            warnings.append("Ürün adı API hata metni veya JSON artığı gibi görünüyor.")
            isAcceptable = false
            needsReview = true
        }
        
        if result.price <= 0 {
            warnings.append("Fiyat sıfır veya negatif.")
            isAcceptable = false
            needsReview = true
        } else if result.price > maxReasonablePrice {
            warnings.append("Fiyat beklenen üst sınırın üzerinde.")
            isAcceptable = false
            needsReview = true
        }
        
        let priceDouble = NSDecimalNumber(decimal: result.price).doubleValue
        if priceDouble.isNaN || priceDouble.isInfinite {
            warnings.append("Fiyat geçerli bir sayı değil.")
            isAcceptable = false
            needsReview = true
        }
        
        if (result.brand?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true), !productName.isEmpty {
            warnings.append("Marka bulunamadı.")
            needsReview = true
        }
        
        return AIValidationResult(
            isAcceptable: isAcceptable,
            needsReview: needsReview,
            warnings: warnings
        )
    }
}
