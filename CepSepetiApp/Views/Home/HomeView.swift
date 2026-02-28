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
    
    // İş mantığını yönetecek sınıfımız
    @State private var viewModel = HomeViewModel()
    
    // Veritabanından tüm alışverişleri tarihe göre en yeniden eskiye doğru otomatik çek (Reaktif Makro)
    @Query(sort: \ShoppingSession.date, order: .reverse) private var sessions: [ShoppingSession]
    
    // Yeni alışveriş başladığında kamerayı tam ekran açmak için state ve aktif sepet
    @State private var showScanner: Bool = false
    @State private var currentSession: ShoppingSession?

    var body: some View {
        NavigationStack {
            VStack {
                // 1. Üst Kısım: Aylık Özet Kartı
                VStack(spacing: 8) {
                    Text("Bu Ayki Harcama")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // ViewModel'den dönen Decimal verisini Currency (Para Birimi) formatında yazdır
                    Text(viewModel.calculateMonthlyTotal(sessions: sessions), format: .currency(code: "TRY"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // 2. Alt Kısım: Geçmiş Alışverişler Listesi
                List {
                    Section(header: Text("Geçmiş Alışverişler")) {
                        if sessions.isEmpty {
                            Text("Henüz bir alışveriş kaydınız yok.")
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
                            .onDelete { indexSet in
                                // Sağa kaydırarak silme işlemi
                                for index in indexSet {
                                    viewModel.deleteSession(session: sessions[index], context: context)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                // 3. En Alt: Yeni Alışveriş Başlat Butonu
                Button(action: {
                    // ViewModel'e "Bana yeni bir sepet ver" diyoruz
                    let newSession = viewModel.createNewSession(context: context)
                    self.currentSession = newSession
                    self.showScanner = true // Kamerayı tetikle
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
            // Kamera ekranını tam sayfa (FullScreenCover) olarak açıyoruz
            .fullScreenCover(item: $currentSession) { session in
                BarcodeScannerView(activeSession: session)
            }
        }
    }
}

#Preview {
    HomeView()
}
