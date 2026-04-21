//
//  ScannerView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import SwiftData

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    
    // ViewModel bu ekranın sahibi, isProcessing ve ocrResult state'lerini buradan yönetecek
    @State private var viewModel = AddItemViewModel()
    
    // Bu tarama oturumunun ait olduğu ana alışveriş oturumu
    let activeSession: ShoppingSession
    
    // El feneri state'i
    @State private var isFlashOn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. KATMAN: Canlı Kamera Önizlemesi (Az önce yazdığımız UIKit köprüsü)
                CameraPreview(cameraService: viewModel.cameraService)
                    .ignoresSafeArea()
                
                // 2. KATMAN: Scanner Çerçevesi (ROI) ve Transparan Arka Plan
                ScannerOverlayView()
                    .ignoresSafeArea()
                
                // 3. KATMAN: UI Elementleri (Butonlar, Yazılar) - Scanner
                VStack {
                    // Üst Kısım: Araç Çubuğu
                    HStack {
                        Button(action: {
                            viewModel.cameraService.stop()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isFlashOn.toggle()
                            viewModel.cameraService.toggleFlash(isOn: isFlashOn)
                        }) {
                            Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 25))
                                .foregroundColor(isFlashOn ? .yellow : .white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // Alt Kısım: Fotoğraf Çek Butonu
                    Button(action: {
                        // ViewModel üzerinden fotoğraf çekme ve analiz sürecini başlat
                        viewModel.captureAndProcess()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray, lineWidth: 2)
                                    .frame(width: 70, height: 70)
                            )
                            .shadow(radius: 10)
                    }
                    .padding(.bottom, 50)
                    // Analiz sürerken butonu dondur (Spam koruması)
                    .disabled(viewModel.isProcessing)
                    .opacity(viewModel.isProcessing ? 0.5 : 1.0)
                }
                
                // 4. KATMAN: Analiz Yükleniyor Overlay'i (Scanner Loading State)
                if viewModel.isProcessing {
                    ZStack {
                        Color.black.opacity(0.8) // Arka planı karart
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView() // iOS standart spinner
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("Yapay Zeka Fiyatı Analiz Ediyor...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            // 5. BAĞLANTI: Analiz başarılıysa onay ekranını aç (Scanner)
            .sheet(isPresented: $viewModel.showConfirmation) {
                if viewModel.ocrResult != nil {
                    // Gemini verilerini onay ekranına pasla
                    AddProductView(viewModel: viewModel, activeSession: activeSession)
                }
            }
            // 6. BAĞLANTI: Hata varsa Alert olarak göster (Scanner)
            .alert("Analiz Hatası", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("Tamam", role: .cancel) { }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
            // Ekran açılırken kamerayı başlat, kapanırken durdur
            .onAppear {
                viewModel.cameraService.start()
            }
            .onDisappear {
                viewModel.cameraService.stop()
            }
        }
    }
}

// Ortadaki tarama çerçevesini ve transparan arka planı çizen yardımcı SwiftUI View
struct ScannerOverlayView: View {
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let frameSize = size.width * 0.7 // Çerçevenin ekranın %70'i kadar olması
            
            ZStack {
                // Ekranı karartan transparan katman
                Color.black.opacity(0.5)
                
                // Tam ortayı oy (kare yap)
                RoundedRectangle(cornerRadius: 16)
                    .frame(width: frameSize, height: frameSize)
                    .blendMode(.destinationOut) // Oyma efekti
                
                // Oymuş karenin etrafına beyaz bir çerçeve çiz
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: frameSize, height: frameSize)
            }
            .compositingGroup() // blendMode'un düzgün çalışması için şart
        }
    }
}


/*
#Preview {
    ScannerView(activeSession: ShoppingSession())
}
*/
