//
//  ShoppingSession.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation
import SwiftData

/// A persistent data model representing a single shopping trip or session.
/// Tek bir alışveriş gezisini veya oturumunu temsil eden kalıcı bir veri modeli.
@Model
final class ShoppingSession {
    /// Unique identifier for the session.
    /// Oturum için benzersiz tanımlayıcı.
    var id: UUID
    /// The date and time when the session occurred.
    /// Oturumun gerçekleştiği tarih ve saat.
    var date: Date
    /// The total calculated amount for all items in this session.
    /// Bu oturumdaki tüm öğeler için hesaplanan toplam tutar.
    var totalAmount: Decimal
    /// Flag indicating whether the shopping trip has been finalized.
    /// Alışveriş gezisinin tamamlanıp tamamlanmadığını belirten bayrak.
    var isCompleted: Bool
    
    /// A list of items associated with this session. Deleting the session deletes all its items.
    /// Bu oturumla ilişkili öğelerin listesi. Oturumun silinmesi tüm öğelerini de siler.
    @Relationship(deleteRule: .cascade, inverse: \ShoppingItem.session)
    var items: [ShoppingItem]?
    
    /// Initializes a new ShoppingSession.
    /// Yeni bir ShoppingSession başlatır.
    /// - Parameters:
    ///   - id: Unique ID.
    ///   - date: Session date.
    ///   - totalAmount: Initial total amount.
    ///   - isCompleted: Initial completion status.
    ///   - items: Initial items in the session.
    init(id: UUID, date: Date, totalAmount: Decimal, isCompleted: Bool, items: [ShoppingItem]? = nil) {
        self.id = id
        self.date = date
        self.totalAmount = totalAmount
        self.isCompleted = isCompleted
        self.items = items
    }
}

/*
 SUMMARY:
 ShoppingSession is a SwiftData model that aggregates multiple ShoppingItems into a single event.
 It tracks the total cost and completion status of a shopping trip.
 It serves as the top-level entity for the app's history and current cart management.
 
 ÖZET:
 ShoppingSession, birden fazla ShoppingItem'ı tek bir olayda birleştiren bir SwiftData modelidir.
 Bir alışveriş gezisinin toplam maliyetini ve tamamlanma durumunu takip eder.
 Uygulamanın geçmişi ve mevcut sepet yönetimi için en üst düzey varlık olarak hizmet eder.
 */
