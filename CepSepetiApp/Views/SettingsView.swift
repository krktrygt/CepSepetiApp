//
//  SettingsView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 12.05.2026.
//

import SwiftUI
import SwiftData

/// A view that manages application settings, data privacy, and legal information.
/// Uygulama ayarlarını, veri gizliliğini ve yasal bilgileri yöneten görünüm.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State Properties
    // MARK: - Durum Özellikleri
    @State private var showDeleteAlert = false
    
    // MARK: - Computed Properties
    // MARK: - Hesaplanmış Özellikler
    
    /// Dynamically retrieves the app version from the Info.plist.
    /// Uygulama sürümünü Info.plist'ten dinamik olarak alır.
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Dynamically retrieves the build number from the Info.plist.
    /// Yapı numarasını Info.plist'ten dinamik olarak alır.
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        Form {
            // Section 1: Data Management
            // Bölüm 1: Veri Yönetimi
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Text("Tüm Geçmişi Temizle")
                        Spacer()
                        Image(systemName: "trash")
                    }
                }
            } header: {
                Text("VERİ YÖNETİMİ")
            } footer: {
                Text("Bu işlem, tüm geçmiş alışveriş oturumlarını ve eklenen ürünleri kalıcı olarak silecektir.")
            }
            
            // Section 2: Privacy & Storage
            // Bölüm 2: Gizlilik ve Depolama
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Veri Gizliliği")
                            .font(.headline)
                        Text("Alışveriş verileriniz KVKK uyumlu şekilde sadece bu cihazda saklanır ve hiçbir sunucuya gönderilmez.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .padding(.vertical, 4)
            } header: {
                Text("GİZLİLİK VE DEPOLAMA")
            }

            // Section 3: Debug (OCR Logs)
            // Bölüm 3: Hata Ayıklama (OCR Logları)
            Section {
                NavigationLink(destination: OCRLogView()) {
                    HStack {
                        Label("OCR Logları", systemImage: "terminal")
                        Spacer()
                    }
                }
            } header: {
                Text("HATA AYIKLAMA")
            }

            // Section 4: Legal & Support
            // Bölüm 4: Yasal ve Destek
            Section {
                Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                    HStack {
                        Text("Gizlilik Politikası")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                    HStack {
                        Text("Kullanım Koşulları")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button {
                    sendFeedback()
                } label: {
                    HStack {
                        Text("Geliştiriciye Geri Bildirim Gönder")
                        Spacer()
                        Image(systemName: "envelope")
                    }
                }
            } header: {
                Text("YASAL VE DESTEK")
            }
            
            // Section 5: App Info
            // Bölüm 5: Uygulama Hakkında
            Section {
                HStack {
                    Text("Uygulama Adı")
                    Spacer()
                    Text("CepSepeti")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Sürüm")
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("UYGULAMA BİLGİSİ")
            }
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.large)
        // Confirmation Alert for data deletion
        // Veri silme işlemi için onay uyarısı
        .alert("Tüm Geçmişi Temizle", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Evet, Hepsini Sil", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("Tüm alışveriş geçmişiniz kalıcı olarak silinecektir. Emin misiniz?")
        }
    }
    
    // MARK: - Actions
    // MARK: - Eylemler
    
    /// Clears all ShoppingSession data from the SwiftData model context.
    /// Tüm ShoppingSession verilerini SwiftData model context'inden temizler.
    private func clearAllData() {
        do {
            // Using delete(model:) for optimized bulk deletion.
            // Toplu silme işlemi için optimize edilmiş delete(model:) kullanımı.
            try modelContext.delete(model: ShoppingSession.self)
            try modelContext.save()
        } catch {
            print("🚨 Veri silinirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    /// Opens the default mail app with a feedback template.
    /// Varsayılan e-posta uygulamasını bir geri bildirim şablonuyla açar.
    private func sendFeedback() {
        let email = "destek@cepsepeti.app"
        let subject = "CepSepeti Geri Bildirim (v\(appVersion))"
        let body = "\n\n--- Cihaz Bilgileri ---\nModel: iPhone\nSürüm: \(appVersion)"
        
        let mailto = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: mailto) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [ShoppingSession.self, OCRLog.self], inMemory: true)
}
