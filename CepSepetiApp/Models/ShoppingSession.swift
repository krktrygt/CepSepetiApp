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
    var isCompleted: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \ShoppingItem.session)
    var items: [ShoppingItem]?
    
    init(id: UUID, date: Date, totalAmount: Decimal, isCompleted: Bool, items: [ShoppingItem]? = nil) {
        self.id = id
        self.date = date
        self.totalAmount = totalAmount
        self.isCompleted = isCompleted
        self.items = items
    }
}
