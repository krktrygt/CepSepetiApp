//
//  ShoppingCartSummaryTests.swift
//  CepSepetiAppTests
//

import XCTest
@testable import CepSepetiApp

final class ShoppingCartSummaryTests: XCTestCase {
    func testCompletedItemsAreIncludedInConfirmedTotal() {
        let item = ShoppingItem(productName: "Süt", price: 20, quantity: 2)
        
        let summary = ShoppingCartSummary.make(items: [item])
        
        XCTAssertEqual(summary.confirmedTotal, 40)
        XCTAssertEqual(summary.estimatedTotal, 40)
        XCTAssertTrue(summary.canFinalize)
    }
    
    func testQueuedAndProcessingItemsAreExcludedFromConfirmedTotal() {
        let queued = ShoppingItem(productName: "Analiz", price: 0, quantity: 1, processingStatus: .queued, localPrice: 12)
        let processing = ShoppingItem(productName: "Analiz", price: 0, quantity: 1, processingStatus: .processing, localPrice: 8)
        
        let summary = ShoppingCartSummary.make(items: [queued, processing])
        
        XCTAssertEqual(summary.confirmedTotal, 0)
        XCTAssertEqual(summary.estimatedTotal, 20)
        XCTAssertEqual(summary.queuedCount, 1)
        XCTAssertEqual(summary.processingCount, 1)
        XCTAssertFalse(summary.canFinalize)
    }
    
    func testFailedItemsAreExcludedFromAllTotals() {
        let failed = ShoppingItem(productName: "Hata", price: 99, quantity: 1, processingStatus: .failed)
        
        let summary = ShoppingCartSummary.make(items: [failed])
        
        XCTAssertEqual(summary.confirmedTotal, 0)
        XCTAssertNil(summary.estimatedTotal)
        XCTAssertEqual(summary.failedCount, 1)
        XCTAssertFalse(summary.canFinalize)
    }
    
    func testNeedsReviewIsEstimatedButBlocksFinalize() {
        let completed = ShoppingItem(productName: "Süt", price: 20, quantity: 1)
        let review = ShoppingItem(productName: "Peynir", price: 30, quantity: 1, processingStatus: .needsReview)
        
        let summary = ShoppingCartSummary.make(items: [completed, review])
        
        XCTAssertEqual(summary.confirmedTotal, 20)
        XCTAssertEqual(summary.estimatedTotal, 50)
        XCTAssertEqual(summary.needsReviewCount, 1)
        XCTAssertFalse(summary.canFinalize)
    }
}
