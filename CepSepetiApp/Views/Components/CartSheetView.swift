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

    @State private var scanCoordinator = ScanProcessingCoordinator()
    @State private var showCheckoutWarning = false
    @State private var itemBeingEdited: ShoppingItem?
    @State private var editedName = ""
    @State private var editedBrand = ""
    @State private var editedPrice = ""

    private var summary: ShoppingCartSummary {
        ShoppingCartSummary.make(items: activeSession.items ?? [])
    }

    private var checkoutWarningMessage: String {
        if summary.hasPendingAnalysis {
            return "Bazı ürünler hâlâ analiz ediliyor. Gösterilen toplam eksik olabilir."
        }
        if summary.needsReviewCount > 0 {
            return "Bazı ürünlerin sonucu kontrol edilmedi. Lütfen onaylayın veya düzenleyin."
        }
        if summary.failedCount > 0 {
            return "Bazı ürünler sepete doğru biçimde eklenemedi. Yeniden deneyin, manuel tamamlayın veya silin."
        }
        return "Alışverişi bitirmek için en az bir tamamlanmış ürün olmalı."
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

                                        actionButtons(for: item)
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
                        Text("Kesinleşen Toplam:")
                            .font(.title2)
                        Spacer()
                        Text(summary.confirmedTotal, format: .currency(code: "TRY"))
                            .font(.title2)
                            .bold()
                    }
                    .padding(.horizontal)

                    if let estimatedTotal = summary.estimatedTotal, estimatedTotal != summary.confirmedTotal {
                        HStack {
                            Text("Tahmini Genel Toplam:")
                                .font(.subheadline)
                            Spacer()
                            Text(estimatedTotal, format: .currency(code: "TRY"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    }

                    if let statusSummary = summary.statusSummaryText {
                        Text(statusSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }

                    Button(action: {
                        guard summary.canFinalize else {
                            showCheckoutWarning = true
                            return
                        }
                        finalizeSession()
                    }) {
                        Text("Alışverişi Bitir")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(summary.canFinalize ? Color.green : Color.orange)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
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
        .alert("Alışveriş tamamlanamadı", isPresented: $showCheckoutWarning) {
            Button("Alışverişe Geri Dön", role: .cancel) { }
            if summary.needsReviewCount > 0 || summary.failedCount > 0 {
                Button("Ürünleri Tamamla") { }
            }
            if summary.hasPendingAnalysis {
                Button("Analizleri Bekle") { }
            }
        } message: {
            Text(checkoutWarningMessage)
        }
        .sheet(item: $itemBeingEdited) { item in
            NavigationStack {
                Form {
                    TextField("Ürün adı", text: $editedName)
                    TextField("Marka", text: $editedBrand)
                    TextField("Fiyat", text: $editedPrice)
                        .keyboardType(.decimalPad)
                }
                .navigationTitle("Ürünü Tamamla")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Vazgeç") {
                            itemBeingEdited = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Kaydet") {
                            saveManualEdit(item)
                        }
                        .disabled(parsedEditedPrice == nil || editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
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

    @ViewBuilder
    private func actionButtons(for item: ShoppingItem) -> some View {
        switch item.processingStatus {
        case .needsReview:
            HStack {
                Button("Onayla") {
                    approve(item)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Düzenle") {
                    beginManualEdit(item)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        case .failed:
            HStack {
                if item.capturedImagePath != nil {
                    Button("Yeniden Dene") {
                        scanCoordinator.retry(item: item, context: context)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Button("Manuel Gir") {
                    beginManualEdit(item)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Sil", role: .destructive) {
                    context.delete(item)
                    try? context.save()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        default:
            EmptyView()
        }
    }

    private func finalizeSession() {
        activeSession.totalAmount = summary.confirmedTotal
        activeSession.isCompleted = true
        try? context.save()
        dismiss()
    }

    private func approve(_ item: ShoppingItem) {
        guard item.price > 0,
              !item.productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            beginManualEdit(item)
            return
        }

        item.processingStatus = .completed
        item.processingError = nil
        item.processingCompletedAt = Date()
        try? context.save()
    }

    private func beginManualEdit(_ item: ShoppingItem) {
        editedName = item.productName == "Ürün analiz edilemedi" ? "" : item.productName
        editedBrand = item.brand ?? ""
        editedPrice = item.price > 0 ? NSDecimalNumber(decimal: item.price).stringValue : ""
        itemBeingEdited = item
    }

    private var parsedEditedPrice: Decimal? {
        Decimal(string: editedPrice.replacingOccurrences(of: ",", with: "."))
    }

    private func saveManualEdit(_ item: ShoppingItem) {
        guard let price = parsedEditedPrice else { return }
        item.productName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        item.brand = editedBrand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editedBrand
        item.price = price
        item.processingStatus = .completed
        item.processingError = nil
        item.processingCompletedAt = Date()
        try? context.save()
        itemBeingEdited = nil
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
