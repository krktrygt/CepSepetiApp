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
    
    /// Fetches all shopping sessions.
    /// Tüm alışveriş oturumlarını getirir.
    @Query(sort: \ShoppingSession.date, order: .reverse) private var allSessions: [ShoppingSession]
    
    /// Holds the currently active shopping session if one is in progress.
    /// Devam eden bir tane varsa, o andaki aktif alışveriş oturumunu tutar.
    @State private var currentSession: ShoppingSession?

    var body: some View {
        NavigationStack {
            VStack {
                List {
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
                                            Text(session.date, format: .dateTime.day().month().year())
                                                .font(.headline)
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
                    
                    Section(header: Text("Geçmiş Alışverişler")) {
                        if completedSessions.isEmpty {
                            Text("Henüz tamamlanmış bir alışveriş yok.")
                                .foregroundColor(.gray)
                                .font(.callout)
                        } else {
                            ForEach(completedSessions) { session in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(session.date, format: .dateTime.day().month().year())
                                            .font(.headline)
                                        Text("\(session.items?.count ?? 0) Ürün")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text(session.totalAmount, format: .currency(code: "TRY"))
                                        .bold()
                                }
                            }
                            .onDelete { offsets in
                                deleteSession(from: completedSessions, at: offsets)
                            }
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
            }
            .navigationTitle("Cep Sepeti")
            .fullScreenCover(item: $currentSession) { session in
                ScannerView(activeSession: session)
            }
        }
    }
    
    /// Removes a session from history.
    /// Bir oturumu geçmişten kaldırır.
    private func deleteSession(from filteredSessions: [ShoppingSession], at offsets: IndexSet) {
        for index in offsets {
            let sessionToDelete = filteredSessions[index]
            context.delete(sessionToDelete)
        }
        try? context.save()
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
