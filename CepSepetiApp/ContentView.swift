//
//  ContentView.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 27.02.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack{
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                NavigationLink("Test"){
                    BarcodeScannerView()
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
