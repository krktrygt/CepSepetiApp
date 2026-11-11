//
//  ScanJob.swift
//  HybridVisionPipeline
//

import Foundation
import UIKit

/// Status tracking for an asynchronous scan job.
public enum ScanJobStatus: Sendable, Equatable {
    case queued
    case processing
    case completed(PipelineResult)
    case failed(String)
}

/// A generic job model representing a queued image scan task.
public struct ScanJob: Identifiable, Sendable {
    public let id: UUID
    public let image: UIImage
    public var status: ScanJobStatus
    public var retryCount: Int
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        image: UIImage,
        status: ScanJobStatus = .queued,
        retryCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.image = image
        self.status = status
        self.retryCount = retryCount
        self.createdAt = createdAt
    }
}
