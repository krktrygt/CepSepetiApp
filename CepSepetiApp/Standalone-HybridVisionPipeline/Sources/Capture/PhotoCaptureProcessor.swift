//
//  PhotoCaptureProcessor.swift
//  HybridVisionPipeline
//

import Foundation
import AVFoundation
import UIKit

/// Handles AVCapturePhotoCaptureDelegate callbacks and safely resumes CheckedContinuation.
public final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private var continuation: CheckedContinuation<UIImage, Error>?
    public var onComplete: (@Sendable () -> Void)?
    
    public init(continuation: CheckedContinuation<UIImage, Error>) {
        self.continuation = continuation
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { onComplete?() }
        
        guard let continuation = self.continuation else { return }
        self.continuation = nil
        
        if let error = error {
            continuation.resume(throwing: error)
            return
        }
        
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            continuation.resume(throwing: PipelineError.imageCorrupted)
            return
        }
        
        continuation.resume(returning: image)
    }
}
