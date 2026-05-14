//
//  OCRLog.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 14.05.2026.
//

import Foundation
import SwiftData

/// A persistent data model for logging OCR results for debugging purposes.
/// Hata ayıklama amacıyla OCR sonuçlarını günlüğe kaydetmek için kalıcı bir veri modeli.
@Model
final class OCRLog {
    /// Unique identifier for the log entry.
    /// Günlük girişi için benzersiz tanımlayıcı.
    var id: UUID
    /// The timestamp when the OCR process occurred.
    /// OCR işleminin gerçekleştiği zaman damgası.
    var timestamp: Date
    /// The raw text extracted by the OCR engine.
    /// OCR motoru tarafından çıkarılan ham metin.
    var rawText: String
    /// Indicates whether the parsing was successful.
    /// Ayrıştırmanın başarılı olup olmadığını belirtir.
    var success: Bool
    
    /// Initializes a new OCRLog entry.
    /// Yeni bir OCRLog girişi başlatır.
    init(id: UUID = UUID(), timestamp: Date = Date(), rawText: String, success: Bool) {
        self.id = id
        self.timestamp = timestamp
        self.rawText = rawText
        self.success = success
    }
}

/*
 SUMMARY:
 OCRLog is a SwiftData model used to store raw OCR text and its parsing outcome.
 It helps developers analyze OCR failures in the field.
 
 ÖZET:
 OCRLog, ham OCR metnini ve ayrıştırma sonucunu saklamak için kullanılan bir SwiftData modelidir.
 Geliştiricilerin sahadaki OCR hatalarını analiz etmesine yardımcı olur.
 */
