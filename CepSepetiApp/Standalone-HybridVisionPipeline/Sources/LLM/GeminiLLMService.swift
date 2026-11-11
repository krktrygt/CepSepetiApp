//
//  GeminiLLMService.swift
//  HybridVisionPipeline
//

import Foundation

/// Concrete implementation of `LLMServiceProtocol` using Google's Gemini Flash model.
public final class GeminiLLMService: LLMServiceProtocol, Sendable {

    private let apiKeyProvider: @Sendable () throws -> String
    private let endpoint: String

    /// Initializes the Gemini service with an API key closure or hardcoded value.
    /// - Parameters:
    ///   - endpoint: Custom endpoint URL, defaulting to gemini-2.5-flash.
    ///   - apiKeyProvider: A closure returning the Gemini API Key.
    public init(
        endpoint: String = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
        apiKeyProvider: @escaping @Sendable () throws -> String
    ) {
        self.endpoint = endpoint
        self.apiKeyProvider = apiKeyProvider
    }

    public func analyze(rawText: String, localCandidate: ExtractedProductData?) async throws -> ExtractedProductData {
        let key = try apiKeyProvider()

        guard let url = URL(string: "\(endpoint)?key=\(key)") else {
            throw PipelineError.llmServiceUnavailable("Invalid endpoint URL")
        }

        let localCandidateText: String
        if let localCandidate {
            localCandidateText = """

                Local parser candidate:
                - productName: \(localCandidate.productName)
                - brand: \(localCandidate.brand ?? "unknown")
                - price: \(localCandidate.price)
                - confidence: \(localCandidate.confidenceScore ?? 0)
                """
        } else {
            localCandidateText = ""
        }

        let prompt = """
            The following text is OCR output from a supermarket price tag. Your task is to find only the actual selling price and the product name.
            Rules:
            1. Ignore unit prices (e.g., 1kg=40TL or unit=10TL) and barcode numbers.
            2. If commas are used in the price field, convert them to dots for decimal format (Ex: 349,00 -> 349.00).
            3. Correct minor OCR character errors in the product name (ex: 'aktue!' -> 'aktüel') if it makes sense. Write the brand if you can find it.
            4. Use the local parser candidate as context only. Correct it when the OCR text supports a better answer.
            5. Provide the output STRICTLY AND ONLY in the following JSON format. Do not add any other explanation, markdown, or code blocks:
            {"productName": "Product Name", "price": 0.00, "brand": "Brand", "rawOCRText": "original_text"}

            OCR Text:
            \(rawText)
            \(localCandidateText)
            """

        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PipelineError.llmServiceUnavailable("Invalid response type from server.")
        }

        guard httpResponse.statusCode == 200 else {
            let serverError = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw PipelineError.llmServiceUnavailable("HTTP \(httpResponse.statusCode): \(serverError)")
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let candidates = json?["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String,
                  let finalData = text.data(using: .utf8) else {
                throw PipelineError.parsingFailed
            }

            let decoded = try JSONDecoder().decode(ExtractedProductData.self, from: finalData)
            return ExtractedProductData(
                productName: decoded.productName,
                price: decoded.price,
                brand: decoded.brand,
                rawOCRText: rawText,
                confidenceScore: 1.0
            )
        } catch {
            throw PipelineError.parsingFailed
        }
    }
}
