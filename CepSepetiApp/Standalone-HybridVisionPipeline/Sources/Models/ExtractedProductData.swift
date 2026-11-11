//
//  ExtractedProductData.swift
//  HybridVisionPipeline
//

import Foundation

/// Represents structured data extracted from a physical price tag or label.
public struct ExtractedProductData: Codable, Sendable, Equatable {
    /// The detected name or title of the item.
    public let productName: String
    
    /// The detected price of the item.
    public let price: Decimal
    
    /// The detected brand of the item, if identified.
    public let brand: String?
    
    /// The raw, unprocessed OCR text from which this result was extracted.
    public let rawOCRText: String
    
    /// Confidence score of the extraction (ranging from 0.0 to 1.0).
    public var confidenceScore: Double?

    public init(
        productName: String,
        price: Decimal,
        brand: String? = nil,
        rawOCRText: String = "",
        confidenceScore: Double? = nil
    ) {
        self.productName = productName
        self.price = price
        self.brand = brand
        self.rawOCRText = rawOCRText
        self.confidenceScore = confidenceScore
    }
}
