//
//  OCRNoiseCleanerTests.swift
//  CepSepetiAppTests
//
//  Created by Gemini CLI on 23.05.2026.
//

import XCTest
@testable import CepSepetiApp

final class OCRNoiseCleanerTests: XCTestCase {
    
    var sut: OCRNoiseCleaner!
    
    override func setUp() {
        super.setUp()
        sut = OCRNoiseCleaner()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testSystemNoiseIsIdentified() {
        XCTAssertTrue(sut.isNoise("FigXPCUtilities"))
        XCTAssertTrue(sut.isNoise("CGAffineTransformInvert: singular matrix"))
        XCTAssertTrue(sut.isNoise("Xcode Simulator Build succeeded"))
        XCTAssertTrue(sut.isNoise("Status Bar"))
        XCTAssertTrue(sut.isNoise("--- BAŞLANGIÇ: IMG_2089.JPG ---"))
        XCTAssertTrue(sut.isNoise("--- BİTİŞ ---"))
    }
    
    func testMarketMetadataNoiseIsIdentified() {
        // Substring matches
        XCTAssertTrue(sut.isNoise("FİYAT GEÇERLİLİK TARİHİ"))
        XCTAssertTrue(sut.isNoise("15 Nisan 2026 -"))
        XCTAssertTrue(sut.isNoise("1 KG = 433,33 TL KDV Dahildir"))
        XCTAssertTrue(sut.isNoise("Ürt. yeri: Türkiye"))
        XCTAssertTrue(sut.isNoise("KDV Dahil"))
        XCTAssertTrue(sut.isNoise("YERLİ ÜRETİM"))
        XCTAssertTrue(sut.isNoise("YERLİ ÜRETÍM"))
        XCTAssertTrue(sut.isNoise("KG Fiyatı"))
        XCTAssertTrue(sut.isNoise("Birim Fiyatı :180.00 TL/KG"))
        XCTAssertTrue(sut.isNoise("F.D.T.: 26.03.2026"))
        XCTAssertTrue(sut.isNoise("Birim F. Değ : 09-10-2025"))
        XCTAssertTrue(sut.isNoise("TL/KG"))
        XCTAssertTrue(sut.isNoise("TL/LT"))
    }
    
    func testExactMatchNoiseIsIdentified() {
        // Standalone noise words (exact matches)
        XCTAssertTrue(sut.isNoise("YERLİ"))
        XCTAssertTrue(sut.isNoise("yerli"))
        XCTAssertTrue(sut.isNoise("ÜRETİM"))
        XCTAssertTrue(sut.isNoise("KDV"))
        XCTAssertTrue(sut.isNoise("TL"))
        XCTAssertTrue(sut.isNoise("₺"))
        XCTAssertTrue(sut.isNoise("MENŞE"))
    }
    
    func testValidProductNamesAreNotNoise() {
        // These should NOT be identified as noise
        XCTAssertFalse(sut.isNoise("YERLİ MUZ"))
        XCTAssertFalse(sut.isNoise("YERLİ DOMATES"))
        XCTAssertFalse(sut.isNoise("İTHAL MUZ"))
        XCTAssertFalse(sut.isNoise("TÜRK KAHVESİ"))
        XCTAssertFalse(sut.isNoise("SÜTAŞ TAM YAĞLI SÜT 1L"))
        XCTAssertFalse(sut.isNoise("ULKER ALBENI 5LI PAKET"))
    }
}
