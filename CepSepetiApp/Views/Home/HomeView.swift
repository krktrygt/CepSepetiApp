//
//  HomeView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import SwiftData

/// The main dashboard of the application showing a history of completed shopping sessions and an option to start a new one.
/// Uygulamanın, tamamlanmış alışveriş oturumlarının geçmişini ve yeni bir tane başlatma seçeneğini gösteren ana paneli.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    
    /// Fetches all shopping sessions, sorted by date in descending order (newest first).
    /// Tüm alışveriş oturumlarını tarih sırasına göre azalan şekilde (en yeni en üstte) getirir.
    @Query(sort: \ShoppingSession.date, order: .reverse) private var allSessions: [ShoppingSession]
    
    /// Holds the currently active shopping session if one is in progress.
    /// Devam eden bir tane varsa, o andaki aktif alışveriş oturumunu tutar.
    @State private var currentSession: ShoppingSession?
    
    /// Calculates the total expenditure across all completed sessions in the current month.
    /// İçinde bulunulan aydaki tüm tamamlanmış oturumlar için toplam harcamayı hesaplar.
    private var monthlySpent: Decimal {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return allSessions.filter { session in
            session.isCompleted &&
            Calendar.current.component(.month, from: session.date) == currentMonth &&
            Calendar.current.component(.year, from: session.date) == currentYear
        }.reduce(0) { $0 + $1.totalAmount }
    }
    
    /// Gets the localized name of the current month.
    /// İçinde bulunulan ayın yerelleştirilmiş adını alır.
    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            Group {
                if allSessions.isEmpty {
                    ContentUnavailableView(
                        "Henüz bir alışverişiniz bulunmuyor",
                        systemImage: "cart.badge.plus"
                    )
                } else {
                    List {
                        // Dashboard Card for Total Expenditure
                        // Toplam Harcama için Dashboard Kartı
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(currentMonthName) Harcaması")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(monthlySpent, format: .currency(code: "TRY"))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        let activeSessions = allSessions.filter { !$0.isCompleted }
                        let completedSessions = allSessions.filter { $0.isCompleted }
                        
                        if !activeSessions.isEmpty {
                            Section(header: Text("Devam Eden Alışverişler")) {
                                ForEach(activeSessions) { session in
                                    Button(action: {
                                        self.currentSession = session
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(session.date, format: .relative(presentation: .named))
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Text("\(session.items?.count ?? 0) Ürün")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .onDelete { offsets in
                                    deleteSession(from: activeSessions, at: offsets)
                                }
                            }
                        }
                        
                        if !completedSessions.isEmpty {
                            Section(header: Text("Geçmiş Alışverişler")) {
                                ForEach(completedSessions) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(session.date, format: .relative(presentation: .named))
                                                    .font(.headline)
                                                Text(session.date, format: .dateTime.day().month().year())
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Text(session.totalAmount, format: .currency(code: "TRY"))
                                                .bold()
                                        }
                                    }
                                }
                                .onDelete { offsets in
                                    deleteSession(from: completedSessions, at: offsets)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Harcamalarım")
            .safeAreaInset(edge: .bottom) {
                // Button to initiate a new shopping trip, pinned to the bottom
                // Yeni bir alışveriş gezisi başlatmak için alt kısma sabitlenmiş buton
                Button(action: {
                    let newSession = ShoppingSession(
                        id: UUID(),
                        date: Date(),
                        totalAmount: 0.0,
                        isCompleted: false
                    )
                    context.insert(newSession)
                    self.currentSession = newSession
                }) {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                        Text("Yeni Alışveriş Başlat")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.background.opacity(0.8))
            }
            .fullScreenCover(item: $currentSession) { session in
                ScannerView(activeSession: session)
            }
        }
    }
    
    /// Removes a session from history safely using SwiftData context.
    /// SwiftData bağlamını kullanarak bir oturumu geçmişten güvenli bir şekilde kaldırır.
    private func deleteSession(from filteredSessions: [ShoppingSession], at offsets: IndexSet) {
        for index in offsets {
            let sessionToDelete = filteredSessions[index]
            context.delete(sessionToDelete)
        }
        try? context.save()
    }
}