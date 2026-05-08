//
//  ProductResponse.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation

/// The root JSON structure returned by the OpenFoodFacts API when searching for a product by barcode.
/// Barkod ile ürün ararken OpenFoodFacts API tarafından döndürülen kök JSON yapısı.
struct ProductResponse: Codable {
    /// API status code: 1 if product is found, 0 otherwise.
    /// API durum kodu: Ürün bulunursa 1, aksi takdirde 0.
    let status: Int             
    /// The barcode of the product.
    /// Ürünün barkodu.
    let code: String?           
    /// Detailed product data, if available.
    /// Varsa ayrıntılı ürün verileri.
    let product: ProductData?
}

/// Detailed information about a product returned from the external API.
/// Harici API'den döndürülen bir ürün hakkında ayrıntılı bilgi.
struct ProductData: Codable {
    /// The name of the product.
    /// Ürünün adı.
    let productName: String?
    /// The brand or manufacturer of the product.
    /// Ürünün markası veya üreticisi.
    let brands: String?
    /// A URL pointing to an image of the product.
    /// Ürünün bir görüntüsüne işaret eden URL.
    let imageUrl: String?
    
    /// Maps API keys to Swift property names.
    /// API anahtarlarını Swift özellik adlarına eşler.
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case imageUrl = "image_url"
    }
}

/*
 SUMMARY:
 This file contains the data structures used for decoding responses from the OpenFoodFacts API.
 It is used by OpenFoodFactsService to provide product details based on a scanned barcode.
 
 ÖZET:
 Bu dosya, OpenFoodFacts API'den gelen yanıtları çözmek için kullanılan veri yapılarını içerir.
 Taranan bir barkoda göre ürün ayrıntılarını sağlamak için OpenFoodFactsService tarafından kullanılır.
 */
