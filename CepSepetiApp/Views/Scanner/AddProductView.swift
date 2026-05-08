//
//  AddProductView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 28.02.2026.
//

import SwiftUI
import SwiftData

/// A form view that allows users to review and edit product data extracted via OCR before adding it to the cart.
/// Kullanıcıların sepete eklemeden önce OCR aracılığıyla çıkarılan ürün verilerini incelemesine ve düzenlemesine olanak tanıyan bir form görünümü.
struct AddProductView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    /// The ViewModel managing the OCR process and result state.
    /// OCR sürecini ve sonuç durumunu yöneten ViewModel.
    @Bindable var viewModel: AddItemViewModel
    /// The active shopping session to which the product will be added.
    /// Ürünün ekleneceği aktif alışveriş oturumu.
    let activeSession: ShoppingSession
    
    // MARK: - Local Edit State
    // MARK: - Yerel Düzenleme Durumu
    @State private var editedName: String = ""
    @State private var editedPrice: Decimal = 0.0
    @State private var quantity: Int = 1
    @State private var selectedCategory: String = "Gıda"
    
    /// List of available product categories.
    /// Mevcut ürün kategorilerinin listesi.
    let categories = ["Gıda", "İçecek", "Temizlik", "Atıştırmalık", "Kozmetik", "Diğer"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Product Details (Editable)")) {
                    TextField("Product Name", text: $editedName)
                    
                    TextField("Price (₺)", value: $editedPrice, format: .number)
                        .keyboardType(.decimalPad)
                    
                    TextField("Quantity", value: $quantity, format: .number)
                        .keyboardType(.numberPad)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                // Display identified brand if Gemini AI found it.
                // Gemini AI markayı bulduysa tanımlanan markayı gösterin.
                if let brand = viewModel.ocrResult?.brand {
                    Section(header: Text("Extra Information")) {
                        HStack {
                            Text("Brand")
                            Spacer()
                            Text(brand).foregroundColor(.gray)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        // Confirm and save the item via the ViewModel.
                        // Öğeyi ViewModel aracılığıyla onaylayın ve kaydedin.
                        viewModel.confirmItem(
                            editedName: editedName,
                            editedPrice: editedPrice,
                            category: selectedCategory,
                            quantity: quantity,
                            activeSession: activeSession,
                            context: context
                        )
                        dismiss() 
                    }) {
                        Text("Add to Cart")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Confirm Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showConfirmation = false
                        viewModel.ocrResult = nil
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Pre-populate the form with data extracted by the OCR pipeline.
                // Formu OCR hattı tarafından çıkarılan verilerle önceden doldurun.
                if let result = viewModel.ocrResult {
                    self.editedName = result.productName
                    self.editedPrice = result.price
                }
            }
        }
    }
}

/*
 SUMMARY:
 AddProductView is the final step in the item addition workflow. 
 It presents the results of AI analysis (product name, price, brand) to the user for validation.
 Once confirmed, it triggers the persistence logic in AddItemViewModel.
 
 ÖZET:
 AddProductView, öğe ekleme iş akışındaki son adımdır.
 Yapay zeka analizinin sonuçlarını (ürün adı, fiyat, marka) doğrulama için kullanıcıya sunar.
 Onaylandıktan sonra, AddItemViewModel'deki kalıcılık mantığını tetikler.
 */
