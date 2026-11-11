//
//  LocalOCRParserServiceTests.swift
//  CepSepetiAppTests
//
//  Created by Gemini CLI on 11.05.2026.
//

import XCTest
@testable import CepSepetiApp

final class LocalOCRParserServiceTests: XCTestCase {
    
    var sut: LocalOCRParserService!
    
    override func setUp() {
        super.setUp()
        sut = LocalOCRParserService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    /// Test case for clean and perfect OCR output.
    func testPerfectOCR() async throws {
        let rawText = """
        SUTAS
        TAM YAGLI SUT 1L
        34,50 TL
        """
        
        let result = sut.parse(ocrText: rawText)
        
        XCTAssertEqual(result.brand, "SÜTAŞ", "Brand normalization failed for SUTAS")
        XCTAssertEqual(result.price, 34.50, "Price extraction failed for 34,50 TL")
        XCTAssertTrue(result.productName.contains("TAM YAGLI SUT 1L"), "Product name missing expected tokens: \(result.productName)")
        XCTAssertGreaterThanOrEqual(result.confidenceScore ?? 0.0, 0.8, "Confidence score too low: \(result.confidenceScore ?? 0.0)")
    }
    
    /// Test case for OCR output containing noise like dates, KDV (tax), and trash words.
    func testOCRWithNoiseAndDates() async throws {
        let rawText = """
        MIGROS TICARET A.S.
        TARIH: 10.05.2026 14:30
        FIS NO: 0042
        ULKER
        ALBENI 5LI PAKET
        22,90 TL
        KDV %10 DAHIL
        TOPLAM
        """
        
        let result = sut.parse(ocrText: rawText)
        
        XCTAssertEqual(result.brand, "ÜLKER", "Expected brand ÜLKER but found \(result.brand ?? "nil")")
        XCTAssertEqual(result.price, 22.90, "Expected price 22.90 but found \(result.price)")
        XCTAssertTrue(result.productName.contains("ALBENI 5LI PAKET"), "Product name missing expected tokens: \(result.productName)")
        XCTAssertFalse(result.productName.contains("10.05.2026"), "Product name should not contain date: \(result.productName)")
        XCTAssertFalse(result.productName.contains("KDV"), "Product name should not contain KDV: \(result.productName)")
    }
    
    /// Test case for identifying multipack multipliers and sizes (e.g., 6X250ML).
    func testOCRWithMultipack() async throws {
        let rawText = """
        COCA COLA
        6X250ML KUTU
        115,00 TL
        """
        
        let result = sut.parse(ocrText: rawText)
        
        XCTAssertEqual(result.brand, "COCA-COLA", "Expected brand COCA-COLA but found \(result.brand ?? "nil")")
        XCTAssertEqual(result.price, 115.00, "Expected price 115.00 but found \(result.price)")
        XCTAssertTrue(result.productName.contains("6X250ML"), "Product name missing multipack info: \(result.productName)")
    }
    
    /// Test case for fallback logic when multiple prices are found (e.g., unit price vs selling price).
    /// Should pick the lower price if verification fails or as a safe fallback.
    func testFallbackMinPrice() async throws {
        let rawText = """
        PINAR
        BEYAZ PEYNIR 500G
        120,00 TL
        1KG=240,00 TL
        """
        
        let result = sut.parse(ocrText: rawText)
        
        XCTAssertEqual(result.brand, "PINAR", "Expected brand PINAR but found \(result.brand ?? "nil")")
        XCTAssertEqual(result.price, 120.00, "Expected price 120.00 but found \(result.price)")
        XCTAssertTrue(result.productName.contains("BEYAZ PEYNIR"), "Product name missing expected name tokens: \(result.productName)")
        XCTAssertTrue(result.productName.contains("500"), "Product name missing expected size tokens: \(result.productName)")
    }
    
    /// Test case for Coca-Cola tag with barcodes and price typos (Case 1 & 7 from metin.txt).
    func testCocaColaWithBarcodesAndPriceTypos() async throws {
        let rawText = "COCA COLA 1,5 LT 08010903 Üretim :TÜRKİYE Birim F. Değ : D-04-2026 fiyat 03g : 20-04-2026 KDY DAHİLDİR Birim Fiyatı : 46.67 TLAT 19DA 5 449000 000439 70.00 ÜRETiM"
        
        let result = sut.parse(ocrText: rawText)
        
        XCTAssertEqual(result.brand, "COCA-COLA", "Expected COCA-COLA but found \(result.brand ?? "nil")")
        XCTAssertEqual(result.price, 70.00, "Expected price 70.00 but found \(result.price)")
        XCTAssertTrue(result.productName.contains("COCA COLA"), "Expected name to contain COCA COLA but was \(result.productName)")
        XCTAssertFalse(result.productName.contains("19DA"), "Product name should not contain 19DA")
        XCTAssertFalse(result.productName.contains("08010903"), "Product name should not contain barcode")
    }
    
    /// Test case for Tamek tag with price split and unit price (Case 2 from metin.txt).
    func testTamekWithPriceSplitsAndUnitFiyat() async throws {
        let rawText = "TAMEK HAŞLANMIS BARBUNYA 800 G YERLİ ÜRETİM KDV DAHİLDİR. MENŞE: TURKIYE F.D.T.: 12.03.2026 99 95 B. FIYAT: 124.94TL/KG"
        
        let result = sut.parse(ocrText: rawText)
        
        XCTAssertEqual(result.brand, "TAMEK", "Expected brand TAMEK but found \(result.brand ?? "nil")")
        XCTAssertEqual(result.price, 99.95, "Expected price 99.95 but found \(result.price)")
        XCTAssertTrue(result.productName.contains("HAŞLANMIS BARBUNYA"), "Expected product name to contain HAŞLANMIS BARBUNYA but was \(result.productName)")
    }
    
    /// Test case for Kekspir tag with barcode and price formatting (Case 3 from metin.txt).
    func testKekspirWithBarcodeAndPriceTypos() async throws {
        let rawText = "1721_2009150936 KEKSPIR KEK MEYVELİ 45 G 17002074-8699118066200-RE-7 8,50 FİYAT GEÇERLİLİK TARİHİ Urt. yerl: Türkiye 15 Nisan 2026 - YERLI 1 KG = 188,89 TL KDV Dahildir ÜRETIM"
        
        let result = sut.parse(ocrText: rawText)
        
        XCTAssertEqual(result.brand, "KEKSPİR", "Expected brand KEKSPİR but found \(result.brand ?? "nil")")
        XCTAssertEqual(result.price, 8.50, "Expected price 8.50 but found \(result.price)")
        XCTAssertTrue(result.productName.contains("KEK MEYVELİ"), "Expected product name to contain KEK MEYVELİ but was \(result.productName)")
    }
    
    /// Test case for Kızılay tag with unit price and Russian letter OCR typo in price (Case 10 from metin.txt).
    func testKizilayWithUnitFiyatAndRussians() async throws {
        let rawText = "KIZILAY MADEN SUYU K.DUT-FRENK UZUMU 6X200 ML 13000193-8692813005086-RE-7 82г FİYAT GEÇERLİLİK TARİHİ Ürt. yeri:Türkiy 13 Mayıs 2026 - YERLI 1 LT = 68,33 TL KDV Dahlidir ÜRETİM"
        
        let result = sut.parse(ocrText: rawText)
        
        XCTAssertEqual(result.brand, "KIZILAY", "Expected brand KIZILAY but found \(result.brand ?? "nil")")
        XCTAssertEqual(result.price, 82.00, "Expected price 82.00 but found \(result.price)")
    }
    
    /// Test case for Çerezya tag with accents, typos, and unit price values (Case from metin.txt).
    func testCerezyaWithAccentsAndUnitFiyat() async throws {
        let rawText = "ÇEREZYA ÇIG BADEM 150 G 109 FİYAT GEÇERLÍLİK TARİHİ- Urt. yerl:ABD 06 Mayis 2026 - 60 96 7 1 YS. - 126,67 TL KDV Darildir TL"
        
        let result = sut.parse(ocrText: rawText)
        
        XCTAssertEqual(result.brand, "ÇEREZYA", "Expected brand ÇEREZYA but found \(result.brand ?? "nil")")
        XCTAssertEqual(result.price, 109.00, "Expected price 109.00 but found \(result.price)")
        XCTAssertTrue(result.productName.contains("ÇIG BADEM"), "Expected product name to contain ÇIG BADEM but was \(result.productName)")
        XCTAssertFalse(result.productName.contains("GEÇERLÍLİK"), "Product name should not contain GEÇERLÍLİK")
        XCTAssertFalse(result.productName.contains("126,67"), "Product name should not contain unit price 126,67")
        XCTAssertFalse(result.productName.contains("Darildir"), "Product name should not contain KDV typo Darildir")
    }
}
