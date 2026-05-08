//
//  OCRResult.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 19.04.2026.
//

import Foundation

/// Represents the result of an Optical Character Recognition (OCR) operation.
/// Optik Karakter Tanıma (OCR) işleminin sonucunu temsil eder.
/// It can either be a success containing parsed price tag data or a failure with a specific error.
/// Ayrıştırılmış fiyat etiketi verilerini içeren bir başarı veya belirli bir hata içeren bir başarısızlık olabilir.
enum OCRResult {
    /// Indicates a successful OCR process with the extracted data.
    /// Çıkarılan verilerle başarılı bir OCR sürecini belirtir.
    case success(PriceTagData)
    /// Indicates a failed OCR process with an associated error.
    /// İlişkili bir hata ile başarısız bir OCR sürecini belirtir.
    case failure(OCRError)
}

/// Defines the specific errors that can occur during the OCR and analysis process.
/// OCR ve analiz süreci sırasında oluşabilecek belirli hataları tanımlar.
enum OCRError: Error, LocalizedError {
    /// No readable text was found on the image.
    /// Görüntü üzerinde okunabilir bir metin bulunamadı.
    case noTextFound
    /// Network connection is unavailable for cloud-based analysis.
    /// Bulut tabanlı analiz için ağ bağlantısı mevcut değil.
    case networkUnavailable
    /// An error returned from the Gemini AI service.
    /// Gemini AI servisinden dönen bir hata.
    case geminiError(String)
    /// The extracted text could not be parsed into a meaningful price tag structure.
    /// Çıkarılan metin anlamlı bir fiyat etiketi yapısına ayrıştırılamadı.
    case parsingFailed
    
    /// Provides a user-friendly description for the error.
    /// Hata için kullanıcı dostu bir açıklama sağlar.
    var errorDescription: String? {
        switch self {
        case .noTextFound:
            return "No readable text found on the label. Please try from a closer distance."
        case .networkUnavailable:
            return "Internet connection could not be established. Connection is required for price analysis."
        case .geminiError(let message):
            return "An error occurred during AI analysis: \(message)"
        case .parsingFailed:
            return "The read data could not be converted into meaningful price information."
        }
    }
}

/*
 SUMMARY:
 This file defines the result types and error handling for the OCR service. 
 It acts as a bridge between the raw image processing and the structured data used by the UI.
 It interacts closely with OCRService and PriceTagData.
 
 ÖZET:
 Bu dosya, OCR servisi için sonuç türlerini ve hata yönetimini tanımlar.
 Ham görüntü işleme ile UI tarafından kullanılan yapılandırılmış veriler arasında bir köprü görevi görür.
 OCRService ve PriceTagData ile yakından etkileşim halindedir.
 */
