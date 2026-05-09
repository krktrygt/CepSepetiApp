//
//  AddItemViewModel.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import Foundation
import SwiftData

/// ViewModel responsible for managing the state and logic of capturing and adding a new item via OCR.
/// OCR aracılığıyla yeni bir öğe yakalama ve ekleme durumunu ve mantığını yönetmekten sorumlu ViewModel.
@Observable
@MainActor
final class AddItemViewModel {
    
    /// Service to manage camera operations.
    /// Kamera operasyonlarını yöneten servis.
    let cameraService = CameraService()
    /// Pipeline to orchestrate OCR and AI processing.
    /// OCR ve yapay zeka işlemesini koordine eden hat (pipeline).
    let pipeline = ImageProcessingPipeline()
    
    // MARK: - State Properties
    // MARK: - Durum Özellikleri
    
    /// Indicates if an image is currently being processed by the OCR pipeline.
    /// Bir görüntünün şu anda OCR hattı tarafından işlenip işlenmediğini belirtir.
    var isProcessing: Bool = false
    /// Holds the result of the OCR/AI analysis once complete.
    /// Tamamlandığında OCR/Yapay Zeka analizinin sonucunu tutar.
    var ocrResult: PriceTagData? = nil
    /// Stores any error message encountered during the process.
    /// İşlem sırasında karşılaşılan herhangi bir hata mesajını saklar.
    var errorMessage: String? = nil
    /// Flag to control the display of the confirmation UI.
    /// Onay UI'ının görüntülenmesini kontrol eden bayrak.
    var showConfirmation: Bool = false
    
    /// Initiates the photo capture and sends it through the processing pipeline.
    /// Fotoğraf yakalamayı başlatır ve işleme hattına gönderir.
    func captureAndProcess() {
        // Prevent multiple simultaneous processing requests.
        // Aynı anda birden fazla işleme isteğini önleyin.
        guard !isProcessing else { return }
        
        isProcessing = true
        errorMessage = nil
        ocrResult = nil
        
        Task {
            do {
                // Step 1: Capture a high-quality photo using the camera service.
                // Adım 1: Kamera servisini kullanarak yüksek kaliteli bir fotoğraf yakalayın.
                let image = try await cameraService.capturePhoto()
                
                // Step 2: Pass the image to the processing pipeline (OCR + AI).
                // Adım 2: Görüntüyü işleme hattına (OCR + Yapay Zeka) geçirin.
                let result = await pipeline.process(image: image)
                
                // Step 3: Update state based on the pipeline's outcome.
                // Adım 3: Hattın sonucuna göre durumu güncelleyin.
                switch result {
                case .success(let data):
                    self.ocrResult = data
                    self.showConfirmation = true
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            } catch {
                self.errorMessage = "Kamera hatası: Fotoğraf çekilemedi."
            }
            self.isProcessing = false
        }
    }
    
    /// Saves the confirmed product information into the persistent database.
    /// Onaylanan ürün bilgilerini kalıcı veritabanına kaydeder.
    /// - Parameters:
    ///   - editedName: The name of the product (potentially edited by the user).
    ///   - editedPrice: The price of the product (potentially edited by the user).
    ///   - category: The category assigned to the product.
    ///   - quantity: The number of units being added.
    ///   - activeSession: The current shopping session.
    ///   - context: The ModelContext for SwiftData operations.
    func confirmItem(editedName: String, editedPrice: Decimal, category: String, quantity: Int, activeSession: ShoppingSession, context: ModelContext) {
        
        // Create a new persistent ShoppingItem instance.
        // Yeni bir kalıcı ShoppingItem örneği oluşturun.
        let newItem = ShoppingItem(
            productName: editedName,
            price: editedPrice,
            category: category,
            quantity: quantity,
            session: activeSession
        )
        
        // Add to the session and insert into the persistent store.
        // Oturuma ekleyin ve kalıcı depoya yerleştirin.
        activeSession.items?.append(newItem)
        context.insert(newItem)
        
        // Reset state and hide the confirmation UI.
        // Durumu sıfırlayın ve onay UI'ını gizleyin.
        self.showConfirmation = false
        self.ocrResult = nil
    }
}

/*
 SUMMARY:
 AddItemViewModel bridges the gap between raw camera input and the final persistent data model.
 It manages the asynchronous state of OCR processing and provides methods for the user to confirm 
 and save the results. It interacts with CameraService, ImageProcessingPipeline, and SwiftData.
 
 ÖZET:
 AddItemViewModel, ham kamera girişi ile nihai kalıcı veri modeli arasındaki boşluğu doldurur.
 OCR işleminin asenkron durumunu yönetir ve kullanıcının sonuçları onaylaması ve kaydetmesi için yöntemler sağlar.
 CameraService, ImageProcessingPipeline ve SwiftData ile etkileşime girer.
 */
