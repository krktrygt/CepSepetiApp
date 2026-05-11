import Foundation
import SwiftData
import SwiftUI

/// Data structure for the last 7 days expenditure chart.
struct DailyExpenditure: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

/// Data structure for brand distribution chart.
struct BrandExpenditure: Identifiable {
    let id = UUID()
    let brand: String
    let amount: Double
}

@Observable
@MainActor
final class StatisticsViewModel {
    
    // MARK: - Output States
    var weeklyData: [DailyExpenditure] = []
    var brandData: [BrandExpenditure] = []
    var mostFrequentItem: String = "-"
    var mostExpensiveItem: String = "-"
    var hasData: Bool = false
    var isLoading: Bool = false
    
    /// Main entry point to refresh statistics from the database.
    func calculateStatistics(sessions: [ShoppingSession]) async {
        guard !sessions.isEmpty else {
            self.hasData = false
            return
        }
        
        isLoading = true
        self.hasData = true
        
        // Use Task.detached for heavy calculations if needed, but since we are handling 
        // a reasonable number of sessions, standard Swift concurrency within the task is fine.
        // For absolute HIG performance, we process this data and update the UI states.
        
        let now = Date()
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -6, to: now) ?? now)
        
        // 1. Calculate Last 7 Days
        var tempWeekly: [DailyExpenditure] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                let startOfDay = calendar.startOfDay(for: date)
                let total = sessions
                    .filter { calendar.isDate($0.date, inSameDayAs: startOfDay) }
                    .reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.totalAmount).doubleValue }
                
                tempWeekly.append(DailyExpenditure(date: startOfDay, amount: total))
            }
        }
        self.weeklyData = tempWeekly.sorted { $0.date < $1.date }
        
        // 2. Process all items for brand and frequency analysis
        let allItems = sessions.flatMap { $0.items ?? [] }
        
        // 3. Top Brands (Donut Chart)
        var brandTotals: [String: Double] = [:]
        for item in allItems {
            let brandName = item.brand?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? item.brand! : "Bilinmeyen"
            let cost = NSDecimalNumber(decimal: item.price * Decimal(item.quantity)).doubleValue
            brandTotals[brandName, default: 0] += cost
        }
        
        self.brandData = brandTotals.map { BrandExpenditure(brand: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
            .prefix(4)
            .map { $0 }
        
        // 4. Shopping Habits
        // Most Frequent (By Quantity)
        var itemFrequencies: [String: Int] = [:]
        var itemCosts: [String: Double] = [:]
        
        for item in allItems {
            itemFrequencies[item.productName, default: 0] += item.quantity
            let cost = NSDecimalNumber(decimal: item.price * Decimal(item.quantity)).doubleValue
            itemCosts[item.productName, default: 0] += cost
        }
        
        self.mostFrequentItem = itemFrequencies.max(by: { $0.value < $1.value })?.key ?? "-"
        self.mostExpensiveItem = itemCosts.max(by: { $0.value < $1.value })?.key ?? "-"
        
        isLoading = false
    }
}
