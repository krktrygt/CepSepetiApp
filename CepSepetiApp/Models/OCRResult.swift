//
//  OCRResult.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 19.04.2026.
//

import Foundation

enum OCRResult{
    case success(PriceTagData)
    case failure(OCRError)
}

enum OCRError: Error, LocalizedError{
    case noTextFound
    case networkUnavailable
    case geminiError(String)
    case parsingFailed
    
    var errorDescription: String?{
        switch self {
        case .noTextFound:
            return "Etiket üzerinde okunabilir bir metin bulunamadı. Lütfen daha yakından deneyin."
        case .networkUnavailable:
            return "İnternet bağlantısı kurulamadı. Fiyat analizi için bağlantı gerekiyor."
        case .geminiError(let message):
            return "Yapay zeka analizi sırasında bir hata oluştu: \(message)"
        case .parsingFailed:
            return "Okunan veri anlamlı bir fiyat bilgisine dönüştürülemedi."
        }
    }
}
