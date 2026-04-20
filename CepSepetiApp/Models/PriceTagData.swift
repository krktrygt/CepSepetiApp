//
//  PriceTagData.swift
//  CepSepetiApp
//
//  Created by Korkut Eryiğit on 19.04.2026.
//

import Foundation

struct PriceTagData: Codable{
    let productName: String
    let price: Decimal
    let brand: String?
    let rawOCRText: String // Debug süreci için ham metni tutma
}
