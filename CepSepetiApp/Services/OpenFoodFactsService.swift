//
//  OpenFoodFactsService.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation

final class OpenFoodFactsService{
    // Singleton deseni (Uygulama boyunca tek bir instance kullanmak için)
    static let shared = OpenFoodFactsService()
    
    private init() {} // Dışarıdan yeni instance oluşturulmasını engeller
    
    func fetchProduct(barcode: String) async throws -> ProductData? {
        // URL oluştur
        let urlString = "https://world.openfoodfacts.org/api/v1/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // İnternete çık ve veriyi indir (Asenkron bekleme noktası)
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Sunucu cevabını kontrol et (200 OK geldi mi?)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Eğer sunucu açıkça "Bulamadım" (404) diyorsa, hata fırlatma, sadece nil döndür
        if httpResponse.statusCode == 404 {
            return nil
        }
        
        // 200 dışında başka kritik bir sunucu hatası varsa (Örn: 500) o zaman hata fırlat
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Gelen JSON verisini modele dönüştür
        let decoder = JSONDecoder()
        let result = try decoder.decode(ProductResponse.self, from: data)
        
        // Eğer status 1 ise (Ürün bulunduysa) ürünü döndür, yoksa nil döndür
        if result.status == 1 {
            return result.product
        } else {
            return nil // Ürün veritabanında yok
        }
        
    }
}
