//
//  CepSepetiAppApp.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 27.02.2026.
//

import SwiftUI
import SwiftData

@main
struct CepSepetiAppApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for :[ShoppingSession.self, ShoppingItem.self])
    }
}
