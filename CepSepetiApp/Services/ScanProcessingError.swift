//
//  ScanProcessingError.swift
//  CepSepetiApp
//

import Foundation

enum ScanProcessingError: LocalizedError {
    case preflightFailed(String)
    case retryable(String)
    case validationFailed(String)
    case permanent(String)
    
    var errorDescription: String? {
        switch self {
        case .preflightFailed(let message),
             .retryable(let message),
             .validationFailed(let message),
             .permanent(let message):
            return message
        }
    }
    
    var isRetryable: Bool {
        if case .retryable = self {
            return true
        }
        return false
    }
}
