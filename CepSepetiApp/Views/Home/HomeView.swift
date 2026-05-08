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
    
    /// Fetches only completed shopping sessions, sorted by date in descending order.
    /// Yalnızca tamamlanmış alışveriş oturumlarını tarih sırasına göre azalan şekilde getirir.
    @Query(filter: #Predicate<ShoppingSession> { $0.isCompleted }, sort: \ShoppingSession.date, order: .reverse) private var sessions: [ShoppingSession]
    
    /// Holds the currently active shopping session if one is in progress.
    /// Devam eden bir tane varsa, o andaki aktif alışveriş oturumunu tutar.
    @State private var currentSession: ShoppingSession?

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: Text("Past Shopping Trips")) {
                        if sessions.isEmpty {
                            Text("No completed shopping trips yet.")
                                .foregroundColor(.gray)
                                .font(.callout)
                        } else {
                            ForEach(sessions) { session in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(session.date, format: .dateTime.day().month().year())
                                            .font(.headline)
                                        Text("\(session.items?.count ?? 0) Items")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text(session.totalAmount, format: .currency(code: "TRY"))
                                        .bold()
                                }
                            }
                            .onDelete(perform: deleteSession)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                // Button to initiate a new shopping trip
                // Yeni bir alışveriş gezisi başlatmak için buton
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
                        Text("Start New Shopping Trip")
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
            }
            .navigationTitle("Cep Sepeti")
            .fullScreenCover(item: $currentSession) { session in
                ScannerView(activeSession: session)
            }
        }
    }
    
    /// Removes a completed session from history.
    /// Tamamlanmış bir oturumu geçmişten kaldırır.
    private func deleteSession(offsets: IndexSet) {
        for index in offsets {
            context.delete(sessions[index])
        }
    }
}

#Preview {
    HomeView()
}

/*
 SUMMARY:
 HomeView acts as the landing page of the app. It provides a visual history of past transactions 
 and serves as the entry point for the scanning workflow by creating new ShoppingSession instances.
 
 ÖZET:
 HomeView, uygulamanın açılış sayfası olarak görev yapar. Geçmiş işlemlerin görsel bir geçmişini sağlar 
 ve yeni ShoppingSession örnekleri oluşturarak tarama iş akışı için giriş noktası olarak hizmet eder.
 */
