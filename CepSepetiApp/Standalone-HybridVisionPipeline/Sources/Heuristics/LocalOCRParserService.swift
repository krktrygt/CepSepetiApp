//
//  LocalOCRParserService.swift
//  HybridVisionPipeline
//

import Foundation

/// A fast on-device rule-based parsing engine designed to extract product name, brand, and prices from raw OCR text.
public final class LocalOCRParserService: Sendable {

    private let priceRegex = try! NSRegularExpression(pattern: #"(\d+[,.]\d{1,2})\s*(?:TL|₺)?|(\d+)\s*(?:TL|₺)"#, options: .caseInsensitive)
    private let integerBeforeFiyatRegex = try! NSRegularExpression(pattern: #"(?<!\d)(\d{1,4})(?:[A-Za-zА-Яа-яĞÜŞİÖÇğüşiöç])?\s+F[İI]YAT"#, options: .caseInsensitive)
    private let splitPriceRegex = try! NSRegularExpression(pattern: #"(?<![\d,.])(\d{1,4})\s+(\d{2})(?![\d,.])"#, options: [])
    private let dateRegex = try! NSRegularExpression(pattern: #"\d{2}[./-]\d{2}[./-]\d{2,4}"#, options: [])
    private let timeRegex = try! NSRegularExpression(pattern: #"\d{2}:\d{2}(:\d{2})?"#, options: [])

    // Known unit keywords to classify sizes
    private let validUnits = ["G", "GR", "KG", "L", "LT", "LITRE", "LİTRE", "ML", "CC", "ADET", "PAKET"]

    // Known brands and common OCR typo mappings
    private let brandNormalizations: [String: String] = [
        "M1LK": "MILK", "ULKER": "ÜLKER", "SUTAS": "SÜTAŞ", "PINAR": "PINAR",
        "ETI": "ETİ", "ETI.": "ETİ", "AYTAÇ": "AYTAÇ", "AYTAC": "AYTAÇ", "TORKU": "TORKU",
        "NESTLE": "NESTLÉ", "MİLKA": "MILKA", "MILKA": "MILKA",
        "COCA-COLA": "COCA-COLA", "COCA COLA": "COCA-COLA", "COCA": "COCA-COLA", "PEPSI": "PEPSI", "PEPSİ": "PEPSI", "LIPTON": "LIPTON", "LİPTON": "LIPTON",
        "DANONE": "DANONE", "ALGİDA": "ALGIDA", "ALGIDA": "ALGIDA", "UNO": "UNO", "ŞÖLEN": "ŞÖLEN", "SOLEN": "ŞÖLEN",
        "BEYPAZARI": "BEYPAZARI", "BEYPAZAR": "BEYPAZARI", "KIZILAY": "KIZILAY", "SARIKIZ": "SARIKIZ",
        "ÇAYKUR": "ÇAYKUR", "CAYKUR": "ÇAYKUR", "DOĞUŞ": "DOĞUŞ", "DOGUS": "DOĞUŞ",
        "SIRMA": "SIRMA", "HAYAT": "HAYAT", "ERİKLİ": "ERİKLİ", "ERIKLI": "ERİKLİ",
        "FUSETEA": "FUSE TEA", "FUSE TEA": "FUSE TEA", "DİDİ": "DİDİ", "DIDI": "DİDİ",
        "TAMEK": "TAMEK", "CAPPY": "CAPPY", "DIMES": "DİMES", "DİMES": "DİMES",
        "FRUKO": "FRUKO", "YEDİGÜN": "YEDİGÜN", "YEDIGUN": "YEDİGÜN", "ULUDAG": "ULUDAĞ", "ULUDAĞ": "ULUDAĞ",
        "FANTA": "FANTA", "SPRITE": "SPRITE", "SCHWEPPES": "SCHWEPPES",
        "BINGO": "BİNGO", "BİNGO": "BİNGO", "ARIEL": "ARİEL", "ARİEL": "ARİEL", "OMO": "OMO", "ALO": "ALO", "RINSO": "RİNSO", "RİNSO": "RİNSO",
        "FAIRY": "FAIRY", "PRIL": "PRİL", "PRİL": "PRİL", "FINISH": "FINISH", "FİNİSH": "FINISH",
        "DOMESTOS": "DOMESTOS", "MARMARABİRLİK": "MARMARABİRLİK", "MARMARABIRLIK": "MARMARABİRLİK",
        "BALKÜPÜ": "BALKÜPÜ", "BALKUPU": "BALKÜPÜ", "IRMAK": "IRMAK", "SÖKE": "SÖKE", "SOKE": "SÖKE",
        "OFÇAY": "OFÇAY", "OFCAY": "OFÇAY", "KARALİ": "KARALİ", "KARALI": "KARALİ",
        "KOMİLİ": "KOMİLİ", "KOMILI": "KOMİLİ", "YUDUM": "YUDUM", "ZEYTİNYAĞI": "ZEYTİNYAĞI",
        "İÇİM": "İÇİM", "ICIM": "İÇİM", "SEK": "SEK", "YÖRSAN": "YÖRSAN", "YORSAN": "YÖRSAN",
        "KINDER": "KINDER", "KİNDER": "KINDER", "NUTELLA": "NUTELLA", "TADELLE": "TADELLE",
        "HALLEY": "HALLEY", "BİSKREM": "BİSKREM", "BISKREM": "BİSKREM", "ÇOKOKREM": "ÇOKOKREM", "COKOKREM": "ÇOKOKREM",
        "LAYS": "LAY'S", "LAY'S": "LAY'S", "RUFFLES": "RUFFLES", "DORITOS": "DORITOS", "DORİTOS": "DORITOS",
        "ÇEREZZA": "ÇEREZZA", "CEREZZA": "ÇEREZZA", "ÇEREZYA": "ÇEREZYA", "CEREZYA": "ÇEREZYA",
        "KEKSPIR": "KEKSPİR", "KEKSPİR": "KEKSPİR", "PATİTO": "PATİTO", "PATITO": "PATİTO"
    ]

    // Invalid brand candidates
    private let invalidBrands: Set<String> = [
        "YERLİ", "YERLI", "ÜRETİM", "URETIM", "KDV", "İNDİRİM", "INDIRIM",
        "MIGROS", "MİGROS", "BIM", "BİM", "A101", "SOK", "ŞOK", "CARREFOUR", "FİŞ", "FIS"
    ]

    public init() {}

    /// Parses raw OCR text to extract product details and calculate a confidence score (0.0 - 1.0).
    public func parse(ocrText: String) -> ExtractedProductData {
        let lines = ocrText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let brand = extractBrand(from: lines)
        let (nameTokens, sizeInKg) = extractNameAndSize(from: lines, brand: brand)
        let name = nameTokens.joined(separator: " ")

        let (priceDecimal, conflictingPrices) = extractPrice(from: lines, sizeInKg: sizeInKg)

        var confidenceScore = 1.0

        if priceDecimal == 0 {
            confidenceScore = 0.0
        } else if conflictingPrices {
            confidenceScore -= 0.4
        }

        if nameTokens.count < 2 {
            confidenceScore -= 0.2
        }

        if name.count < 4 {
            confidenceScore -= 0.2
        }

        if brand == nil {
            confidenceScore -= 0.1
        }

        let symbolCount = name.filter { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }.count
        if name.count > 0 && Double(symbolCount) / Double(name.count) > 0.2 {
            confidenceScore -= 0.3
        }

        confidenceScore = max(0.0, min(1.0, confidenceScore))

        return ExtractedProductData(
            productName: name.isEmpty ? "Unknown Product" : name,
            price: priceDecimal,
            brand: brand,
            rawOCRText: ocrText,
            confidenceScore: confidenceScore
        )
    }

    // MARK: - Parsing Helpers

    private func extractBrand(from lines: [String]) -> String? {
        let trLocale = Locale(identifier: "tr-TR")

        for line in lines {
            let words = line.components(separatedBy: .whitespaces)
            for word in words {
                let upperWord = word.uppercased(with: trLocale).trimmingCharacters(in: .punctuationCharacters)
                if let normalized = brandNormalizations[upperWord] {
                    return normalized
                }
            }
        }

        for line in lines {
            let words = line.components(separatedBy: .whitespaces)
            guard let firstWord = words.first else { continue }

            let upperFirstWord = firstWord.uppercased(with: trLocale).trimmingCharacters(in: .punctuationCharacters)

            if validUnits.contains(upperFirstWord) || invalidBrands.contains(upperFirstWord) { continue }

            if firstWord == upperFirstWord && firstWord.count > 2 && firstWord.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil {
                return firstWord
            }
        }
        return nil
    }

    private func extractNameAndSize(from lines: [String], brand: String?) -> ([String], Double?) {
        var nameTokens = [String]()
        var sizeInKg: Double? = nil

        let trLocale = Locale(identifier: "tr-TR")

        let trashWords = [
            "DAHIL", "DAHİL", "DAHILDIR", "DAHİLDİR", "DAHLIDIR", "DARILDIR", "PAYLAS", "PAYLAŞ",
            "ZIYARET", "ŞIKAYETVAR", "ŞİKAYETVAR", "TIKTOK", "ARAMAK", "ARA", "GOOGLE",
            "TARINI", "TARIHI", "TARİHİ", "GEÇERLİLİK", "GEÇERLÍLİK", "GECERLILIK", "FİYAT", "FIYAT",
            "BIRIM", "BİRİM", "DEĞ", "DEG", "KDY", "KDV", "B", "YS", "X", "YERLİ", "YERLI",
            "ÜRETİM", "URETIM", "URETİM", "ÜRETIM", "ADET", "YURTBAŞI", "ELAZIG", "ELAZIĞ",
            "TOPLAM", "FIS", "FİŞ", "TARIH", "TARİH", "TURKIYE", "TÜRKİYE", "TÜRKIY", "TURKIY", "ABD"
        ]

        var skipNextLine = false

        for line in lines {
            if skipNextLine {
                skipNextLine = false
                continue
            }

            let upperLine = line.uppercased(with: trLocale)

            if lines.count > 1, upperLine.contains("%") {
                continue
            }

            if lines.count > 1, upperLine.contains("Ü.YER") || upperLine.contains("MENŞE") || upperLine.contains("TARİH") || upperLine.contains("TETT") || upperLine.contains("SKT") || upperLine.contains("PNT") {
                skipNextLine = true
                continue
            }

            var cleanLine = line
            cleanLine = dateRegex.stringByReplacingMatches(in: cleanLine, options: [], range: NSRange(location: 0, length: cleanLine.utf16.count), withTemplate: " ")
            cleanLine = timeRegex.stringByReplacingMatches(in: cleanLine, options: [], range: NSRange(location: 0, length: cleanLine.utf16.count), withTemplate: " ")
            cleanLine = priceRegex.stringByReplacingMatches(in: cleanLine, options: [], range: NSRange(location: 0, length: cleanLine.utf16.count), withTemplate: " ")

            let tokens = cleanLine.components(separatedBy: .whitespaces)

            for (index, rawToken) in tokens.enumerated() {
                let token = rawToken.trimmingCharacters(in: .punctuationCharacters)
                if token.isEmpty { continue }

                let upperToken = token.uppercased(with: trLocale)
                if upperToken == brand?.uppercased(with: trLocale) { continue }

                let hasLetters = token.rangeOfCharacter(from: CharacterSet.letters) != nil
                let hasDigits = token.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil

                if hasLetters && !hasDigits {
                    if token.count == 1 && !validUnits.contains(upperToken) { continue }
                    if trashWords.contains(upperToken) { continue }
                    if validUnits.contains(upperToken) {
                        if index > 0, tokens[index-1].rangeOfCharacter(from: CharacterSet.decimalDigits) != nil {
                            if !nameTokens.contains(upperToken) { nameTokens.append(upperToken) }
                        }
                        continue
                    }

                    if !nameTokens.contains(upperToken) {
                        nameTokens.append(upperToken)
                    }

                } else if hasDigits && !hasLetters {
                    if index + 1 < tokens.count {
                        let nextToken = tokens[index + 1].trimmingCharacters(in: .punctuationCharacters).uppercased(with: trLocale)
                        if validUnits.contains(nextToken) {
                            nameTokens.append(token)
                            if let val = Double(token.replacingOccurrences(of: ",", with: ".")) {
                                sizeInKg = (nextToken == "G" || nextToken == "GR" || nextToken == "ML" || nextToken == "CC") ? (val / 1000.0) : val
                            }
                        }
                    }
                } else if hasLetters && hasDigits {
                    let multiplierRegex = try? NSRegularExpression(pattern: #"^\d+[X*x]\d+([A-Z]*)$"#, options: .caseInsensitive)
                    if let mRegex = multiplierRegex, mRegex.firstMatch(in: upperToken, options: [], range: NSRange(location: 0, length: upperToken.utf16.count)) != nil {
                        nameTokens.append(upperToken)
                        continue
                    }

                    let packageCountRegex = try? NSRegularExpression(pattern: #"^\d+(LI|Lİ|LU|LÜ)$"#, options: .caseInsensitive)
                    if let pRegex = packageCountRegex, pRegex.firstMatch(in: upperToken, options: [], range: NSRange(location: 0, length: upperToken.utf16.count)) != nil {
                        nameTokens.append(upperToken)
                        continue
                    }

                    let letters = token.components(separatedBy: CharacterSet.letters.inverted).joined().uppercased(with: trLocale)
                    let digits = token.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

                    if !letters.isEmpty && !digits.isEmpty && token.hasPrefix(digits) && token.hasSuffix(letters) && validUnits.contains(letters) {
                        nameTokens.append(upperToken)
                        if let val = Double(digits) {
                            sizeInKg = (letters == "G" || letters == "GR" || letters == "ML" || letters == "CC") ? (val / 1000.0) : val
                        }
                    } else if !trashWords.contains(upperToken), upperToken.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil {
                        nameTokens.append(upperToken)
                    }
                }
            }
        }

        return (nameTokens, sizeInKg)
    }

    private func extractPrice(from lines: [String], sizeInKg: Double?) -> (Decimal, Bool) {
        var foundPrices = [Decimal]()

        for line in lines {
            var cleanLine = line
            cleanLine = dateRegex.stringByReplacingMatches(in: cleanLine, options: [], range: NSRange(location: 0, length: cleanLine.utf16.count), withTemplate: " ")
            cleanLine = timeRegex.stringByReplacingMatches(in: cleanLine, options: [], range: NSRange(location: 0, length: cleanLine.utf16.count), withTemplate: " ")

            let matches = priceRegex.matches(in: cleanLine, options: [], range: NSRange(location: 0, length: cleanLine.utf16.count))
            for match in matches {
                if shouldSkipPriceMatch(in: cleanLine, matchRange: match.range) {
                    continue
                }

                var matchRange = match.range(at: 1)
                if matchRange.location == NSNotFound {
                    matchRange = match.range(at: 2)
                }

                if matchRange.location != NSNotFound, let r = Range(matchRange, in: cleanLine) {
                    let priceStr = String(cleanLine[r]).replacingOccurrences(of: ",", with: ".")

                    let afterRange = NSRange(location: match.range.upperBound, length: cleanLine.utf16.count - match.range.upperBound)
                    let textAfter = (cleanLine as NSString).substring(with: afterRange).trimmingCharacters(in: .whitespaces)
                    let firstWordAfter = textAfter.components(separatedBy: .whitespaces).first?.uppercased(with: Locale(identifier: "tr-TR")).trimmingCharacters(in: .punctuationCharacters) ?? ""

                    if validUnits.contains(firstWordAfter) {
                        continue
                    }

                    if let decimal = Decimal(string: priceStr) {
                        if decimal > Decimal(0.0) && decimal < Decimal(100000) {
                            foundPrices.append(decimal)
                        }
                    }
                }
            }

            let fiyatMatches = integerBeforeFiyatRegex.matches(in: cleanLine, options: [], range: NSRange(location: 0, length: cleanLine.utf16.count))
            for match in fiyatMatches {
                let matchRange = match.range(at: 1)
                if matchRange.location != NSNotFound, let r = Range(matchRange, in: cleanLine) {
                    let priceStr = String(cleanLine[r])
                    if let decimal = Decimal(string: priceStr), decimal > Decimal(0.0), decimal < Decimal(100000) {
                        foundPrices.append(decimal)
                    }
                }
            }

            let splitMatches = splitPriceRegex.matches(in: cleanLine, options: [], range: NSRange(location: 0, length: cleanLine.utf16.count))
            for match in splitMatches {
                let afterRange = NSRange(location: match.range.upperBound, length: min(24, cleanLine.utf16.count - match.range.upperBound))
                let textAfter = (cleanLine as NSString).substring(with: afterRange).uppercased(with: Locale(identifier: "tr-TR"))
                let trimmedAfter = textAfter.trimmingCharacters(in: .whitespacesAndNewlines)
                guard textAfter.contains("B. FIYAT") || textAfter.contains("B. FİYAT") || trimmedAfter.hasPrefix("TL") else {
                    continue
                }

                let wholeRange = match.range(at: 1)
                let fractionRange = match.range(at: 2)
                guard let whole = Range(wholeRange, in: cleanLine),
                      let fraction = Range(fractionRange, in: cleanLine) else {
                    continue
                }

                let priceStr = "\(cleanLine[whole]).\(cleanLine[fraction])"
                if let decimal = Decimal(string: priceStr), decimal > Decimal(0.0), decimal < Decimal(100000) {
                    foundPrices.append(decimal)
                }
            }
        }

        if foundPrices.isEmpty { return (0, false) }

        let uniquePrices = Array(Set(foundPrices)).sorted()
        if uniquePrices.count == 1 { return (uniquePrices[0], false) }

        // Mathematical Verification: Unit Price * Size = Selling Price
        if let size = sizeInKg, size > 0 {
            let sizeDec = Decimal(size)
            for p1 in uniquePrices {
                for p2 in uniquePrices {
                    if p1 == p2 { continue }

                    let calculatedP2 = p1 * sizeDec
                    let diff = abs(calculatedP2 - p2)

                    if diff <= Decimal(0.1) {
                        return (p2, false)
                    }
                }
            }
        }

        let minPrice = uniquePrices.min() ?? 0
        return (minPrice, true)
    }

    private func shouldSkipPriceMatch(in line: String, matchRange: NSRange) -> Bool {
        let nsLine = line as NSString
        let beforeStart = max(0, matchRange.location - 24)
        let beforeLength = matchRange.location - beforeStart
        let before = nsLine.substring(with: NSRange(location: beforeStart, length: beforeLength))

        let afterStart = matchRange.upperBound
        let afterLength = min(16, line.utf16.count - afterStart)
        let after = nsLine.substring(with: NSRange(location: afterStart, length: max(0, afterLength)))

        let context = "\(before) \(after)"
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr-TR"))
            .uppercased(with: Locale(identifier: "en-US"))

        return context.contains("BIRIM")
            || context.contains("KG=")
            || context.contains("KG =")
            || context.contains("LT=")
            || context.contains("LT =")
            || context.contains("TL/KG")
            || context.contains("TL/LT")
    }
}
