//
//  Shopping.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation
import SwiftData

/// A persistent data model representing a single item in a shopping cart.
/// Alışveriş sepetindeki tek bir öğeyi temsil eden kalıcı bir veri modeli.
@Model
final class ShoppingItem {
    /// The name of the product.
    /// Ürünün adı.
    var productName: String
    /// The brand of the product.
    /// Ürünün markası.
    var brand: String?
    /// The unit price of the product.
    /// Ürünün birim fiyatı.
    var price: Decimal
    /*
    /// The category the product belongs to (e.g., Beverage, Snacks).
    /// Ürünün ait olduğu kategori (örneğin, İçecek, Atıştırmalık).
    var category: String
    */
    /// The quantity of this item in the cart.
    /// Sepetteki bu öğenin miktarı.
    var quantity: Int
    /// The timestamp when the item was added.
    /// Öğenin eklendiği zaman damgası.
    var createdAt: Date
    var processingStatusRaw: String = ItemProcessingStatus.completed.rawValue
    var scanJobID: UUID?
    var capturedImagePath: String?
    var rawOCRText: String?
    var localProductName: String?
    var localBrand: String?
    var localPrice: Double?
    var aiConfidence: Double?
    var processingError: String?
    var retryCount: Int = 0
    var processingStartedAt: Date?
    var processingCompletedAt: Date?
    /// The shopping session this item belongs to.
    /// Bu öğenin ait olduğu alışveriş oturumu.
    var session: ShoppingSession?

    var processingStatus: ItemProcessingStatus {
        get {
            ItemProcessingStatus(rawValue: processingStatusRaw) ?? .failed
        }
        set {
            processingStatusRaw = newValue.rawValue
        }
    }

    /// Initializes a new ShoppingItem.
    /// Yeni bir ShoppingItem başlatır.
    /// - Parameters:
    ///   - productName: Name of the product.
    ///   - brand: Optional brand name.
    ///   - price: Price per unit.
    ///   // - category: Product category.
    ///   - quantity: Initial quantity.
    ///   - session: The parent shopping session.
    init(
        productName: String,
        brand: String? = nil,
        price: Decimal,
        /* category: String, */
        quantity: Int,
        processingStatus: ItemProcessingStatus = .completed,
        scanJobID: UUID? = nil,
        capturedImagePath: String? = nil,
        rawOCRText: String? = nil,
        localProductName: String? = nil,
        localBrand: String? = nil,
        localPrice: Double? = nil,
        aiConfidence: Double? = nil,
        processingError: String? = nil,
        retryCount: Int = 0,
        processingStartedAt: Date? = nil,
        processingCompletedAt: Date? = nil,
        session: ShoppingSession? = nil
    ) {
        self.productName = productName
        self.brand = brand
        self.price = price
        // self.category = category
        self.quantity = quantity
        self.createdAt = Date()
        self.processingStatusRaw = processingStatus.rawValue
        self.scanJobID = scanJobID
        self.capturedImagePath = capturedImagePath
        self.rawOCRText = rawOCRText
        self.localProductName = localProductName
        self.localBrand = localBrand
        self.localPrice = localPrice
        self.aiConfidence = aiConfidence
        self.processingError = processingError
        self.retryCount = retryCount
        self.processingStartedAt = processingStartedAt
        self.processingCompletedAt = processingCompletedAt
        self.session = session
    }
}

/*
 SUMMARY:
 ShoppingItem is a core SwiftData model representing a product added to a shopping list.
 it maintains properties like price and quantity, and holds a relationship to a ShoppingSession.
 It is managed by ViewModels to reflect current cart state.

 ÖZET:
 ShoppingItem, bir alışveriş listesine eklenen bir ürünü temsil eden temel bir SwiftData modelidir.
 Fiyat ve miktar gibi özellikleri korur ve bir ShoppingSession ile ilişki tutar.
 Mevcut sepet durumunu yansıtmak için ViewModel'ler tarafından yönetilir.
 */
