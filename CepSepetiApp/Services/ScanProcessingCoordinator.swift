//
//  ScanProcessingCoordinator.swift
//  CepSepetiApp
//

import Foundation
import SwiftData
import UIKit

@MainActor
final class ScanProcessingCoordinator {
    private let queue = ScanProcessingQueue()
    private let imageStorageService = ImageStorageService()
    private let pipeline = ImageProcessingPipeline()
    private var context: ModelContext?
    private let maximumAutomaticRetries = 2
    private let retryBackoffsNanoseconds: [UInt64] = [
        1_500_000_000,
        4_000_000_000
    ]

    init() {
        Task {
            await queue.setHandler { [weak self] jobID in
                await self?.processItem(jobID)
            }
        }
    }

    func submitScan(image: UIImage, session: ShoppingSession, context: ModelContext) {
        self.context = context
        let jobID = UUID()

        do {
            let imagePath = try imageStorageService.saveScanImage(image, id: jobID)
            let item = ShoppingItem(
                productName: "Analiz ediliyor...",
                brand: nil,
                price: 0,
                quantity: 1,
                processingStatus: .queued,
                scanJobID: jobID,
                capturedImagePath: imagePath,
                session: session
            )

            if session.items == nil {
                session.items = [item]
            } else {
                session.items?.append(item)
            }
            context.insert(item)
            try context.save()

            Task {
                await queue.enqueue(itemID: jobID)
            }
        } catch {
            let item = ShoppingItem(
                productName: "Görsel kaydedilemedi",
                price: 0,
                quantity: 1,
                processingStatus: .failed,
                scanJobID: jobID,
                processingError: "Fotoğraf yerel olarak kaydedilemedi.",
                session: session
            )

            if session.items == nil {
                session.items = [item]
            } else {
                session.items?.append(item)
            }
            context.insert(item)
            try? context.save()
        }
    }

    func restorePendingItems(in session: ShoppingSession, context: ModelContext) {
        self.context = context
        guard let items = session.items else { return }

        let pendingJobIDs = items.compactMap { item -> UUID? in
            guard item.processingStatus == .queued || item.processingStatus == .processing else {
                return nil
            }

            item.processingStatus = .queued
            return item.scanJobID
        }

        try? context.save()

        Task {
            await queue.restorePendingJobs(pendingJobIDs)
        }
    }

    func retry(item: ShoppingItem, context: ModelContext) {
        self.context = context
        guard let jobID = item.scanJobID else { return }

        item.processingStatus = .queued
        item.processingError = nil
        item.retryCount += 1
        item.processingStartedAt = nil
        item.processingCompletedAt = nil
        try? context.save()

        Task {
            await queue.retry(itemID: jobID)
        }
    }

    private func processItem(_ jobID: UUID) async {
        guard let context, let item = findItem(jobID: jobID, context: context) else {
            return
        }

        guard let imagePath = item.capturedImagePath,
              let image = imageStorageService.loadImage(path: imagePath) else {
            item.processingStatus = .failed
            item.processingError = "Kaydedilen fotoğraf bulunamadı."
            item.processingCompletedAt = Date()
            try? context.save()
            return
        }

        item.processingStatus = .processing
        item.processingStartedAt = Date()
        item.processingError = nil
        try? context.save()

        do {
            let result = try await pipeline.processScan(image: image, context: context)
            guard let currentItem = findItem(jobID: jobID, context: context) else {
                return
            }

            currentItem.productName = result.productName
            currentItem.brand = result.brand
            currentItem.price = result.price
            currentItem.rawOCRText = result.rawOCRText
            currentItem.localProductName = result.localResult?.productName
            currentItem.localBrand = result.localResult?.brand
            currentItem.localPrice = result.localResult.map { NSDecimalNumber(decimal: $0.price).doubleValue }
            currentItem.aiConfidence = result.confidence
            currentItem.processingStatus = result.needsReview ? .needsReview : .completed
            currentItem.processingError = result.validationWarnings.isEmpty ? nil : result.validationWarnings.joined(separator: "\n")
            currentItem.processingCompletedAt = Date()
            try context.save()
        } catch {
            guard let currentItem = findItem(jobID: jobID, context: context) else {
                return
            }

            if shouldRetry(error: error, item: currentItem), let jobID = currentItem.scanJobID {
                let retryIndex = currentItem.retryCount
                currentItem.retryCount += 1
                currentItem.processingStatus = .queued
                currentItem.processingError = "Geçici hata nedeniyle yeniden denenecek: \(error.localizedDescription)"
                currentItem.processingStartedAt = nil
                currentItem.processingCompletedAt = nil
                try? context.save()

                let delay = retryBackoffsNanoseconds[min(retryIndex, retryBackoffsNanoseconds.count - 1)]
                Task {
                    try? await Task.sleep(nanoseconds: delay)
                    await queue.enqueue(itemID: jobID)
                }
            } else {
                currentItem.processingStatus = .failed
                currentItem.processingError = error.localizedDescription
                currentItem.processingCompletedAt = Date()
                try? context.save()
            }
        }
    }

    private func shouldRetry(error: Error, item: ShoppingItem) -> Bool {
        guard item.retryCount < maximumAutomaticRetries else {
            return false
        }

        if let processingError = error as? ScanProcessingError {
            return processingError.isRetryable
        }

        if let geminiError = error as? GeminiError {
            return geminiError.isRetryable
        }

        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain
    }

    private func findItem(jobID: UUID, context: ModelContext) -> ShoppingItem? {
        let descriptor = FetchDescriptor<ShoppingItem>()
        return (try? context.fetch(descriptor))?.first { $0.scanJobID == jobID }
    }
}
