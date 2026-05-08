//
//  PriceTagData.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 19.04.2026.
//

import Foundation

/// Represents the structured data extracted from a physical price tag using OCR.
/// OCR kullanılarak fiziksel bir fiyat etiketinden çıkarılan yapılandırılmış verileri temsil eder.
struct PriceTagData: Codable {
    /// The name of the product identified from the price tag.
    /// Fiyat etiketinden tanımlanan ürünün adı.
    let productName: String
    /// The price of the product.
    /// Ürünün fiyatı.
    let price: Decimal
    /// The brand of the product, if identifiable.
    /// Tanımlanabiliyorsa ürünün markası.
    let brand: String?
    /// The original, unprocessed text captured by the OCR system (used for debugging).
    /// OCR sistemi tarafından yakalanan orijinal, işlenmemiş metin (hata ayıklama için kullanılır).
    let rawOCRText: String
    /// The confidence score of the parsing result (0.0 to 1.0).
    /// Ayrıştırma sonucunun güven puanı (0.0 ile 1.0 arası).
    var confidenceScore: Double?
}

/*
 SUMMARY:
 PriceTagData is a data model used to store the results of price tag analysis.
 It is populated by the GeminiService after processing an image and is used by 
 the AddItemViewModel to prepopulate the product addition form.
 
 ÖZET:
 PriceTagData, fiyat etiketi analizinin sonuçlarını saklamak için kullanılan bir veri modelidir.
 Bir görüntüyü işledikten sonra GeminiService tarafından doldurulur ve AddItemViewModel tarafından 
 ürün ekleme formunu önceden doldurmak için kullanılır.
 */
