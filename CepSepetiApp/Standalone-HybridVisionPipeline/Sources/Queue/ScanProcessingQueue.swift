//
//  ScanProcessingQueue.swift
//  HybridVisionPipeline
//

import Foundation

/// An Actor-isolated FIFO background queue that limits concurrent image extraction jobs.
public actor ScanProcessingQueue {
    private let maxConcurrentJobs: Int
    private var pendingJobIDs: [UUID] = []
    private var runningJobIDs: Set<UUID> = []
    private var handler: (@Sendable (UUID) async -> Void)?
    
    public init(maxConcurrentJobs: Int = 2) {
        self.maxConcurrentJobs = maxConcurrentJobs
    }
    
    public func setHandler(_ handler: @escaping @Sendable (UUID) async -> Void) {
        self.handler = handler
        startAvailableJobs()
    }
    
    public func enqueue(jobID: UUID) {
        guard !runningJobIDs.contains(jobID), !pendingJobIDs.contains(jobID) else {
            return
        }
        
        pendingJobIDs.append(jobID)
        startAvailableJobs()
    }
    
    public func restorePendingJobs(_ jobIDs: [UUID]) {
        for jobID in jobIDs {
            enqueue(jobID: jobID)
        }
    }
    
    public func retry(jobID: UUID) {
        enqueue(jobID: jobID)
    }
    
    public func cancel(jobID: UUID) {
        pendingJobIDs.removeAll { $0 == jobID }
        runningJobIDs.remove(jobID)
    }
    
    public var activeJobsCount: Int {
        runningJobIDs.count
    }
    
    public var pendingJobsCount: Int {
        pendingJobIDs.count
    }
    
    private func startAvailableJobs() {
        guard let handler else { return }
        
        while runningJobIDs.count < maxConcurrentJobs, !pendingJobIDs.isEmpty {
            let jobID = pendingJobIDs.removeFirst()
            runningJobIDs.insert(jobID)
            
            Task {
                await handler(jobID)
                self.finish(jobID: jobID)
            }
        }
    }
    
    private func finish(jobID: UUID) {
        runningJobIDs.remove(jobID)
        startAvailableJobs()
    }
}
