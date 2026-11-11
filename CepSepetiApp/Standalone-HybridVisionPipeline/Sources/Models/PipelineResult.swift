//
//  PipelineResult.swift
//  HybridVisionPipeline
//

import Foundation

/// Origin source of the parsed result.
public enum ResultSource: String, Codable, Sendable {
    case localHeuristic = "Local Heuristic"
    case cloudLLM = "Cloud LLM"
    case localOfflineFallback = "Local Offline Fallback"
    case manualEntry = "Manual Entry"
}

/// The final outcome of the end-to-end extraction pipeline.
public struct PipelineResult: Sendable {
    public let data: ExtractedProductData
    public let source: ResultSource
    public let needsReview: Bool
    public let warnings: [String]

    public init(
        data: ExtractedProductData,
        source: ResultSource,
        needsReview: Bool = false,
        warnings: [String] = []
    ) {
        self.data = data
        self.source = source
        self.needsReview = needsReview
        self.warnings = warnings
    }
}

/// Errors that may occur during the pipeline execution.
public enum PipelineError: Error, LocalizedError {
    case imageCorrupted
    case textPreflightFailed(String)
    case ocrRecognitionFailed
    case noTextFound
    case llmServiceUnavailable(String)
    case parsingFailed

    public var errorDescription: String? {
        switch self {
        case .imageCorrupted:
            return "Image could not be processed or converted."
        case .textPreflightFailed(let reason):
            return "Preflight validation failed: \(reason)"
        case .ocrRecognitionFailed:
            return "Apple Vision OCR failed to recognize text."
        case .noTextFound:
            return "No recognizable text found in the image."
        case .llmServiceUnavailable(let message):
            return "LLM service failed or unavailable: \(message)"
        case .parsingFailed:
            return "Failed to extract product details from text."
        }
    }
}
