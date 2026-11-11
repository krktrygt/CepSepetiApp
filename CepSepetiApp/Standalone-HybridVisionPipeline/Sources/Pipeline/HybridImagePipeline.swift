//
//  HybridImagePipeline.swift
//  HybridVisionPipeline
//

import Foundation
import UIKit
import Network

/// Coordinates image text recognition: runs Vision OCR, parses locally with regex,
/// and only calls the LLM if the local score is low.
public final class HybridImagePipeline: Sendable {

    private let ocrService: OCRService
    private let preflightValidator: OCRPreflightValidator
    private let localParser: LocalOCRParserService
    private let llmService: (any LLMServiceProtocol)?
    private let aiValidator: AIResultValidator
    public let localConfidenceThreshold: Double

    public init(
        ocrService: OCRService = OCRService(),
        preflightValidator: OCRPreflightValidator = OCRPreflightValidator(),
        localParser: LocalOCRParserService = LocalOCRParserService(),
        llmService: (any LLMServiceProtocol)? = nil,
        aiValidator: AIResultValidator = AIResultValidator(),
        localConfidenceThreshold: Double = 0.7
    ) {
        self.ocrService = ocrService
        self.preflightValidator = preflightValidator
        self.localParser = localParser
        self.llmService = llmService
        self.aiValidator = aiValidator
        self.localConfidenceThreshold = localConfidenceThreshold
    }

    public func process(image: UIImage) async throws -> PipelineResult {
        // 1. Run local Vision OCR
        let rawText = try await ocrService.recognizeText(from: image)

        // 2. Quick pre-check on text length and quality
        let preflight = preflightValidator.validate(rawText)
        guard preflight.canUseOCR else {
            throw PipelineError.textPreflightFailed(preflight.message ?? "Text quality is too low.")
        }

        // 3. Local regex & heuristics
        let localCandidate = localParser.parse(ocrText: rawText)
        let confidence = localCandidate.confidenceScore ?? 0.0

        // If local result is confident enough or no LLM is provided, return it
        if confidence >= localConfidenceThreshold || llmService == nil {
            return PipelineResult(
                data: localCandidate,
                source: .localHeuristic,
                needsReview: confidence < 0.5,
                warnings: confidence < 0.5 ? ["Low confidence local extraction."] : []
            )
        }

        // 4. Check internet connection before making an API call
        let isConnected = await checkConnection()
        guard isConnected, let llm = llmService else {
            return PipelineResult(
                data: localCandidate,
                source: .localOfflineFallback,
                needsReview: true,
                warnings: ["Offline or no LLM configured. Used local heuristics."]
            )
        }

        // 5. Ask LLM to extract or verify
        do {
            let aiResult = try await llm.analyze(rawText: rawText, localCandidate: localCandidate)
            let validation = aiValidator.validate(aiResult)

            guard validation.isAcceptable else {
                return PipelineResult(
                    data: localCandidate,
                    source: .localOfflineFallback,
                    needsReview: true,
                    warnings: validation.warnings
                )
            }

            return PipelineResult(
                data: aiResult,
                source: .cloudLLM,
                needsReview: validation.needsReview,
                warnings: validation.warnings
            )
        } catch {
            // If LLM fails, don't crash, fall back to what we found locally
            return PipelineResult(
                data: localCandidate,
                source: .localOfflineFallback,
                needsReview: true,
                warnings: ["LLM invocation failed: \(error.localizedDescription)"]
            )
        }
    }

    // MARK: - Network Check
    private func checkConnection() async -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "HybridVision.NetworkCheck")

        actor ContinuationManager {
            private var isResumed = false
            func resume(with status: Bool, continuation: CheckedContinuation<Bool, Never>) {
                guard !isResumed else { return }
                isResumed = true
                continuation.resume(returning: status)
            }
        }

        let manager = ContinuationManager()

        return await withCheckedContinuation { continuation in
            monitor.pathUpdateHandler = { path in
                let status = path.status == .satisfied
                monitor.cancel()
                Task {
                    await manager.resume(with: status, continuation: continuation)
                }
            }
            monitor.start(queue: queue)
        }
    }
}
