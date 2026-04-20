//
//  GeminiService.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 20.04.2026.
//

import Foundation

final class GeminiService {
    
    // API Anahtarını plist'ten güvenli bir şekilde okuyan property
    private var apiKey: String {
        guard let filePath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let value = plist.object(forKey: "GEMINI_API_KEY") as? String,
              !value.isEmpty else {
            fatalError("HATA: Secrets.plist dosyası veya GEMINI_API_KEY bulunamadı!")
        }
        return value
    }
    
    // Gemini 2.5 Flash modelini kullanıyor
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    func parse(ocrText: String) async throws -> PriceTagData {
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw OCRError.parsingFailed
        }
        
        // LLM'i kısıtladığımız katı prompt (Sistem Komutu)
        let prompt = """
            Aşağıdaki metin bir market etiketinin OCR çıktısıdır. Görevin sadece asıl satış fiyatını ve ürünün adını bulmaktır.
            Kurallar:
            1. Birim fiyatlarını (örneğin 1kg=40TL veya adet=10TL gibi) ve barkod numaralarını yoksay.
            2. Fiyat alanında virgül kullanılmışsa bunu ondalık formatta noktaya çevir (Örn: 349,00 -> 349.00).
            3. Ürün adındaki küçük OCR harf hatalarını (örn: 'aktue!' -> 'aktüel') mantıklıysa düzelt. Markayı bulabiliyorsan yaz.
            4. Çıktıyı KESİNLİKLE VE SADECE aşağıdaki JSON formatında ver. Başka hiçbir açıklama, markdown veya kod bloğu ekleme:
            {"productName": "Ürün Adı", "price": 0.00, "brand": "Marka", "rawOCRText": "orijinal_metin"}
                
            OCR Metni:
            \(ocrText)
            """
        // Gemini API'nin beklediği Body formatı
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            // Çıktıyı zorla JSON formatında vermesini istiyoruz
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Ağ isteğini atıyoruz
        let (data, response) = try await URLSession.shared.data(for: request)
        
        
        // HATA AYIKLAMA (DEBUG) BLOĞU
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP Durum Kodu: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                // Eğer hata aldıysak, Google'ın gönderdiği JSON hata detayını string olarak bas
                let serverErrorMessage = String(data: data, encoding: .utf8) ?? "Mesaj okunamadı"
                print("🚨 GOOGLE API HATA DETAYI:\n\(serverErrorMessage)")
                throw OCRError.geminiError("Sunucu Hatası. Kod: \(httpResponse.statusCode)")
            }
        } else {
            throw OCRError.geminiError("Geçersiz sunucu yanıtı.")
        }

        
        // Gelen JSON verisini PriceTagData struct'ımıza dönüştürüyoruz
        do {
            // Gemini bazen JSON'ı "candidates" -> "content" -> "parts" -> "text" içinde string olarak döndürür.
            // Bu içiçe yapıyı açmamız gerekiyor.
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let candidates = json?["candidates"] as? [[String: Any]],
                    let content = candidates.first?["content"] as? [String: Any],
                    let parts = content["parts"] as? [[String: Any]],
                    let text = parts.first?["text"] as? String,
                    let finalData = text.data(using: .utf8) else {
                throw OCRError.parsingFailed
            }
                   
            var parsedData = try JSONDecoder().decode(PriceTagData.self, from: finalData)
            // Debug için orijinal metni de içine gömüyoruz
            parsedData = PriceTagData(productName: parsedData.productName,
                                        price: parsedData.price,
                                        brand: parsedData.brand,
                                        rawOCRText: ocrText)
            return parsedData
                   
        } catch {
            throw OCRError.geminiError("Gelen veri anlaşılamadı.")
        }
    }
    
}
