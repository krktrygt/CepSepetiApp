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
            guard item.processingStatus == .completed else { continue }
            total += item.price * Decimal(item.quantity)
        }
        return total
    }

    private var hasBlockingItems: Bool {
        guard let items = activeSession.items else { return false }
        return items.contains { item in
            item.processingStatus == .queued ||
            item.processingStatus == .processing ||
            item.processingStatus == .needsReview ||
            item.processingStatus == .failed
        }
    }

    private var completedItemCount: Int {
        activeSession.items?.filter { $0.processingStatus == .completed }.count ?? 0
    }

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if let items = activeSession.items, !items.isEmpty {
                        ForEach(items) { item in
                            @Bindable var item = item
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    if item.processingStatus == .completed {
                                        Text(item.productName)
                                            .font(.headline)
                                        if let brand = item.brand, !brand.isEmpty {
                                            Text(brand)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Text(item.price, format: .currency(code: "TRY"))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    } else {
                                        HStack(spacing: 8) {
                                            if item.processingStatus == .queued || item.processingStatus == .processing {
                                                ProgressView()
                                                    .controlSize(.small)
                                            }
                                            Text(statusTitle(for: item))
                                                .font(.headline)
                                        }
                                        Text(statusSubtitle(for: item))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()

                                if item.processingStatus == .completed {
                                    // Stepper to adjust item quantity
                                    // Öğe miktarını ayarlamak için Stepper
                                    Stepper("", value: $item.quantity, in: 1...100)
                                        .labelsHidden()
                                    Text("\(item.quantity) Adet")
                                        .frame(width: 60, alignment: .trailing)
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    } else {
                        Text("Sepetiniz şu anda boş.")
                            .foregroundColor(.gray)
                    }
                }

                // Summary section with total amount and checkout button
                // Toplam tutar ve ödeme butonu ile özet bölümü
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

                    if hasBlockingItems {
                        Text("Analiz bekleyen ürünler kesin toplama dahil edilmedi.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }

                    Button(action: {
                        // Mark the session as completed and save the final total
                        // Oturumu tamamlandı olarak işaretleyin ve nihai toplamı kaydedin
                        activeSession.totalAmount = totalAmount
                        activeSession.isCompleted = true
                        try? context.save()

                        dismiss()
                    }) {
                        Text("Alışverişi Bitir")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(completedItemCount == 0 || hasBlockingItems ? Color.gray : Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(completedItemCount == 0 || hasBlockingItems)
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

    /// Deletes selected items from the shopping session.
    /// Seçili öğeleri alışveriş oturumundan siler.
    private func deleteItems(offsets: IndexSet) {
        guard let items = activeSession.items else { return }
        for index in offsets {
            context.delete(items[index])
        }
    }

    private func statusTitle(for item: ShoppingItem) -> String {
        switch item.processingStatus {
        case .queued:
            return "Sırada..."
        case .processing:
            return "Analiz ediliyor..."
        case .needsReview:
            return item.productName.isEmpty ? "Sonucu kontrol edin" : item.productName
        case .failed:
            return "Ürün analiz edilemedi"
        case .completed:
            return item.productName
        }
    }

    private func statusSubtitle(for item: ShoppingItem) -> String {
        switch item.processingStatus {
        case .queued:
            return "Etiket işleme kuyruğuna alındı."
        case .processing:
            return "OCR ve AI doğrulaması çalışıyor."
        case .needsReview:
            let priceText = item.price > 0 ? "Tahmini fiyat: \(item.price.formatted(.currency(code: "TRY")))" : "Manuel kontrol gerekli."
            return priceText
        case .failed:
            return item.processingError ?? "Manuel giriş veya tekrar deneme gerekli."
        case .completed:
            return ""
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
