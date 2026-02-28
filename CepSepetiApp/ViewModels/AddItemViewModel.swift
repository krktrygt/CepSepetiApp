//
//  AddItemViewModel.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import Foundation
import SwiftData

@Observable
final class AddItemViewModel{
    var productName: String = ""
    var priceString: String = "" // Kullanıcıdan metin olarak alıp kaydederken Decimal'a çevireceğiz
    var quantity: Int = 1
    var category: String = "Gıda"
    var barcode: String = ""
    
    // Analizlerin düzgün çalışması için sistemin kabul edeceği sabit kategoriler
    let categories = ["Gıda", "İçecek", "Atıştırmalık", "Temizlik", "Kişisel Bakım", "Manav", "Diğer"]
    
    // Barkod okunduğunda veya API cevap verdiğinde bu sınıf başlatılacak
    init(scannedBarcode: String, apiName: String?){
        self.barcode = scannedBarcode
        if let name = apiName, !name.isEmpty{
            self.productName = name
        }
    }
    
    func saveItem(context: ModelContext, activeSession: ShoppingSession){
        // 1. Fiyat Dönüşüm Riski: Kullanıcı virgül veya nokta girebilir.
        // Hatalı girişte uygulamanın çökmesini engellemek için formatlama.
        
        let formattedPrice = priceString.replacingOccurrences(of: ",", with: ".")
        let price = Decimal(string: formattedPrice) ?? 0.0
        
        // 2. Yeni ürünü oluştur
        let newItem = ShoppingItem(
            id: UUID(),
            productName: productName,
            price: price,
            category: category,
            barcode: barcode,
            quantity: quantity
        )
        
        // 3. İlişkiyi kur (Ürünü mevcut sepete bağla)
        // DİKKAT: activeSession.items nil ise diye boş dizi ataması yapmıyoruz çünkü ShoppingSession init'inde boş dizi olarak tanımladık.
        activeSession.items?.append(newItem)
        newItem.session = activeSession
        
        // 4. Sepetin genel toplamını güncelle
        let itemTotal = price * Decimal(quantity)
        activeSession.totalAmount += itemTotal
        
        // 5. Veritabanına yaz
        do {
            try context.save()
        } catch {
            print("Kritik Hata: Veritabanına kayıt yapılamadı. Neden: \(error.localizedDescription)")
        }
    }
}
