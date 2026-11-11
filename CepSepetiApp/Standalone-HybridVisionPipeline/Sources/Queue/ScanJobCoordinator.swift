//
//  ScanJobCoordinator.swift
//  HybridVisionPipeline
//

import Foundation
import UIKit

/// High-level coordinator managing concurrent image submission, retry backoffs, and pipeline execution.
@MainActor
public final class ScanJobCoordinator {
    private let queue: ScanProcessingQueue
    private let pipeline: HybridImagePipeline
    private let maximumAutomaticRetries: Int
    private let retryBackoffsNanoseconds: [UInt64]
    
    // Internal job state registry
    private var jobs: [UUID: ScanJob] = [:]
    
    /// Delegate or callback to receive status updates.
    public var onJobStatusChanged: (@MainActor (ScanJob) -> Void)?

    public init(
        pipeline: HybridImagePipeline,
        maxConcurrentJobs: Int = 2,
        maximumAutomaticRetries: Int = 2,
        retryBackoffsNanoseconds: [UInt64] = [1_500_000_000, 4_000_000_000]
    ) {
        self.pipeline = pipeline
        self.queue = ScanProcessingQueue(maxConcurrentJobs: maxConcurrentJobs)
        self.maximumAutomaticRetries = maximumAutomaticRetries
        self.retryBackoffsNanoseconds = retryBackoffsNanoseconds
        
        Task {
            await self.queue.setHandler { [weak self] jobID in
                await self?.processJob(jobID)
            }
        }
    }

    /// Submits a new image to the processing queue.
    /// - Parameter image: The captured or loaded UIImage.
    /// - Returns: The assigned UUID of the job.
    @discardableResult
    public func submit(image: UIImage) -> UUID {
        let job = ScanJob(image: image)
        jobs[job.id] = job
        onJobStatusChanged?(job)
        
        Task {
            await queue.enqueue(jobID: job.id)
        }
        return job.id
    }

    /// Manually retries a failed job.
    public func retry(jobID: UUID) {
        guard var job = jobs[jobID] else { return }
        job.status = .queued
        job.retryCount += 1
        jobs[jobID] = job
        onJobStatusChanged?(job)

        Task {
            await queue.retry(jobID: jobID)
        }
    }

    /// Cancels a job if it's pending.
    public func cancel(jobID: UUID) {
        jobs.removeValue(forKey: jobID)
        Task {
            await queue.cancel(jobID: jobID)
        }
    }

    public func getJob(id: UUID) -> ScanJob? {
        jobs[id]
    }

    // MARK: - Private Execution

    private func processJob(_ jobID: UUID) async {
        guard var job = jobs[jobID] else { return }
        
        job.status = .processing
        jobs[jobID] = job
        onJobStatusChanged?(job)

        do {
            let result = try await pipeline.process(image: job.image)
            job.status = .completed(result)
            jobs[jobID] = job
            onJobStatusChanged?(job)
        } catch {
            if job.retryCount < maximumAutomaticRetries {
                let retryIndex = job.retryCount
                job.retryCount += 1
                job.status = .queued
                jobs[jobID] = job
                onJobStatusChanged?(job)

                let delay = retryBackoffsNanoseconds[min(retryIndex, retryBackoffsNanoseconds.count - 1)]
                Task {
                    try? await Task.sleep(nanoseconds: delay)
                    await queue.enqueue(jobID: jobID)
                }
            } else {
                job.status = .failed(error.localizedDescription)
                jobs[jobID] = job
                onJobStatusChanged?(job)
            }
        }
    }
}
