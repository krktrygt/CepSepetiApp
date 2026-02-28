//
//  ProductResponse.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation

// API'den dönen en dıştaki JSON iskeleti
struct ProductResponse: Codable {
    let status: Int             // 1 ise ürün bulundu, 0 ise ürün bulunamadı
    let code: String?           // Barkod
    let product: ProductData?
}

struct ProductData: Codable {
    let productName: String?
    let brands: String?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case imageUrl = "image_url"
    }
}

