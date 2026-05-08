//
//  AddProductView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import SwiftData

struct AddProductView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // ViewModel'i dışarıdan alıyoruz, çünkü süreci kamera ekranı (CameraPreviewView) başlatacak
    @Bindable var viewModel: AddItemViewModel
    let activeSession: ShoppingSession
    
    // Kullanıcının textfield'lar üzerinde değişiklik yapabilmesi için yerel state'ler
    @State private var editedName: String = ""
    @State private var editedPrice: Decimal = 0.0
    @State private var quantity: Int = 1
    @State private var selectedCategory: String = "Gıda"
    
    // Şimdilik basit bir kategori listesi
    let categories = ["Gıda", "İçecek", "Temizlik", "Atıştırmalık", "Kozmetik", "Diğer"]
    
    var body: some View {
        
        NavigationStack{
            Form{
                Section(header: Text("Ürün Bilgileri (Düzenlenebilir")){
                    TextField("Ürün Adı", text: $editedName)
                    
                    TextField("Fiyat (₺)", value: $editedPrice, format: .number)
                        .keyboardType(.decimalPad)
                    
                    TextField("Miktar", value: $quantity, format: .number)
                        .keyboardType(.numberPad)
                    
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                // Eğer Gemini markayı bulabildiyse ekstra bilgi olarak göster
                if let brand = viewModel.ocrResult?.brand {
                    Section(header: Text("Ekstra Bilgiler")) {
                        HStack {
                            Text("Marka")
                            Spacer()
                            Text(brand).foregroundColor(.gray)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        // Kullanıcı onayladığında ViewModel üzerinden SwiftData'ya kaydet
                        viewModel.confirmItem(
                            editedName: editedName,
                            editedPrice: editedPrice,
                            category: selectedCategory,
                            quantity: quantity,
                            activeSession: activeSession,
                            context: context
                        )
                        dismiss() // Modalı kapat
                    }) {
                        Text("Sepete Ekle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Ürünü Onayla")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        viewModel.showConfirmation = false
                        viewModel.ocrResult = nil
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Ekran açıldığında OCR'dan gelen verileri TextField'lara doldur
                if let result = viewModel.ocrResult {
                    self.editedName = result.productName
                    self.editedPrice = result.price
                }
            }
        }
    }
}
/*
#Preview {
    AddProductView()
}
*/
