//
//  CartSheetView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 21.04.2026.
//

import SwiftUI
import SwiftData

struct CartSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @Bindable var activeSession: ShoppingSession
    
    // Toplam tutarı dinamik hesapla
    var totalAmount: Decimal {
        guard let items = activeSession.items else { return Decimal(0) }
        var total: Decimal = 0
        for item in items {
            total += item.price * Decimal(item.quantity)
        }
        return total
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if let items = activeSession.items, !items.isEmpty {
                        ForEach(items) { item in
                            @Bindable var item = item
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.productName)
                                        .font(.headline)
                                    Text(item.price, format: .currency(code: "TRY"))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                
                                Stepper("", value: $item.quantity, in: 1...100)
                                    .labelsHidden()
                                Text("\(item.quantity) Adet")
                                    .frame(width: 60, alignment: .trailing)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    } else {
                        Text("Sepetiniz şu an boş.")
                            .foregroundColor(.gray)
                    }
                }
                
                // Toplam Tutar ve Bitirme Butonu
                VStack(spacing: 16) {
                    HStack {
                        Text("Toplam Tutar:")
                            .font(.title2)
                        Spacer()
                        Text(totalAmount, format: .currency(code: "TRY"))
                            .font(.title2)
                            .bold()
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        // Oturumu tamamla ve veritabanını güncelle
                        activeSession.totalAmount = totalAmount
                        activeSession.isCompleted = true
                        
                        // Ekranı kapatıp ana sayfaya dönmesi için bildirim veya environment mantığı eklenebilir
                        // Şimdilik sadece bu sepet sayfasını kapatıyoruz.
                        dismiss()
                    }) {
                        Text("Alışverişi Bitir")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(activeSession.items?.isEmpty == true ? Color.gray : Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(activeSession.items?.isEmpty == true)
                }
                .padding(.bottom)
            }
            .navigationTitle("Sepetim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        guard let items = activeSession.items else { return }
        for index in offsets {
            context.delete(items[index])
        }
    }
}
