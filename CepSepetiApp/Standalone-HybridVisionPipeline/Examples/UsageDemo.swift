//
//  UsageDemo.swift
//  HybridVisionPipeline
//

import UIKit

/// An example showing how easily the pipeline and coordinator can be integrated.
@MainActor
func runDemo(sampleImage: UIImage) async {
    // 1. Configure the LLM provider (optional)
    let geminiLLM = GeminiLLMService {
        // Return your API key here (e.g. from Keychain or environment)
        return "YOUR_GEMINI_API_KEY"
    }

    // 2. Initialize the pipeline
    let pipeline = HybridImagePipeline(
        llmService: geminiLLM,
        localConfidenceThreshold: 0.75 // Only invoke LLM if local confidence is below 75%
    )

    // 3. Initialize the job coordinator (handles concurrency, retries, backgrounding)
    let coordinator = ScanJobCoordinator(
        pipeline: pipeline,
        maxConcurrentJobs: 2
    )

    // 4. Observe status updates
    coordinator.onJobStatusChanged = { job in
        switch job.status {
        case .queued:
            print("⏳ Job \(job.id) is queued.")
        case .processing:
            print("⚙️ Job \(job.id) is processing...")
        case .completed(let result):
            print("✅ Product: \(result.data.productName)")
            print("   Brand: \(result.data.brand ?? "None")")
            print("   Price: \(result.data.price)")
            print("   Source: \(result.source.rawValue)")
            print("   Needs Review: \(result.needsReview)")
        case .failed(let error):
            print("❌ Job \(job.id) failed: \(error)")
        }
    }

    // 5. Submit an image to scan
    let jobID = coordinator.submit(image: sampleImage)
    print("Submitted scan job: \(jobID)")
}
