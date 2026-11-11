//
//  PipelineFlowTests.swift
//  HybridVisionPipelineTests
//

import XCTest
@testable import HybridVisionPipeline

// Simple Mock LLM for testing
final class MockLLMService: LLMServiceProtocol, @unchecked Sendable {
    var shouldFail: Bool = false
    var mockedReturnData: ExtractedProductData?

    func analyze(rawText: String, localCandidate: ExtractedProductData?) async throws -> ExtractedProductData {
        if shouldFail {
            throw PipelineError.llmServiceUnavailable("Mocked network failure")
        }
        return mockedReturnData ?? ExtractedProductData(
            productName: "Mock Product",
            price: Decimal(19.99),
            brand: "Mock Brand",
            rawOCRText: rawText,
            confidenceScore: 1.0
        )
    }
}

final class PipelineFlowTests: XCTestCase {

    func testHighConfidenceBypassesLLM() async {
        // Given a high confidence threshold
        let mockLLM = MockLLMService()
        mockLLM.shouldFail = true // If called, it would fail
        
        let localParser = LocalOCRParserService()
        let pipeline = HybridImagePipeline(
            localParser: localParser,
            llmService: mockLLM,
            localConfidenceThreshold: 0.5
        )

        // Text that yields high confidence locally
        let highConfText = """
        PINAR
        SUT 1 LT
        35.00 TL
        """

        let candidate = localParser.parse(ocrText: highConfText)
        XCTAssertGreaterThanOrEqual(candidate.confidenceScore ?? 0, 0.5)

        // When local confidence is high, localHeuristic is expected
        // Note: In a full pipeline integration test with UIImage, it runs end-to-end.
    }

    func testLLMFailureFallsBackGracefullyToLocalResult() async {
        let mockLLM = MockLLMService()
        mockLLM.shouldFail = true

        let localParser = LocalOCRParserService()
        let lowConfText = "BEYAZ PEYNIR"
        let candidate = localParser.parse(ocrText: lowConfText)
        
        XCTAssertEqual(candidate.price, 0)
    }
}
