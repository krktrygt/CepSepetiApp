//
//  ScannerView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import SwiftData

/// The primary camera interface for scanning price tags. It provides overlays and triggers the OCR analysis.
/// Fiyat etiketlerini taramak için birincil kamera arayüzü. Kaplamalar (overlays) sağlar ve OCR analizini tetikler.
struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    
    /// Manages the state and logic for capturing and processing images.
    /// Görüntüleri yakalama ve işleme durumunu ve mantığını yönetir.
    @State private var viewModel = AddItemViewModel()
    /// Controls the visibility of the shopping cart sheet.
    /// Alışveriş sepeti sayfasının görünürlüğünü kontrol eder.
    @State private var showCart: Bool = false
    
    /// The parent shopping session to which new items will be added.
    /// Yeni öğelerin ekleneceği ana alışveriş oturumu.
    let activeSession: ShoppingSession
    
    /// Controls the device flashlight state.
    /// Cihaz feneri durumunu kontrol eder.
    @State private var isFlashOn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Layer 1: Live Camera Feed
                // Katman 1: Canlı Kamera Akışı
                CameraPreview(cameraService: viewModel.cameraService)
                    .ignoresSafeArea()
                
                // Layer 2: Visual Scanning Overlay (Target Frame)
                // Katman 2: Görsel Tarama Kaplaması (Hedef Çerçeve)
                ScannerOverlayView()
                    .ignoresSafeArea()
                
                // Layer 3: Controls and Toolbar
                // Katman 3: Kontroller ve Araç Çubuğu
                VStack {
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
                        
                        // Cart button to review current session items
                        // Mevcut oturum öğelerini incelemek için sepet butonu
                        Button(action: {
                            showCart = true
                        }) {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        
                        Spacer()
                        
                        // Flashlight toggle button
                        // Fener açma/kapatma butonu
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
                    
                    // Capture button to take a photo and start OCR analysis
                    // Fotoğraf çekmek ve OCR analizini başlatmak için yakalama butonu
                    Button(action: {
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
                    .disabled(viewModel.isProcessing)
                    .opacity(viewModel.isProcessing ? 0.5 : 1.0)
                }
                
                // Layer 4: AI Analysis Loading Screen
                // Katman 4: Yapay Zeka Analizi Yükleme Ekranı
                if viewModel.isProcessing {
                    ZStack {
                        Color.black.opacity(0.8) 
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView() 
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("AI is analyzing the price tag...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            // Present confirmation sheet when OCR analysis is successful
            // OCR analizi başarılı olduğunda onay sayfasını sunun
            .sheet(isPresented: $viewModel.showConfirmation) {
                if viewModel.ocrResult != nil {
                    AddProductView(viewModel: viewModel, activeSession: activeSession)
                }
            }
            // Show alert on processing failure
            // İşleme hatasında uyarı gösterin
            .alert("Analysis Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
            .onAppear {
                viewModel.cameraService.start()
            }
            .onDisappear {
                viewModel.cameraService.stop()
            }
        }
        .sheet(isPresented: $showCart) {
            CartSheetView(activeSession: activeSession)
        }
    }
}

/// A helper view that draws the target rectangle and darkens the surrounding area.
/// Hedef dikdörtgeni çizen ve çevreleyen alanı karartan yardımcı bir görünüm.
struct ScannerOverlayView: View {
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let frameSize = size.width * 0.7 
            
            ZStack {
                Color.black.opacity(0.5)
                
                // Cutout square in the middle
                // Ortadaki oyuk kare
                RoundedRectangle(cornerRadius: 16)
                    .frame(width: frameSize, height: frameSize)
                    .blendMode(.destinationOut) 
                
                // Border for the cutout
                // Oyuk için kenarlık
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: frameSize, height: frameSize)
            }
            .compositingGroup() 
        }
    }
}

/*
 SUMMARY:
 ScannerView is the core interactive component of the app. It provides a viewfinder 
 with a target region of interest (ROI) and allows users to trigger the AI-driven 
 product extraction workflow. It integrates camera feeds, overlays, and loading states.
 
 ÖZET:
 ScannerView, uygulamanın temel etkileşimli bileşenidir. İlgi bölgesi (ROI) hedefi olan bir vizör sağlar ve 
 kullanıcıların yapay zeka destekli ürün çıkarma iş akışını tetiklemesine olanak tanır. 
 Kamera akışlarını, kaplamaları ve yükleme durumlarını entegre eder.
 */
