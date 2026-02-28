//
//  HomeViewModel.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation
import SwiftData

@Observable
final class HomeViewModel {
    
    // 1. Aylık Toplam Harcamayı Hesapla
    func calculateMonthlyTotal(sessions: [ShoppingSession]) -> Decimal {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // Sadece bu aya ait olan ve "Tamamlanmış" (veya içi boş olmayan) alışverişleri filtrele
        let monthlySessions = sessions.filter { session in
            let sessionMonth = Calendar.current.component(.month, from: session.date)
            let sessionYear = Calendar.current.component(.year, from: session.date)
            
            return sessionMonth == currentMonth && sessionYear == currentYear
        }
        
        // Filtrelenen alışverişlerin toplam tutarlarını topla
        return monthlySessions.reduce(0) { $0 + $1.totalAmount }
    }
    
    // 2. Yeni Alışveriş Sepeti (Oturumu) Oluştur
    func createNewSession(context: ModelContext) -> ShoppingSession {
        let newSession = ShoppingSession(id: UUID(), date: .now, totalAmount: 0.0, isCompleted: false)
        context.insert(newSession) // Veritabanına ekle
        
        do {
            try context.save()
        } catch {
            print("Hata: Yeni sepet oluşturulamadı - \(error.localizedDescription)")
        }
        
        return newSession
    }
    
    // 3. Geçmiş Alışverişi Sil (Kullanıcı kaydırarak silmek isterse)
    func deleteSession(session: ShoppingSession, context: ModelContext) {
        context.delete(session)
        try? context.save()
    }
}
