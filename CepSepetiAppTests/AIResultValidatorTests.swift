//
//  AIResultValidatorTests.swift
//  CepSepetiAppTests
//

import XCTest
@testable import CepSepetiApp

final class AIResultValidatorTests: XCTestCase {
    private var validator: AIResultValidator!
    private var preflightValidator: OCRPreflightValidator!
    
    override func setUp() {
        super.setUp()
        validator = AIResultValidator()
        preflightValidator = OCRPreflightValidator()
    }
    
    override func tearDown() {
        validator = nil
        preflightValidator = nil
        super.tearDown()
    }
    
    func testValidProductNameBrandAndPriceIsAcceptable() {
        let data = PriceTagData(productName: "Sütaş Süt 1L", price: 34.50, brand: "Sütaş", rawOCRText: "SUTAS SUT 34,50 TL", confidenceScore: 1)
        
        let result = validator.validate(data)
        
        XCTAssertTrue(result.isAcceptable)
        XCTAssertFalse(result.needsReview)
    }
    
    func testEmptyProductNameNeedsReviewAndIsRejected() {
        let data = PriceTagData(productName: "   ", price: 34.50, brand: "Sütaş", rawOCRText: "34,50 TL", confidenceScore: 1)
        
        let result = validator.validate(data)
        
        XCTAssertFalse(result.isAcceptable)
        XCTAssertTrue(result.needsReview)
    }
    
    func testZeroAndNegativePricesAreRejected() {
        let zero = PriceTagData(productName: "Süt", price: 0, brand: nil, rawOCRText: "SUT", confidenceScore: 1)
        let negative = PriceTagData(productName: "Süt", price: -10, brand: nil, rawOCRText: "SUT", confidenceScore: 1)
        
        XCTAssertFalse(validator.validate(zero).isAcceptable)
        XCTAssertFalse(validator.validate(negative).isAcceptable)
    }
    
    func testMissingBrandDoesNotAutomaticallyFail() {
        let data = PriceTagData(productName: "Tam Yağlı Süt 1L", price: 34.50, brand: nil, rawOCRText: "TAM YAGLI SUT 34,50 TL", confidenceScore: 1)
        
        let result = validator.validate(data)
        
        XCTAssertTrue(result.isAcceptable)
        XCTAssertTrue(result.needsReview)
    }
    
    func testPreflightAllowsBrokenButMeaningfulOCR() {
        let result = preflightValidator.validate("SUT4S TAM Y4GLI SUT 34,50 TL")
        
        XCTAssertTrue(result.canUseOCR)
    }
    
    func testPreflightRejectsEmptyOCRAndTinyNoise() {
        XCTAssertFalse(preflightValidator.validate("").canUseOCR)
        XCTAssertFalse(preflightValidator.validate("::").canUseOCR)
    }
}
