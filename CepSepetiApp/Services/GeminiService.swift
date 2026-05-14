//
//  GeminiService.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 20.04.2026.
//

import Foundation

/// Custom error types for Gemini Service.
/// Gemini Servisi için özel hata türleri.
enum GeminiError: Error {
    case missingAPIKey
    case networkError(String)
    case invalidResponse
    case parsingFailed
}

/// A service that interacts with Google's Gemini AI API to analyze and parse OCR text into structured data.
/// OCR metnini analiz etmek ve yapılandırılmış verilere ayrıştırmak için Google'ın Gemini AI API'si ile etkileşime giren bir servis.
final class GeminiService {
    
    /// Retrieves the Gemini API key from the Secrets.plist file.
    /// Gemini API anahtarını Secrets.plist dosyasından alır.
    private func getApiKey() throws -> String {
        guard let filePath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let value = plist.object(forKey: "GEMINI_API_KEY") as? String,
              !value.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        return value
    }
    
    /// The API endpoint for the Gemini 2.5 Flash model.
    /// Gemini 2.5 Flash modeli için API uç noktası.
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    /// Sends OCR text to the Gemini AI and parses the response into a PriceTagData object.
    /// OCR metnini Gemini AI'ya gönderir ve yanıtı bir PriceTagData nesnesine ayrıştırır.
    /// - Parameter ocrText: The raw text extracted from an image.
    /// - Returns: A structured PriceTagData object.
    func parse(ocrText: String) async throws -> PriceTagData {
        let key = try getApiKey()
        
        guard let url = URL(string: "\(endpoint)?key=\(key)") else {
            throw GeminiError.invalidResponse
        }
        
        // Detailed prompt to guide the LLM to extract product name, price, and brand in a strict JSON format.
        // LLM'in ürün adını, fiyatını ve markasını katı bir JSON formatında çıkarmasını sağlamak için ayrıntılı prompt.
        let prompt = """
            The following text is OCR output from a supermarket price tag. Your task is to find only the actual selling price and the product name.
            Rules:
            1. Ignore unit prices (e.g., 1kg=40TL or unit=10TL) and barcode numbers.
            2. If commas are used in the price field, convert them to dots for decimal format (Ex: 349,00 -> 349.00).
            3. Correct minor OCR character errors in the product name (ex: 'aktue!' -> 'aktüel') if it makes sense. Write the brand if you can find it.
            4. Provide the output STRICTLY AND ONLY in the following JSON format. Do not add any other explanation, markdown, or code blocks:
            {"productName": "Product Name", "price": 0.00, "brand": "Brand", "rawOCRText": "original_text"}
                
            OCR Text:
            \(ocrText)
            """
        
        // Define the request body format expected by the Gemini API.
        // Gemini API tarafından beklenen istek gövdesi formatını tanımlayın.
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
        
        // Execute the network request.
        // Ağ isteğini gerçekleştirin.
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debugging block for HTTP response status.
        // HTTP yanıt durumu için hata ayıklama bloğu.
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let serverErrorMessage = String(data: data, encoding: .utf8) ?? "Mesaj okunamadı"
                print("🚨 GOOGLE API ERROR DETAIL:\n\(serverErrorMessage)")
                throw GeminiError.networkError("Sunucu Hatası. Kod: \(httpResponse.statusCode)")
            }
        } else {
            throw GeminiError.invalidResponse
        }

        // Parse the hierarchical JSON response from Gemini into PriceTagData.
        // Gemini'den gelen hiyerarşik JSON yanıtını PriceTagData'ya ayrıştırın.
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let candidates = json?["candidates"] as? [[String: Any]],
                    let content = candidates.first?["content"] as? [String: Any],
                    let parts = content["parts"] as? [[String: Any]],
                    let text = parts.first?["text"] as? String,
                    let finalData = text.data(using: .utf8) else {
                throw GeminiError.parsingFailed
            }
                   
            var parsedData = try JSONDecoder().decode(PriceTagData.self, from: finalData)
            // Re-embed the original OCR text for debugging purposes.
            // Hata ayıklama amacıyla orijinal OCR metnini yeniden gömün.
            parsedData = PriceTagData(productName: parsedData.productName,
                                        price: parsedData.price,
                                        brand: parsedData.brand,
                                        rawOCRText: ocrText,
                                        confidenceScore: 1.0) // AI parsing implies high confidence if successful
            return parsedData
                   
        } catch {
            throw GeminiError.parsingFailed
        }
    }
}

/*
 SUMMARY:
 GeminiService acts as the intelligence layer of the app. It uses Large Language Models to transform 
 messy OCR text into clean, structured data. It defines the prompting logic and handles API communication.
 It is orchestrated by ImageProcessingPipeline.
 
 ÖZET:
 GeminiService, uygulamanın zeka katmanı olarak görev yapar. Karışık OCR metnini temiz, yapılandırılmış verilere 
 dönüştürmek için Büyük Dil Modellerini (LLM) kullanır. Prompt mantığını tanımlar ve API iletişimini yönetir.
 ImageProcessingPipeline tarafından koordine edilir.
 */
