//
//  ImageStorageService.swift
//  CepSepetiApp
//

import Foundation
import UIKit

enum ImageStorageError: Error {
    case documentsDirectoryUnavailable
    case jpegConversionFailed
    case writeFailed
}

final class ImageStorageService {
    func saveScanImage(_ image: UIImage, id: UUID) throws -> String {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ImageStorageError.documentsDirectoryUnavailable
        }
        
        let scansDirectory = documentsURL.appendingPathComponent("ScanImages", isDirectory: true)
        try FileManager.default.createDirectory(at: scansDirectory, withIntermediateDirectories: true)
        
        let fileURL = scansDirectory.appendingPathComponent("\(id.uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: 0.82) else {
            throw ImageStorageError.jpegConversionFailed
        }
        
        do {
            try data.write(to: fileURL, options: [.atomic])
            return fileURL.path
        } catch {
            throw ImageStorageError.writeFailed
        }
    }
    
    func loadImage(path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }
}
