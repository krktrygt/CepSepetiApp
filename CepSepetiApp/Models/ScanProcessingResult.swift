//
//  ScanProcessingResult.swift
//  CepSepetiApp
//

import Foundation

struct ScanProcessingResult {
    let productName: String
    let brand: String?
    let price: Decimal
    let rawOCRText: String
    let localResult: PriceTagData?
    let source: ResultSource
    let confidence: Double
    let needsReview: Bool
}
