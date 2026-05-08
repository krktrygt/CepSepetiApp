//
//  CepSepetiAppApp.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 27.02.2026.
//

import SwiftUI
import SwiftData

/// The main entry point of the CepSepetiApp.
/// CepSepetiApp'in ana giriş noktası.
@main
struct CepSepetiAppApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        // Initialize the SwiftData container for persisting sessions and items.
        // Oturumları ve öğeleri saklamak için SwiftData kapsayıcısını başlatın.
        .modelContainer(for :[ShoppingSession.self, ShoppingItem.self])
    }
}

/*
 SUMMARY:
 This is the application lifecycle controller. It sets up the root view (HomeView) 
 and configures the shared SwiftData model container used for persistence across the app.
 
 ÖZET:
 Bu, uygulama yaşam döngüsü kontrolörüdür. Kök görünümü (HomeView) ayarlar ve uygulama genelinde 
 kalıcılık için kullanılan paylaşılan SwiftData model kapsayıcısını yapılandırır.
 */
