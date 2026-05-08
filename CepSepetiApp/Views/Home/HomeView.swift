//
//  HomeView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    
    // Sadece tamamlanmış alışverişleri getir
    @Query(filter: #Predicate<ShoppingSession> { $0.isCompleted }, sort: \ShoppingSession.date, order: .reverse) private var sessions: [ShoppingSession]
    
    @State private var currentSession: ShoppingSession?

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: Text("Geçmiş Alışverişler")) {
                        if sessions.isEmpty {
                            Text("Henüz tamamlanmış bir alışveriş kaydınız yok.")
                                .foregroundColor(.gray)
                                .font(.callout)
                        } else {
                            ForEach(sessions) { session in
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
                            .onDelete(perform: deleteSession)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
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
    
    private func deleteSession(offsets: IndexSet) {
        for index in offsets {
            context.delete(sessions[index])
        }
    }
}

#Preview {
    HomeView()
}
