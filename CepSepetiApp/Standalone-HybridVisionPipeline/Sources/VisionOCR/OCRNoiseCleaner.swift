//
//  OCRNoiseCleaner.swift
//  HybridVisionPipeline
//

import Foundation

/// Identifies OCR lines that are scanner, system, or price-tag metadata noise.
public final class OCRNoiseCleaner: Sendable {
    private let exactNoiseWords: Set<String> = [
        "YERLI",
        "URETIM",
        "KDV",
        "TL",
        "₺",
        "MENSE"
    ]
    
    private let noiseFragments = [
        "FIGXPCUTILITIES",
        "CGAFFINETRANSFORMINVERT",
        "XCODE SIMULATOR",
        "STATUS BAR",
        "--- BASLANGIC:",
        "--- BITIS",
        "FIYAT GECERLILIK TARIHI",
        "KDV DAHIL",
        "YERLI URETIM",
        "KG FIYATI",
        "BIRIM FIYATI",
        "BIRIM F. DEG",
        "F.D.T.",
        "URT. YERI",
        "URT. YERİ",
        "TL/KG",
        "TL/LT"
    ]
    
    private let dateLineRegex = try! NSRegularExpression(
        pattern: #"^\d{1,2}\s+[A-ZÇĞİÖŞÜ]+(?:\s+\d{4})?\s*-?$"#,
        options: [.caseInsensitive]
    )
    
    public init() {}
    
    public func isNoise(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        
        let normalized = normalize(trimmed)
        
        if exactNoiseWords.contains(normalized) {
            return true
        }
        
        if noiseFragments.contains(where: { normalized.contains($0) }) {
            return true
        }
        
        let range = NSRange(location: 0, length: normalized.utf16.count)
        return dateLineRegex.firstMatch(in: normalized, options: [], range: range) != nil
    }
    
    private func normalize(_ text: String) -> String {
        text.uppercased(with: Locale(identifier: "tr-TR"))
            .replacingOccurrences(of: "İ", with: "I")
            .replacingOccurrences(of: "Ğ", with: "G")
            .replacingOccurrences(of: "Ü", with: "U")
            .replacingOccurrences(of: "Ş", with: "S")
            .replacingOccurrences(of: "Ö", with: "O")
            .replacingOccurrences(of: "Ç", with: "C")
    }
}
