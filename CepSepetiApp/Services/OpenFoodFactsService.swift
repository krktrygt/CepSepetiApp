//
//  OpenFoodFactsService.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation

/// A service that fetches product details from the Open Food Facts database using barcode numbers.
/// Barkod numaralarını kullanarak Open Food Facts veritabanından ürün ayrıntılarını getiren bir servis.
final class OpenFoodFactsService {
    /// Shared singleton instance for application-wide access.
    /// Uygulama genelinde erişim için paylaşılan singleton örneği.
    static let shared = OpenFoodFactsService()
    
    private init() {} 
    
    /// Fetches product data for a given barcode from the Open Food Facts API.
    /// Open Food Facts API'sinden verilen bir barkod için ürün verilerini getirir.
    /// - Parameter barcode: The barcode string (e.g., EAN-13).
    /// - Returns: ProductData if found, nil otherwise.
    func fetchProduct(barcode: String) async throws -> ProductData? {
        let urlString = "https://world.openfoodfacts.org/api/v1/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // Perform the network request asynchronously.
        // Ağ isteğini asenkron olarak gerçekleştirin.
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Handle 'Not Found' status gracefully.
        // 'Bulunamadı' durumunu zarif bir şekilde idare edin.
        if httpResponse.statusCode == 404 {
            return nil
        }
        
        // Ensure the response is successful.
        // Yanıtın başarılı olduğundan emin olun.
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Decode the JSON response into the ProductResponse model.
        // JSON yanıtını ProductResponse modeline çözün.
        let decoder = JSONDecoder()
        let result = try decoder.decode(ProductResponse.self, from: data)
        
        // Return product details if found.
        // Bulunursa ürün ayrıntılarını döndürün.
        if result.status == 1 {
            return result.product
        } else {
            return nil 
        }
    }
}

/*
 SUMMARY:
 OpenFoodFactsService provides integration with an external product database.
 It allows the app to automatically retrieve product names and brands when a barcode is scanned,
 reducing manual data entry for the user.
 
 ÖZET:
 OpenFoodFactsService, harici bir ürün veritabanıyla entegrasyon sağlar.
 Uygulamanın bir barkod tarandığında ürün adlarını ve markalarını otomatik olarak almasını sağlayarak 
 kullanıcı için manuel veri girişini azaltır.
 */
