//
//  LLMServiceProtocol.swift
//  HybridVisionPipeline
//

import Foundation

/// Defines an abstract contract for calling an LLM (Cloud or On-Device) to parse and verify OCR text.
public protocol LLMServiceProtocol: Sendable {
    /// Analyzes the raw OCR text with optional guidance from local candidates.
    /// - Parameters:
    ///   - rawText: The full raw text recognized from the image.
    ///   - localCandidate: An optional candidate produced by local heuristic parser.
    /// - Returns: Clean, structured `ExtractedProductData`.
    func analyze(rawText: String, localCandidate: ExtractedProductData?) async throws -> ExtractedProductData
}
