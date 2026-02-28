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
    
    // İş mantığını yönetecek ViewModel'imiz
    @State private var viewModel: AddItemViewModel
    
    // Ürünün ekleneceği aktif alışveriş sepeti/
    var activeSession: ShoppingSession
    
    // View oluşturulurken dışarıdan alınacak veriler
    init(scannedBarcode: String, apiName: String?, session: ShoppingSession) {
        // ViewModel'i dışarıdan gelen verilerle başlatıyoruz
        _viewModel = State(initialValue: AddItemViewModel(scannedBarcode: scannedBarcode, apiName: apiName))
        self.activeSession = session
    }
    
    var body: some View {
        NavigationStack{
            Form{
                // 1. Ürün bilgileri bölümü
                Section(header: Text("Ürün Bilgileri")){
                    TextField("Ürün Adı:", text: $viewModel.productName)
                        .textInputAutocapitalization(.words)
                    
                    Text("Barkod: \(viewModel.barcode)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 2. Fiyat ve Adet Bölümü
                Section(header: Text("Fiyat ve Miktar")){
                    HStack{
                        Text("Fiyat (₺):")
                        Spacer()
                        TextField("0.00", text: $viewModel.priceString)
                            .keyboardType(.decimalPad) // Sadece rakam ve virgül/nokta klavyesi
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.blue)
                    }
                    
                    Stepper(value: $viewModel.quantity, in: 1...100){
                        Text("Adet: \(viewModel.quantity)")
                    }
                }
                
                // 3. Kategori Bölümü
                Section(header: Text("Kategori")){
                    Picker("Kategori seç", selection: $viewModel.category) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Ürünü Sepete Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                // Sol üst iptal butonu
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                                
                // Sağ üst kaydet butonu
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") {
                        // İş mantığını ViewModel'e devret
                        viewModel.saveItem(context: context, activeSession: activeSession)
                        dismiss() // Ekranı kapat
                    }
                    // Ürün adı veya fiyat boşsa butonu pasif (disabled) yap
                    .disabled(viewModel.productName.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.priceString.isEmpty)
                }
                                
                // UX İyileştirmesi: DecimalPad klavyesini kapatmak için "Bitti" butonu
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Bitti") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
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
