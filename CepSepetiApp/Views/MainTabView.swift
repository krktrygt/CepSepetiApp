//
//  MainTabView.swift
//  CepSepetiApp
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var scannerSession: ShoppingSession?
    
    // We need access to the modelContext to find or create an active session
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<ShoppingSession> { $0.isCompleted == false }) private var activeSessions: [ShoppingSession]

    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == 1 {
                    presentScanner()
                } else {
                    selectedTab = newValue
                }
            }
        )
    }
    
    var body: some View {
        Group {
            if let scannerSession {
                ScannerView(activeSession: scannerSession) {
                    self.scannerSession = nil
                }
            } else {
                TabView(selection: tabSelection) {
                    NavigationStack {
                        HomeView()
                    }
                    .tabItem {
                        Label("Ana Sayfa", systemImage: "house.fill")
                    }
                    .tag(0)

                    Color.clear
                        .tabItem {
                            Label("Başlat", systemImage: "cart.fill.badge.plus")
                        }
                        .tag(1)

                    NavigationStack {
                        StatisticsView()
                    }
                    .tabItem {
                        Label("İstatistikler", systemImage: "chart.pie.fill")
                    }
                    .tag(2)
                }
            }
        }
    }

    private func presentScanner() {
        guard scannerSession == nil else { return }
        scannerSession = getOrCreateActiveSession()
    }
    
    /// Helper to ensure we have a session to pass to the ScannerView
    private func getOrCreateActiveSession() -> ShoppingSession? {
        if let existing = activeSessions.first {
            return existing
        }
        
        let newSession = ShoppingSession(id: UUID(), date: Date(), totalAmount: 0.0, isCompleted: false)
        modelContext.insert(newSession)
        // Note: SwiftData auto-saves or we can try? modelContext.save()
        return newSession
    }
}

import Charts

// MARK: - Statistics View
struct StatisticsView: View {
    @Query private var allSessions: [ShoppingSession]
    @State private var viewModel = StatisticsViewModel()
    
    var body: some View {
        Group {
            if !viewModel.hasData {
                ContentUnavailableView(
                    "Henüz Veri Yok",
                    systemImage: "chart.pie",
                    description: Text("İstatistiklerin oluşması için alışveriş yapın.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Weekly Expenditure (Bar Chart)
                        SectionView(title: "Son 7 Günün Harcamaları") {
                            Chart(viewModel.weeklyData) { item in
                                BarMark(
                                    x: .value("Gün", item.date, unit: .day),
                                    y: .value("Tutar", item.amount)
                                )
                                .foregroundStyle(Color.blue.opacity(0.8))
                                .cornerRadius(4)
                            }
                            .frame(height: 200)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisValueLabel(format: .dateTime.weekday(.short))
                                }
                            }
                        }
                        
                        // 2. Top Brands (Donut Chart)
                        SectionView(title: "En Çok Tercih Edilen Markalar") {
                            Chart(viewModel.brandData) { item in
                                SectorMark(
                                    angle: .value("Tutar", item.amount),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .foregroundStyle(by: .value("Marka", item.brand))
                                .cornerRadius(5)
                            }
                            .frame(height: 200)
                            .chartForegroundStyleScale([
                                viewModel.brandData.indices.contains(0) ? viewModel.brandData[0].brand : "": Color.blue.opacity(0.7),
                                viewModel.brandData.indices.contains(1) ? viewModel.brandData[1].brand : "": Color.green.opacity(0.7),
                                viewModel.brandData.indices.contains(2) ? viewModel.brandData[2].brand : "": Color.orange.opacity(0.7),
                                viewModel.brandData.indices.contains(3) ? viewModel.brandData[3].brand : "": Color.purple.opacity(0.7)
                            ])
                        }
                        
                        // 3. Shopping Habits (Cards)
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                HabitCard(
                                    title: "En Sık Alınan",
                                    value: viewModel.mostFrequentItem,
                                    icon: "repeat",
                                    color: .orange
                                )
                                
                                HabitCard(
                                    title: "En Çok Harcanan",
                                    value: viewModel.mostExpensiveItem,
                                    icon: "tag.fill",
                                    color: .green
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("İstatistikler")
        .task(id: allSessions) {
            await viewModel.calculateStatistics(sessions: allSessions)
        }
    }
}

// MARK: - Supporting Views
struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            content
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
        }
    }
}

struct HabitCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .bold()
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: ShoppingSession.self, inMemory: true)
}
