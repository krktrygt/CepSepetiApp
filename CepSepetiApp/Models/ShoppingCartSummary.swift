//
//  ShoppingCartSummary.swift
//  CepSepetiApp
//

import Foundation

struct ShoppingCartSummary {
    let confirmedTotal: Decimal
    let estimatedTotal: Decimal?
    let completedCount: Int
    let queuedCount: Int
    let processingCount: Int
    let needsReviewCount: Int
    let failedCount: Int
    
    var hasPendingAnalysis: Bool {
        queuedCount > 0 || processingCount > 0
    }
    
    var hasBlockingItems: Bool {
        hasPendingAnalysis || needsReviewCount > 0 || failedCount > 0
    }
    
    var canFinalize: Bool {
        completedCount > 0 && !hasBlockingItems
    }
    
    var statusSummaryText: String? {
        var parts: [String] = []
        let analyzing = queuedCount + processingCount
        if analyzing > 0 {
            parts.append("\(analyzing) ürün analiz ediliyor")
        }
        if needsReviewCount > 0 {
            parts.append("\(needsReviewCount) ürün kontrol bekliyor")
        }
        if failedCount > 0 {
            parts.append("\(failedCount) ürün eklenemedi")
        }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
    
    static func make(items: [ShoppingItem]) -> ShoppingCartSummary {
        var confirmedTotal: Decimal = 0
        var estimatedTotal: Decimal = 0
        var hasEstimate = false
        var completedCount = 0
        var queuedCount = 0
        var processingCount = 0
        var needsReviewCount = 0
        var failedCount = 0
        
        for item in items {
            switch item.processingStatus {
            case .completed:
                let lineTotal = item.price * Decimal(item.quantity)
                confirmedTotal += lineTotal
                estimatedTotal += lineTotal
                hasEstimate = true
                completedCount += 1
            case .queued:
                queuedCount += 1
                if let localPrice = item.localPrice, localPrice > 0 {
                    estimatedTotal += Decimal(localPrice) * Decimal(item.quantity)
                    hasEstimate = true
                }
            case .processing:
                processingCount += 1
                if let localPrice = item.localPrice, localPrice > 0 {
                    estimatedTotal += Decimal(localPrice) * Decimal(item.quantity)
                    hasEstimate = true
                }
            case .needsReview:
                needsReviewCount += 1
                let estimate = item.price > 0 ? item.price : Decimal(item.localPrice ?? 0)
                if estimate > 0 {
                    estimatedTotal += estimate * Decimal(item.quantity)
                    hasEstimate = true
                }
            case .failed:
                failedCount += 1
            }
        }
        
        return ShoppingCartSummary(
            confirmedTotal: confirmedTotal,
            estimatedTotal: hasEstimate ? estimatedTotal : nil,
            completedCount: completedCount,
            queuedCount: queuedCount,
            processingCount: processingCount,
            needsReviewCount: needsReviewCount,
            failedCount: failedCount
        )
    }
}
