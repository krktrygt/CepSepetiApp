//
//  LocalOCRParserServiceTests.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 21.04.2026.
//

import Foundation

/// A dedicated test suite for validating the fully local Swift-based parser service.
/// Tamamen yerel Swift tabanlı ayrıştırıcı servisini doğrulamak için test paketi.
/// Note: Implemented without XCTest so it can compile within the main app target or run as a standalone script.
final class LocalOCRParserServiceTests {
    
    private let parserService = LocalOCRParserService()
    
    /// A structured model for testing OCR parsing
    struct MockLabel {
        let name: String
        let rawText: String
        let expectedPrice: Decimal
        let expectedBrand: String?
        let expectsLowConfidence: Bool
    }
    
    /// Tests the parser against 10 mock retail labels with varying difficulty levels.
    func runTests() {
        let mockLabels: [MockLabel] = [
            // 1. Clean output
            MockLabel(name: "Clean Standard",
                      rawText: "SUTAS\nSüt 1L\n34,50 TL",
                      expectedPrice: 34.50,
                      expectedBrand: "SÜTAŞ",
                      expectsLowConfidence: false),
            
            // 2. OCR Corrupted Brand
            MockLabel(name: "Corrupted Brand",
                      rawText: "M1LK\nYarim Yagli Sut\n24.90",
                      expectedPrice: 24.90,
                      expectedBrand: "MILK",
                      expectsLowConfidence: false),
            
            // 3. No price (Should have 0.0 confidence)
            MockLabel(name: "Missing Price",
                      rawText: "ETI\nBurcak Bisküvi",
                      expectedPrice: 0.0,
                      expectedBrand: "ETİ",
                      expectsLowConfidence: true),
            
            // 4. Conflicting prices (Discount scenario)
            MockLabel(name: "Multiple Prices",
                      rawText: "ULKER\nCikolata\n15,00 TL\n%10 İndirim\n13,50 TL",
                      expectedPrice: 13.50, // Discount logic expects the smaller selling price
                      expectedBrand: "ÜLKER",
                      expectsLowConfidence: true),
            
            // 5. Unit price included
            MockLabel(name: "Unit Price Ignore",
                      rawText: "PINAR\nBeyaz Peynir 500G\n105,90 TL\n1KG=211,80 TL",
                      expectedPrice: 105.90,
                      expectedBrand: "PINAR",
                      expectsLowConfidence: false),
            
            // 6. Barcode included
            MockLabel(name: "Barcode Ignore",
                      rawText: "TORKU\nToz Seker 1KG\n35₺\n8690123456789",
                      expectedPrice: 35.00,
                      expectedBrand: "TORKU",
                      expectsLowConfidence: false),
            
            // 7. Missing decimal
            MockLabel(name: "Plain Integer Price",
                      rawText: "AYTAÇ\nSucuk\n120 TL",
                      expectedPrice: 120.00,
                      expectedBrand: "AYTAÇ",
                      expectsLowConfidence: false),
            
            // 8. English unit/keyword
            MockLabel(name: "English Formatting",
                      rawText: "NESTLE\nWater 1.5 LT\n10,25",
                      expectedPrice: 10.25,
                      expectedBrand: "NESTLÉ",
                      expectsLowConfidence: false),
            
            // 9. Extreme corruption (Symbols)
            MockLabel(name: "Extreme Corruption",
                      rawText: "H#LLO\nW@R!D\n999,99",
                      expectedPrice: 999.99,
                      expectedBrand: "H#LLO",
                      expectsLowConfidence: true), // Confidence drop due to high symbol ratio
            
            // 10. Just the price and random text
            MockLabel(name: "Only Price",
                      rawText: "19,95 TL\nab",
                      expectedPrice: 19.95,
                      expectedBrand: nil,
                      expectsLowConfidence: true) // Confidence drop due to short name
        ]
        
        var successCount = 0
        var totalConfidence: Double = 0.0
        
        print("🧪 --- Starting LocalOCRParserService Tests --- 🧪")
        
        for (index, mock) in mockLabels.enumerated() {
            let result = parserService.parse(ocrText: mock.rawText)
            let confidence = result.confidenceScore ?? 0.0
            
            print("\n[\(index + 1)] Testing: \(mock.name)")
            print("   Expected Price: \(mock.expectedPrice) | Found: \(result.price)")
            print("   Expected Brand: \(mock.expectedBrand ?? "None") | Found: \(result.brand ?? "None")")
            print("   Calculated Confidence: \(confidence)")
            
            var passed = true
            
            if result.price != mock.expectedPrice {
                print("   ❌ FAILED: Price mismatch")
                passed = false
            }
            
            if result.brand != mock.expectedBrand {
                print("   ❌ FAILED: Brand mismatch")
                passed = false
            }
            
            if mock.expectsLowConfidence && confidence >= 0.7 {
                print("   ❌ FAILED: Expected low confidence, but got \(confidence)")
                passed = false
            } else if !mock.expectsLowConfidence && confidence < 0.7 {
                print("   ❌ FAILED: Expected high confidence, but got \(confidence)")
                passed = false
            }
            
            if passed {
                print("   ✅ PASSED")
                successCount += 1
            }
            
            totalConfidence += confidence
        }
        
        // Print Statistics
        let averageConfidence = totalConfidence / Double(mockLabels.count)
        print("\n📊 --- Parser Accuracy Statistics --- 📊")
        print("Total Labels Tested: \(mockLabels.count)")
        print("Successful Extractions: \(successCount)")
        print("Average Confidence Score: \(String(format: "%.2f", averageConfidence))")
        print("Overall Accuracy: \(String(format: "%.1f%%", (Double(successCount) / Double(mockLabels.count)) * 100))")
    }
}
