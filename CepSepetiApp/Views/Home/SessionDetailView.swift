//
//  SessionDetailView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import SwiftData

/// A read-only detail view displaying the items of a completed shopping session.
/// Tamamlanmış bir alışveriş oturumunun öğelerini gösteren salt okunur detay görünümü.
struct SessionDetailView: View {
    /// The shopping session to display.
    /// Görüntülenecek alışveriş oturumu.
    let session: ShoppingSession

    var body: some View {
        List {
            if let items = session.items, !items.isEmpty {
                ForEach(items) { item in
                    LabeledContent {
                        Text(item.price * Decimal(item.quantity), format: .currency(code: "TRY"))
                            .bold()
                            .foregroundColor(.primary)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.productName)
                                .font(.body)
                                .foregroundColor(.primary)

                            if let brand = item.brand, !brand.isEmpty {
                                Text(brand)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            if item.quantity > 1 {
                                Text("\(item.quantity) Adet (Birim: \(item.price, format: .currency(code: "TRY")))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            if item.processingStatus != .completed {
                                Text(statusText(for: item))
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            } else {
                Text("Bu alışverişte ürün bulunmuyor.")
                    .foregroundColor(.gray)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(session.date.formatted(.dateTime.day().month().year()))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Text("Toplam Tutar")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(session.totalAmount, format: .currency(code: "TRY"))
                        .font(.title)
                        .bold()
                        .foregroundColor(.primary)
                }
                .padding()
            }
            .background(.regularMaterial)
        }
    }

    private func statusText(for item: ShoppingItem) -> String {
        switch item.processingStatus {
        case .queued:
            return "Sırada"
        case .processing:
            return "Analiz ediliyor"
        case .needsReview:
            return "Kontrol bekliyor"
        case .failed:
            return "Eklenemedi"
        case .completed:
            return ""
        }
    }
}
