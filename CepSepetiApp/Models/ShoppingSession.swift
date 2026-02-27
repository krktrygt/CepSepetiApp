//
//  ShoppingSession.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation
import SwiftData

@Model
final class ShoppingSession {
    var id: UUID
    var date: Date
    var totalAmount: Decimal
    var isComplated: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \ShoppingItem.session)
    var items: [ShoppingItem]?
    
    init(id: UUID, date: Date, totalAmount: Decimal, isComplated: Bool, items: [ShoppingItem]? = nil) {
        self.id = id
        self.date = date
        self.totalAmount = totalAmount
        self.isComplated = isComplated
        self.items = items
    }
}
