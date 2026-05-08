//
//  CartSheetView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 21.04.2026.
//

import SwiftUI
import SwiftData

/// A view that displays the current shopping cart as a sheet, allowing users to adjust quantities and finalize the session.
/// Mevcut alışveriş sepetini bir sayfa (sheet) olarak görüntüleyen, kullanıcıların miktarları ayarlamasına ve oturumu sonlandırmasına olanak tanıyan bir görünüm.
struct CartSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    /// The shopping session being managed in the cart.
    /// Sepette yönetilen alışveriş oturumu.
    @Bindable var activeSession: ShoppingSession
    
    /// Dynamically calculates the total price of all items currently in the cart.
    /// Sepetteki tüm öğelerin toplam fiyatını dinamik olarak hesaplar.
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
                                
                                // Stepper to adjust item quantity
                                // Öğe miktarını ayarlamak için Stepper
                                Stepper("", value: $item.quantity, in: 1...100)
                                    .labelsHidden()
                                Text("\(item.quantity) Units")
                                    .frame(width: 60, alignment: .trailing)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    } else {
                        Text("Your cart is currently empty.")
                            .foregroundColor(.gray)
                    }
                }
                
                // Summary section with total amount and checkout button
                // Toplam tutar ve ödeme butonu ile özet bölümü
                VStack(spacing: 16) {
                    HStack {
                        Text("Total Amount:")
                            .font(.title2)
                        Spacer()
                        Text(totalAmount, format: .currency(code: "TRY"))
                            .font(.title2)
                            .bold()
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        // Mark the session as completed and save the final total
                        // Oturumu tamamlandı olarak işaretleyin ve nihai toplamı kaydedin
                        activeSession.totalAmount = totalAmount
                        activeSession.isCompleted = true
                        
                        dismiss()
                    }) {
                        Text("Finish Shopping")
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
            .navigationTitle("My Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    /// Deletes selected items from the shopping session.
    /// Seçili öğeleri alışveriş oturumundan siler.
    private func deleteItems(offsets: IndexSet) {
        guard let items = activeSession.items else { return }
        for index in offsets {
            context.delete(items[index])
        }
    }
}

/*
 SUMMARY:
 CartSheetView provides a detailed list of items in the current activeSession.
 It allows users to modify quantities or remove items before finalizing the shopping trip.
 It interacts directly with SwiftData via the modelContext and updates the session state.
 
 ÖZET:
 CartSheetView, mevcut activeSession'daki öğelerin ayrıntılı bir listesini sağlar.
 Kullanıcıların alışveriş gezisini sonlandırmadan önce miktarları değiştirmesine veya öğeleri kaldırmasına olanak tanır.
 ModelContext aracılığıyla doğrudan SwiftData ile etkileşime girer ve oturum durumunu günceller.
 */
