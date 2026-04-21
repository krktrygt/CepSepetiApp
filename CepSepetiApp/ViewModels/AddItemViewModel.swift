//
//  AddItemViewModel.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import Foundation
import SwiftData

@Observable
@MainActor
final class AddItemViewModel{
    
    let cameraService = CameraService()
    let pipeline = ImageProcessingPipeline()
    
    // STATE'LER (UI'ı Yönetecek Değişkenler)
    var isProcessing: Bool = false
    var ocrResult: PriceTagData? = nil
    var errorMessage: String? = nil
    var showConfirmation: Bool = false
    
    func captureAndProcess() {
        // Eğer zaten bir işlem sürüyorsa butona art arda basılmasını engelle
        guard !isProcessing else { return }
        
        isProcessing = true
        errorMessage = nil
        ocrResult = nil
        
        Task {
            do {
                // Kameradan görüntüyü al
                let image = try await cameraService.capturePhoto()
                
                // Görüntüyü boru hattına (Pipeline) gönder
                let result = await pipeline.process(image: image)
                
                // Pipeline'dan dönen sonuca göre UI state'lerini güncelle
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
    
    // 2. Onaylanan Ürünü Veritabanına Kaydet
    func confirmItem(editedName: String, editedPrice: Decimal, category: String, activeSession: ShoppingSession, context: ModelContext) {
        
        // Yeni ürün nesnesini oluştur (Barkod opsiyonel olduğu için nil kalacak)
        let newItem = ShoppingItem(
            productName: editedName,
            price: editedPrice,
            category: category,
            session: activeSession
        )
        
        // Veritabanı işlemleri
        activeSession.items?.append(newItem)
        context.insert(newItem)
        
        // Ekranı temizle ve onayı kapat
        self.showConfirmation = false
        self.ocrResult = nil
    }
}
