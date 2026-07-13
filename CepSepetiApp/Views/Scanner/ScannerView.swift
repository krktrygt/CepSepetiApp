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
    @Environment(\.modelContext) private var context
    
    /// Manages the state and logic for capturing and processing images.
    /// Görüntüleri yakalama ve işleme durumunu ve mantığını yönetir.
    @State private var viewModel = AddItemViewModel()
    /// Controls the visibility of the shopping cart sheet.
    /// Alışveriş sepeti sayfasının görünürlüğünü kontrol eder.
    @State private var showCart: Bool = false
    @State private var isCameraPreviewVisible = true
    @State private var isClosingScanner = false
    
    /// The parent shopping session to which new items will be added.
    /// Yeni öğelerin ekleneceği ana alışveriş oturumu.
    let activeSession: ShoppingSession
    let onClose: () -> Void
    
    /// Controls the device flashlight state.
    /// Cihaz feneri durumunu kontrol eder.
    @State private var isFlashOn = false
    
    /// Flag to show the cancellation confirmation alert.
    /// İptal onay uyarısını göstermek için bayrak.
    @State private var showCancelAlert = false

    private func closeScanner() {
        guard !isClosingScanner else { return }
        isClosingScanner = true
        showCart = false
        viewModel.showConfirmation = false
        showCancelAlert = false
        viewModel.cancelCapture()
        viewModel.cameraService.stop {
            isCameraPreviewVisible = false
            onClose()
        }
    }
    
    /// Action to cancel the shopping session and cleanup items.
    /// Alışveriş oturumunu iptal etme ve öğeleri temizleme eylemi.
    private func cancelShopping() {
        if let items = activeSession.items {
            for item in items {
                context.delete(item)
            }
        }
        context.delete(activeSession)
        try? context.save()
        closeScanner()
    }
    
    var body: some View {
        ZStack {
                // Layer 1: Live Camera Feed
                // Katman 1: Canlı Kamera Akışı
                if isCameraPreviewVisible {
                    CameraPreview(cameraService: viewModel.cameraService)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                } else {
                    Color.black
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                
                // Layer 2: Visual Scanning Overlay (Target Frame)
                // Katman 2: Görsel Tarama Kaplaması (Hedef Çerçeve)
                ScannerOverlayView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // Layer 3: Controls and Toolbar
                // Katman 3: Kontroller ve Araç Çubuğu
                VStack {
                    HStack {
                        Button(action: {
                            closeScanner()
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                        
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
                    
                    HStack(spacing: 30) {
                        // Cancel Shopping Button (Moved to bottom left)
                        // Alışverişi İptal Et Butonu (Sol alta taşındı)
                        Button(action: {
                            showCancelAlert = true
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .frame(width: 60, height: 60)
                        
                        // Capture button to take a photo and start OCR analysis
                        // Fotoğraf çekmek ve OCR analizini başlatmak için yakalama butonu
                        Button(action: {
                            viewModel.captureAndProcess(activeSession: activeSession, context: context)
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
                        .disabled(viewModel.isProcessing)
                        .opacity(viewModel.isProcessing ? 0.5 : 1.0)

                        // Cart button with dynamic badge
                        // Dinamik rozetli sepet butonu
                        Button(action: {
                            showCart = true
                        }) {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .overlay(alignment: .topTrailing) {
                                    if let itemCount = activeSession.items?.count, itemCount > 0 {
                                        Text("\(itemCount)")
                                            .font(.caption2).bold()
                                            .foregroundColor(.white)
                                            .frame(width: 20, height: 20)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                            .offset(x: 5, y: -5)
                                    }
                                }
                        }
                        .frame(width: 60, height: 60)
                    }
                    .padding(.bottom, 50)
                }
                
                // Layer 4: Short capture feedback
                // Katman 4: Kısa çekim geri bildirimi
                if viewModel.isProcessing {
                    ZStack {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView() 
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("Etiket sepete ekleniyor...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
        }
        .allowsHitTesting(!isClosingScanner)
        // Present confirmation sheet when OCR analysis is successful
        // OCR analizi başarılı olduğunda onay sayfasını sunun
        .sheet(isPresented: $viewModel.showConfirmation) {
            if viewModel.ocrResult != nil {
                AddProductView(viewModel: viewModel, activeSession: activeSession)
                    .presentationDetents([.fraction(0.85), .medium])
            }
        }
        // Show alert on processing failure or fallback
        // İşleme hatasında veya geri dönüşte (fallback) uyarı gösterin
        .alert("Bilgi", isPresented: $viewModel.showErrorAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
        .onAppear {
            isCameraPreviewVisible = true
            isClosingScanner = false
            viewModel.cameraService.start()
            viewModel.restorePendingItems(activeSession: activeSession, context: context)
        }
        .onDisappear {
            isCameraPreviewVisible = false
            viewModel.cameraService.stop()
        }
        .sheet(isPresented: $showCart) {
            CartSheetView(activeSession: activeSession)
                .presentationDetents([.medium, .large])
        }
        .onChange(of: activeSession.isCompleted) { _, newValue in
            if newValue {
                closeScanner()
            }
        }
        .alert("Alışverişi İptal Et", isPresented: $showCancelAlert) {
            Button("Evet, İptal Et", role: .destructive) {
                cancelShopping()
            }
            Button("Hayır", role: .cancel) { }
        } message: {
            Text("Bu alışverişi ve eklenen tüm ürünleri silmek istediğinize emin misiniz?")
        }
    }
}

/// A helper view that draws the target rectangle and darkens the surrounding area.
/// Hedef dikdörtgeni çizen ve çevreleyen alanı karartan yardımcı bir görünüm.
struct ScannerOverlayView: View {
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let frameSize = min(size.width * 0.7, size.height * 0.45)
            let verticalInset = max((size.height - frameSize) / 2, 0)
            let horizontalInset = max((size.width - frameSize) / 2, 0)

            ZStack {
                VStack(spacing: 0) {
                    Color.black.opacity(0.5)
                        .frame(height: verticalInset)

                    HStack(spacing: 0) {
                        Color.black.opacity(0.5)
                            .frame(width: horizontalInset)

                        Color.clear
                            .frame(width: frameSize, height: frameSize)

                        Color.black.opacity(0.5)
                            .frame(width: horizontalInset)
                    }
                    .frame(height: frameSize)

                    Color.black.opacity(0.5)
                        .frame(height: verticalInset)
                }
                .frame(width: size.width, height: size.height)

                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: frameSize, height: frameSize)
            }
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
