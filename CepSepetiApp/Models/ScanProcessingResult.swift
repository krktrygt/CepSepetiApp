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
    let validationWarnings: [String]

    init(
        productName: String,
        brand: String?,
        price: Decimal,
        rawOCRText: String,
        localResult: PriceTagData?,
        source: ResultSource,
        confidence: Double,
        needsReview: Bool,
        validationWarnings: [String] = []
    ) {
        self.productName = productName
        self.brand = brand
        self.price = price
        self.rawOCRText = rawOCRText
        self.localResult = localResult
        self.source = source
        self.confidence = confidence
        self.needsReview = needsReview
        self.validationWarnings = validationWarnings
    }
}
