//
//  OCRLogView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 14.05.2026.
//

import SwiftUI
import SwiftData

/// A view that displays and manages OCR debug logs.
/// OCR hata ayıklama günlüklerini görüntüleyen ve yöneten görünüm.
struct OCRLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OCRLog.timestamp, order: .reverse) private var logs: [OCRLog]
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        List {
            if logs.isEmpty {
                ContentUnavailableView(
                    "Log Kaydı Bulunamadı",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Henüz bir OCR işlemi gerçekleştirilmedi veya tüm loglar temizlendi.")
                )
            } else {
                ForEach(logs) { log in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: log.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(log.success ? .green : .red)
                            
                            Text(log.timestamp, style: .date)
                                .font(.caption)
                            Text(log.timestamp, style: .time)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(log.success ? "Başarılı" : "Hata")
                                .font(.caption2).bold()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(log.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .foregroundColor(log.success ? .green : .red)
                                .cornerRadius(4)
                        }
                        
                        Text(log.rawText)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(5)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteLogs)
            }
        }
        .navigationTitle("OCR Logları")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if !logs.isEmpty {
                        // ShareLink for exporting logs
                        // Logları dışa aktarmak için ShareLink
                        ShareLink(item: generateExportString()) {
                            Label("Dışa Aktar", systemImage: "square.and.arrow.up")
                        }
                        
                        // Clear All button
                        // Tümünü temizle butonu
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .alert("Tüm Logları Temizle", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Evet, Hepsini Sil", role: .destructive) {
                clearAllLogs()
            }
        } message: {
            Text("Tüm OCR günlükleri kalıcı olarak silinecektir. Emin misiniz?")
        }
    }
    
    // MARK: - Helper Methods
    // MARK: - Yardımcı Yöntemler
    
    /// Generates a long string containing all logs in a structured format.
    /// Tüm logları yapılandırılmış bir formatta içeren uzun bir dize oluşturur.
    private func generateExportString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        var exportString = "--- CepSepeti OCR Debug Logs ---\n\n"
        exportString += "Tarih | Başarı Durumu | Ham Metin\n"
        exportString += String(repeating: "-", count: 40) + "\n"
        
        for log in logs {
            let dateStr = formatter.string(from: log.timestamp)
            let successStr = log.success ? "BAŞARILI" : "HATA"
            let sanitizedText = log.rawText.replacingOccurrences(of: "\n", with: " ")
            exportString += "\(dateStr) | \(successStr) | \(sanitizedText)\n"
        }
        
        return exportString
    }
    
    /// Deletes specific logs from the context.
    /// Belirli logları context'ten siler.
    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(logs[index])
        }
    }
    
    /// Clears all OCRLog data from the context.
    /// Tüm OCRLog verilerini context'ten temizler.
    private func clearAllLogs() {
        do {
            try modelContext.delete(model: OCRLog.self)
            try modelContext.save()
        } catch {
            print("🚨 Loglar silinirken hata oluştu: \(error.localizedDescription)")
        }
    }
}

#Preview {
    OCRLogView()
        .modelContainer(for: OCRLog.self, inMemory: true)
}
