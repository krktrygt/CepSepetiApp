//
//  BarcodeScannerView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI

struct BarcodeScannerView: View {
    
    // 1. Backend servisimizi UI'a bağlıyoruz
    @State private var scannerService = BarcodeScannerService()
        
    // 2. Okunan barkodu ekranda göstermek için State (MVP Testi için)
    @State private var scannedCode: String?
    @State private var productName: String?
    @State private var isSearching: Bool = false // API isteği atıldığında UI'ı kilitlemek için
        
    // Ekranı kapatmak için çevresel değişken (Environment)
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            ZStack{
                // Katman 1: Kamera görüntüsü
                CameraPreviewView(session: scannerService.captureSession)
                    .ignoresSafeArea()
                
                //Katman 2: Arayüz elemanları
                VStack{
                    Spacer()
                    
                    // Kullanıcıya nereye odaklanacağını gösteren vizör (Tasarım detayı)
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.8), lineWidth: 3)
                        .frame(width: 250, height: 150)
                        .background(Color.black.opacity(0.1))
                                        
                    Spacer()
                    
                    if isSearching{
                        VStack{
                            ProgressView()
                                .tint(.black)
                            Text("Ürün aranıyor...")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                        .padding()
                        .background(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 40)
                    } else if let code = scannedCode {
                        VStack (spacing: 8){
                            
                            Text("Barkod: \(code)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                
                            // API'den gelen isim veya hata mesajı
                            Text(productName ?? "Beklenmeyen Hata")
                                .font(.headline)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Barkod Okut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image (systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .onAppear{
            // Ekran açıldığında kamerayı başlat
            scannerService.startScanning()
                        
            // Backend barkodu bulduğunda ne yapacağımızı söylüyoruz (Callback)
            scannerService.onBarcodeScanned = { barcode in
                
                guard !self.isSearching else { return }
                self.scannedCode = barcode
                self.isSearching = true
                self.productName = nil
                
                Task{
                    do {
                        
                        if let product = try await OpenFoodFactsService.shared.fetchProduct(barcode: barcode) {
                            self.productName = product.productName ?? "İsimsiz Ürün"
                        } else {
                            self.productName = "Ürün bulunamadı (Manuel girilecek)"
                        }
                    } catch {
                        self.productName = "Bağlantı hatası!"
                        print("API Hatası: \(error)")
                    }
                    
                    self.isSearching = false
                }
            }
        }
            .onDisappear {
                // Ekran kapandığında kamerayı durdur (Batarya sömürüsünü engellemek için kritik)
            scannerService.stopScanning()
        }
    }
}

#Preview {
    BarcodeScannerView()
}
