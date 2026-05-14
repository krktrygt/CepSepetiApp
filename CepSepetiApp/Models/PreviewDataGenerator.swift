//
//  PreviewDataGenerator.swift
//  CepSepetiApp
//
//  Created by Gemini CLI on 11.05.2026.
//

import Foundation
import SwiftData

/// A utility to generate in-memory mock data for SwiftUI Previews.
/// SwiftUI Önizlemeleri için bellek içi sahte veriler oluşturmaya yönelik bir yardımcı program.
struct PreviewDataGenerator {
    
    @MainActor
    static var previewContainer: ModelContainer = {
        do {
            // KESİNLİKLE isStoredInMemoryOnly: true ayarı yapıldı
            let schema = Schema([
                ShoppingSession.self,
                ShoppingItem.self
            ])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            let context = container.mainContext
            
            // Son 30 gün için rastgele veriler üretelim
            let brands = ["ÜLKER", "ETİ", "SÜTAŞ", "PINAR", "TORKU", "NESTLÉ", "COCA-COLA"]
            let products = [
                "Süt 1L", "Bisküvi", "Peynir 500G", "Çikolata", "Makarna", 
                "Zeytinyağı 1LT", "Yoğurt 2KG", "Ekmek", "Meyve Suyu", "Çay 1KG"
            ]
            
            for i in 0..<6 {
                let randomDaysAgo = Double(Int.random(in: 1...30))
                let sessionDate = Date().addingTimeInterval(-86400 * randomDaysAgo)
                
                let session = ShoppingSession(
                    id: UUID(),
                    date: sessionDate,
                    totalAmount: 0,
                    isCompleted: true
                )
                context.insert(session)
                
                var sessionTotal: Decimal = 0
                let itemCount = Int.random(in: 3...6)
                
                for _ in 0..<itemCount {
                    let price = Decimal(Double.random(in: 15.0...150.0).rounded(toPlaces: 2))
                    let quantity = Int.random(in: 1...3)
                    let item = ShoppingItem(
                        productName: products.randomElement() ?? "Ürün",
                        brand: brands.randomElement(),
                        price: price,
                        quantity: quantity,
                        session: session
                    )
                    context.insert(item)
                    sessionTotal += price * Decimal(quantity)
                }
                
                session.totalAmount = sessionTotal
            }
            
            try context.save()
            return container
            
        } catch {
            fatalError("Failed to create preview container: \(error.localizedDescription)")
        }
    }()
}

// SwiftUI Previews Kullanımı:
// .modelContainer(PreviewDataGenerator.previewContainer)

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
