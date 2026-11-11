//
//  OCRService.swift
//  HybridVisionPipeline
//

import Foundation
import Vision
import UIKit

/// A service that uses Apple's Vision framework to perform Optical Character Recognition (OCR) on-device.
public final class OCRService: Sendable {
    
    private let shouldCropToCenter: Bool
    
    public init(shouldCropToCenter: Bool = false) {
        self.shouldCropToCenter = shouldCropToCenter
    }
    
    /// Recognizes text from a given image using Apple's Vision framework.
    /// - Parameter image: The source UIImage.
    /// - Returns: A single string containing all recognized text separated by newlines.
    public func recognizeText(from image: UIImage) async throws -> String {
        let targetImage: UIImage
        if shouldCropToCenter {
            guard let cropped = cropToCenter(image: image) else {
                throw PipelineError.imageCorrupted
            }
            targetImage = cropped
        } else {
            targetImage = image
        }
        
        guard let cgImage = targetImage.cgImage else {
            throw PipelineError.imageCorrupted
        }
        
        let orientation = cgImageOrientation(from: targetImage.imageOrientation)
        
        return try await Task.detached(priority: .userInitiated) {
            return try await withCheckedThrowingContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    if error != nil {
                        continuation.resume(throwing: PipelineError.ocrRecognitionFailed)
                        return
                    }
                    
                    guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                        continuation.resume(throwing: PipelineError.noTextFound)
                        return
                    }
                    
                    let recognizedStrings = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }
                    
                    let fullText = recognizedStrings.joined(separator: "\n")
                    
                    if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        continuation.resume(throwing: PipelineError.noTextFound)
                    } else {
                        continuation.resume(returning: fullText)
                    }
                }
                
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["tr-TR", "en-US"]
                request.customWords = ["TL", "₺", "KDV", "Fiyatı", "Adet", "İndirim", "kg", "lt", "ml"]
                
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
                
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: PipelineError.ocrRecognitionFailed)
                }
            }
        }.value
    }
    
    // MARK: - Helpers
    
    private func cropToCenter(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let cropSize = min(width, height) * 0.7
        
        let x = (width - cropSize) / 2.0
        let y = (height - cropSize) / 2.0
        let cropRect = CGRect(x: x, y: y, width: cropSize, height: cropSize)
        
        if let croppedCgImage = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedCgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        return nil
    }
    
    private func cgImageOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
