//
//  ScanProcessingQueue.swift
//  CepSepetiApp
//

import Foundation

actor ScanProcessingQueue {
    private let maxConcurrentJobs: Int
    private var pendingJobIDs: [UUID] = []
    private var runningJobIDs: Set<UUID> = []
    private var handler: ((UUID) async -> Void)?
    
    init(maxConcurrentJobs: Int = 2) {
        self.maxConcurrentJobs = maxConcurrentJobs
    }
    
    func setHandler(_ handler: @escaping (UUID) async -> Void) {
        self.handler = handler
        startAvailableJobs()
    }
    
    func enqueue(itemID: UUID) {
        guard !runningJobIDs.contains(itemID), !pendingJobIDs.contains(itemID) else {
            return
        }
        
        pendingJobIDs.append(itemID)
        startAvailableJobs()
    }
    
    func restorePendingJobs(_ itemIDs: [UUID]) {
        for itemID in itemIDs {
            enqueue(itemID: itemID)
        }
    }
    
    func retry(itemID: UUID) {
        enqueue(itemID: itemID)
    }
    
    func cancel(itemID: UUID) {
        pendingJobIDs.removeAll { $0 == itemID }
        runningJobIDs.remove(itemID)
    }
    
    private func startAvailableJobs() {
        guard let handler else { return }
        
        while runningJobIDs.count < maxConcurrentJobs, !pendingJobIDs.isEmpty {
            let itemID = pendingJobIDs.removeFirst()
            runningJobIDs.insert(itemID)
            
            Task {
                await handler(itemID)
                await self.finish(itemID: itemID)
            }
        }
    }
    
    private func finish(itemID: UUID) {
        runningJobIDs.remove(itemID)
        startAvailableJobs()
    }
}
