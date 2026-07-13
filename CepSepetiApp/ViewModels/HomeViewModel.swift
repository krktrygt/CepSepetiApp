//
//  HomeViewModel.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//
import Foundation
import SwiftData

/// ViewModel for the main dashboard of the application, managing summary calculations and session lifecycle.
/// Uygulamanın ana paneli için özet hesaplamalarını ve oturum yaşam döngüsünü yöneten ViewModel.
@Observable
final class HomeViewModel {
    
    /// Calculates the total expenditure for the current calendar month across all completed sessions.
    /// Tüm tamamlanmış oturumlar arasında mevcut takvim ayı için toplam harcamayı hesaplar.
    /// - Parameter sessions: An array of all available shopping sessions.
    /// - Returns: The sum of total amounts for sessions within the current month.
    func calculateMonthlyTotal(sessions: [ShoppingSession]) -> Decimal {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // Filter sessions that occurred in the current month and year.
        // Mevcut ay ve yılda gerçekleşen oturumları filtreleyin.
        let monthlySessions = sessions.filter { session in
            let sessionMonth = Calendar.current.component(.month, from: session.date)
            let sessionYear = Calendar.current.component(.year, from: session.date)
            
            return session.isCompleted && sessionMonth == currentMonth && sessionYear == currentYear
        }
        
        // Accumulate the totals.
        // Toplamları biriktirin.
        return monthlySessions.reduce(0) { $0 + $1.totalAmount }
    }
    
    /// Creates a new shopping session and persists it in the database.
    /// Yeni bir alışveriş oturumu oluşturur ve veritabanında saklar.
    /// - Parameter context: The ModelContext for SwiftData operations.
    /// - Returns: The newly created ShoppingSession object.
    func createNewSession(context: ModelContext) -> ShoppingSession {
        let newSession = ShoppingSession(id: UUID(), date: .now, totalAmount: 0.0, isCompleted: false)
        context.insert(newSession) 
        
        do {
            try context.save()
        } catch {
            print("Error: Could not create new session - \(error.localizedDescription)")
        }
        
        return newSession
    }
    
    /// Deletes a specific shopping session from the database.
    /// Veritabanından belirli bir alışveriş oturumunu siler.
    /// - Parameters:
    ///   - session: The session to be deleted.
    ///   - context: The ModelContext for SwiftData operations.
    func deleteSession(session: ShoppingSession, context: ModelContext) {
        context.delete(session)
        try? context.save()
    }
}

/*
 SUMMARY:
 HomeViewModel handles the high-level business logic for the Home screen.
 It performs data aggregation (monthly totals) and manages the creation/deletion of shopping sessions.
 it serves as the primary controller for the session-based history and current trip initiation.
 
 ÖZET:
 HomeViewModel, Ana ekran için üst düzey iş mantığını yönetir.
 Veri toplama (aylık toplamlar) işlemlerini gerçekleştirir ve alışveriş oturumlarının oluşturulmasını/silinmesini yönetir.
 Oturum tabanlı geçmiş ve mevcut gezi başlatma için birincil kontrolör olarak hizmet eder.
 */
