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
    private let scanCoordinator = ScanProcessingCoordinator()

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
    /// Flag to control the display of the error alert.
    /// Hata uyarısının görüntülenmesini kontrol eden bayrak.
    var showErrorAlert: Bool = false
    /// Flag to control the display of the confirmation UI.
    /// Onay UI'ının görüntülenmesini kontrol eden bayrak.
    var showConfirmation: Bool = false

    /// Initiates photo capture and submits it to the persistent scan queue.
    /// Fotoğraf yakalamayı başlatır ve kalıcı tarama kuyruğuna gönderir.
    /// - Parameter context: The SwiftData ModelContext for logging.
    func captureAndProcess(activeSession: ShoppingSession, context: ModelContext) {
        guard !isProcessing else { return }

        isProcessing = true
        errorMessage = nil
        showErrorAlert = false
        ocrResult = nil

        Task {
            do {
                // Step 1: Capture a high-quality photo using the camera service.
                // Adım 1: Kamera servisini kullanarak yüksek kaliteli bir fotoğraf yakalayın.
                let image = try await cameraService.capturePhoto()

                // Step 2: Persist a placeholder item and process it in the background.
                // Adım 2: Geçici ürünü kaydet ve arka planda işle.
                self.scanCoordinator.submitScan(image: image, session: activeSession, context: context)
            } catch {
                self.errorMessage = "Kamera hatası: Fotoğraf çekilemedi."
                self.showErrorAlert = true
            }
            self.isProcessing = false
        }
    }

    func restorePendingItems(activeSession: ShoppingSession, context: ModelContext) {
        scanCoordinator.restorePendingItems(in: activeSession, context: context)
    }

    /// Saves the confirmed product information into the persistent database.
    /// Onaylanan ürün bilgilerini kalıcı veritabanına kaydeder.
    /// - Parameters:
    ///   - editedName: The name of the product (potentially edited by the user).
    ///   - editedPrice: The price of the product (potentially edited by the user).
    ///   - brand: The brand identified by OCR/AI, if available.
    //   - category: The category assigned to the product.
    ///   - quantity: The number of units being added.
    ///   - activeSession: The current shopping session.
    ///   - context: The ModelContext for SwiftData operations.
    func confirmItem(editedName: String, editedPrice: Decimal, brand: String?, /* category: String, */ quantity: Int, activeSession: ShoppingSession, context: ModelContext) {

        // Create a new persistent ShoppingItem instance.
        // Yeni bir kalıcı ShoppingItem örneği oluşturun.
        let newItem = ShoppingItem(
            productName: editedName,
            brand: brand,
            price: editedPrice,
            // category: category,
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
