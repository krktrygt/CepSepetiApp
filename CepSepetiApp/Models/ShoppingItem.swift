//
//  Shopping.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation
import SwiftData

@Model
final class ShoppingItem {
    var id: UUID
    var productName: String
    var brand: String?
    var price: Decimal
    var category: String
    var barcode: String
    var quantity: Int
    //var createdAt: Date
    // Inverse İlişki: Bu ürün hangi alışveriş oturumuna ait?
    var session: ShoppingSession?
    
    //init(id: UUID, productName: String, brand: String? = nil, price: Decimal, category: String, barcode: String, quantity: Int, createdAt: Date, session: ShoppingSession? = nil) {

    init(id: UUID, productName: String, brand: String? = nil, price: Decimal, category: String, barcode: String, quantity: Int, session: ShoppingSession? = nil) {
        self.id = id
        self.productName = productName
        self.brand = brand
        self.price = price
        self.category = category
        self.barcode = barcode
        self.quantity = quantity
        //self.createdAt = createdAt
        self.session = session
    }
}
