//
//  LocalOCRParserTests.swift
//  HybridVisionPipelineTests
//

import XCTest
@testable import HybridVisionPipeline

final class LocalOCRParserTests: XCTestCase {

    var parser: LocalOCRParserService!

    override func setUp() {
        super.setUp()
        parser = LocalOCRParserService()
    }

    func testSimpleProductAndPrice() {
        let ocrText = """
        SÜTAŞ
        SÜT 1 LİTRE
        45,50 TL
        """

        let result = parser.parse(ocrText: ocrText)

        XCTAssertEqual(result.brand, "SÜTAŞ")
        XCTAssertTrue(result.productName.contains("SÜT"))
        XCTAssertEqual(result.price, Decimal(string: "45.50"))
        XCTAssertGreaterThan(result.confidenceScore ?? 0.0, 0.6)
    }

    func testUnitAndSellingPriceSeparation() {
        // Tag with unit price: 100 TL/KG and actual item price: 25.00 TL (250g)
        let ocrText = """
        PINAR
        BEYAZ PEYNIR 250 G
        BIRIM FIYATI: 100,00 TL/KG
        25,00 TL
        """

        let result = parser.parse(ocrText: ocrText)

        XCTAssertEqual(result.brand, "PINAR")
        XCTAssertEqual(result.price, Decimal(string: "25.00"))
    }

    func testBrandTypoNormalization() {
        let ocrText = """
        M1LK
        TAM YAGLI SUT 1L
        29,90 TL
        """

        let result = parser.parse(ocrText: ocrText)

        XCTAssertEqual(result.brand, "MILK")
    }

    func testZeroPriceGeneratesZeroConfidence() {
        let ocrText = """
        RASTGELE METIN
        FIYAT BELIRTILMEMIS
        """

        let result = parser.parse(ocrText: ocrText)

        XCTAssertEqual(result.price, Decimal(0))
        XCTAssertEqual(result.confidenceScore, 0.0)
    }
}
