//
//  ItemProcessingStatus.swift
//  CepSepetiApp
//

import Foundation

enum ItemProcessingStatus: String, Codable, CaseIterable {
    case queued
    case processing
    case completed
    case needsReview
    case failed
}
