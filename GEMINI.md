# CepSepetiApp - AI Handbook

Welcome to the **CepSepetiApp** technical documentation. This guide is designed to provide a comprehensive overview of the project's architecture, technologies, and core logic for developers and AI agents.

## 🚀 Project Purpose
CepSepetiApp is a smart shopping assistant designed to help users track their grocery expenditures in real-time. By leveraging **On-Device OCR**, **Local Regex Parsing**, and **Cloud-based AI**, the app automatically extracts product names, brands, and prices from physical price tags, significantly reducing manual data entry and helping users manage their budget effectively.

---

## 🏗️ Architectural Overview
The project follows a modern **MVVM (Model-View-ViewModel)** architecture, integrated with **SwiftData** for persistent storage and **Asynchronous Programming (Swift Concurrency)** for high-performance image processing.

### Folder Structure
- **Models/**: Contains SwiftData entities and data transfer objects.
  - `ShoppingSession`: Persistent entity representing a shopping session (one-to-many relationship with `ShoppingItem`). Deleting a session deletes all its items (cascade).
  - `ShoppingItem`: Persistent entity representing a single item in the cart.
  - `OCRLog`: Persistent log for debugging OCR failures, storing raw text, success state, and decision traces.
  - `PriceTagData`: DTO representing parsed price tag details (name, price, brand, raw text, confidence score, execution trace).
  - `OCRResult`: Enum representing the processing result (`.success`, `.localFallback`, or `.failure`).
  - `PreviewDataGenerator`: Helper for SwiftUI Previews.
- **Services/**: Core logic layers for hardware interaction and external APIs.
  - `CameraService`: Manages photo capture using AVFoundation and `PhotoCaptureProcessor`.
  - `OCRService`: Uses Apple's **Vision Framework** (`VNRecognizeTextRequest`) for raw text extraction.
  - `LocalOCRParserService`: Entry point for local parsing using the strategy-based router.
  - `GeminiService`: Fallback service that orchestrates semantic analysis using **Google Gemini 2.5 Flash**.
  - `ImageProcessingPipeline`: Orchestrates the confidence-based flow between OCR, Local Parser, and Gemini.
  - **Parsers/**: Folder containing the strategy-based parsing engine.
    - `MarketParserStrategy`: Protocol defining requirements (`canParse`, `parse`) for market parsers.
    - `MarketParserStrategy+Defaults`: Extension providing default implementations for brand, name/size, and price extraction, alongside shared regexes and brand lists.
    - `MarketRouter`: Routes raw text to matching strategies (`A101Parser`, `FileParser`, `MigrosParser`, `SokParser`, `GenericParser`).
    - `A101Parser`: Special strategy for A101 tags.
    - `FileParser`: Special strategy for File Market tags.
    - `MigrosParser`: Special strategy for Migros tags.
    - `SokParser`: Special strategy for Şok tags.
    - `GenericParser`: Fallback strategy capped at 0.5 confidence.
- **ViewModels/**: Acts as the glue between UI and Services.
  - `AddItemViewModel`: Manages scanning and item confirmation flow.
  - `HomeViewModel`: Handles dashboard calculations and session lifecycle.
  - `StatisticsViewModel`: Aggregates session data for weekly expenditures, brand distribution, and insights.
- **Views/**: SwiftUI-based user interface components.
  - `MainTabView`: Root navigation container. Embeds `HomeView`, a camera trigger, and `StatisticsView` (which utilizes Swift Charts).
  - **Home/**:
    - `HomeView`: Main dashboard displaying monthly spending, active sessions, and shopping history.
    - `SessionDetailView`: Read-only list displaying items of a finalized shopping session.
  - **Scanner/**:
    - `ScannerView`: Directs camera preview and triggers scan.
    - `AddProductView`: Form sheet for confirming/editing scanned product details.
    - `CameraPreview`: UIKit wrapper for AVCaptureVideoPreviewLayer.
  - **Components/**:
    - `CartSheetView`: Swipeable sheet to inspect the current session's shopping cart.
  - `OCRLogView`: Interface for viewing, deleting, and exporting OCR debug logs via `ShareLink`.
  - `SettingsView`: Manages bulk history deletion, privacy info (KVKK/storage compliance), feedback, and legal links.

---

## 🛠️ Core Technologies

### 1. Vision Framework (Local OCR)
The app uses `VNRecognizeTextRequest` to process images locally. This ensures that the primary text extraction is fast and works offline. We use `.accurate` recognition level with Turkish locale support.

### 2. Strategy-based Local Parsing
Local parsing is structured as a Strategy pattern:
- **MarketRouter** processes the text sequentially through a list of strategies.
- Strategies like `A101Parser`, `FileParser`, `MigrosParser`, and `SokParser` identify specific market tags by looking for unique keywords.
- `GenericParser` acts as a final fallback.
- **Execution Tracing**: Every parsing step is added to an `executionTrace` string array to debug matches in the field.

### 3. Hybrid Extraction & Fallback Strategy
To maximize efficiency and reduce API costs:
- **Confidence Scoring**: Each local parser calculates a confidence score (0.0 - 1.0) based on name length, price validity, brand matching, and conflicts.
- **Fallback Threshold (0.5)**: If the local confidence is below **0.5**, and internet is available, the app falls back to **Gemini AI**.
- **Robust Recovery**: If Gemini fails or internet is unavailable, the pipeline falls back safely to the local results, alerting the user to review the fields.

### 4. Google Gemini AI (Semantic Parsing)
When local parsing confidence is low, Gemini 2.5 Flash is invoked as a fallback. It:
- Identifies product name and brand from messy OCR text.
- Extracts the actual selling price, ignoring unit prices.
- Corrects character errors (e.g., "M1lk" -> "Milk").
- Returns data strictly in JSON format matching `PriceTagData`.

### 5. SwiftData (Persistence)
All data is stored locally.
- **Relationships**: `ShoppingSession` cascades deletion to its child `ShoppingItem`s.
- **Logging**: `OCRLog` logs all OCR results for offline debugging.

---

## 💡 Technical Tips for AI Agents

### Working with the Camera
The `CameraService` uses a custom `PhotoCaptureProcessor`. Ensure the `CheckedContinuation` is resumed exactly once. Use `CameraPreview` for SwiftUI integration.

### Adding a New Market Parser Strategy
1. Create a new struct conforming to `MarketParserStrategy`.
2. Implement `canParse(rawText:)` to return true for tag-specific keywords.
3. Implement `parse(rawText:)` utilizing default methods from `MarketParserStrategy+Defaults` or custom overrides.
4. Add the strategy instance to the `strategies` array inside `MarketRouter.swift` (ensure `GenericParser` remains last).

### Modifying Brands or Units
Modify `SharedParserConstants` inside `MarketParserStrategy+Defaults.swift`:
- `brandNormalizations` for mapping typo-prone or shorthand brands to clean names.
- `invalidBrands` to ignore metadata keywords (like "KDV", "İNDİRİM").
- `validUnits` for units of measurement.

### Modifying AI Prompts
Prompt logic resides in `GeminiService.swift`. Only modify the prompt if the JSON structure of `PriceTagData` changes. Maintain the instruction for JSON-only output.

### State Management
UI state is managed via `@Observable` ViewModels.
- Use `StatisticsViewModel` for any new chart or data analysis features.
- Keep business logic out of Views; use the `ImageProcessingPipeline` for orchestration.

### Security
The Gemini API key is retrieved dynamically from `Secrets.plist`. Never hardcode keys or commit them to source control.

---

## 🔗 Key Interactions
1. `ScannerView` triggers `AddItemViewModel.captureAndProcess()`.
2. `CameraService` returns a `UIImage`.
3. `ImageProcessingPipeline` calls `OCRService` for raw text.
4. `LocalOCRParserService` attempts extraction and assigns a confidence score.
5. If confidence < 0.5 and network is available, `GeminiService` is called as a fallback.
6. If Gemini fails or network is offline, the pipeline recovers the local results under a fallback state.
7. Result is presented in `AddProductView` for user confirmation.
8. `confirmItem()` persists the data into `SwiftData` and logs the attempt in `OCRLog`.

---
*Documentation updated on May 23, 2026.*
