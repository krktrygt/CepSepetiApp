# CepSepeti 🛒
### Akıllı Market Alışveriş Asistanı & Hibrit OCR Fiyat Etiketi Tarayıcısı
**Smart Grocery Shopping Assistant with On-Device OCR & AI Verification**

[![Swift](https://img.shields.io/badge/Swift-5.10%20%7C%206.0-orange.svg?style=flat&logo=swift)](https://developer.apple.com/swift/)
[![iOS](https://img.shields.io/badge/iOS-18.0%2B-blue.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg?style=flat)](https://developer.apple.com/xcode/swiftui/)
[![SwiftData](https://img.shields.io/badge/Storage-SwiftData-green.svg?style=flat)](https://developer.apple.com/documentation/swiftdata)
[![Vision](https://img.shields.io/badge/Framework-Apple%20Vision-lightgrey.svg?style=flat)](https://developer.apple.com/documentation/vision)
[![Gemini](https://img.shields.io/badge/AI-Google%20Gemini%202.5%20Flash-blueviolet.svg?style=flat)](https://ai.google.dev/)

---

## 📌 Proje Genel Bakışı (Overview)

**CepSepeti**, fiziksel market alışverişlerinde bütçe takibini zahmetsiz ve akıcı hale getirmek amacıyla geliştirilmiş yerel bir iOS uygulamasıdır. Kullanıcıların raf etiketlerinin fotoğraflarını çekerek anında sepet tutarlarını görmelerini sağlar.

Geleneksel tarama uygulamalarının aksine, **CepSepeti** kullanıcının fotoğraf çekildikten sonra saniyelerce ekranda beklemesini engeller. Geliştirilen **Asenkron Hibrit Boru Hattı (Hybrid Vision Pipeline)** sayesinde:
1. Etiket fotoğrafı çekildiği anda sepete **"Analiz ediliyor..."** durumuyla geçici ürün olarak eklenir.
2. Kamera vizörü anında tekrar açılır; kullanıcı peş peşe etiket taramaya devam edebilir.
3. Arka planda **Apple Vision OCR**, **Yerel Regex/Heuristic Motoru** ve **Google Gemini AI** kademeli olarak çalışarak ürünü doğrular ve sepet kartını otomatik günceller.

---

## 🏗️ Mimari & Hibrit İşleme Hattı (Pipeline Architecture)

Uygulama modern **MVVM (Model-View-ViewModel)** desenini, **Swift Concurrency (async/await, Actors)** ve **SwiftData** kalıcılık katmanını kullanır.

```
[ Kamera / Deklanşör ] 
         │ (Kamera anında serbest kalır)
         ▼
[ ScanProcessingCoordinator ] ──► [ SwiftData: ShoppingItem (.queued) ]
         │
         ▼
[ ScanProcessingQueue (Actor, Concurrency: 2) ]
         │
         ├──► 1. Apple Vision Framework (Cihaz İçi Yerel OCR - Hızlı & Çevrimdışı)
         │
         ├──► 2. LocalOCRParserService (Regex, Birim Fiyat / Satış Fiyatı Ayırma, Marka Normalizasyonu)
         │
         ├──► 3. Ağ & Bağlantı Kontrolü (NWPathMonitor)
         │         ├─► [İnternet Var]: Google Gemini 2.5 Flash Doğrulaması
         │         │         │
         │         │         ▼
         │         │   [ AIResultValidator ] (Tutarlılık & Fiyat Sınır Kontrolü)
         │         │
         │         └─► [İnternet Yok veya API Hatası]: Güvenli Yerel Fallback (.localOffline)
         │
         ▼
[ SwiftData Güncellemesi: .completed / .needsReview / .failed ]
         │
         ▼
[ CartSheetView & Sesion Özeti Güncellemesi ]
```

### 1. Neden Hibrit Yaklaşım?
* **Maliyet & Hız Tasarrufu:** Her görüntüyü doğrudan bulut LLM modeline göndermek yüksek maliyet, ağ gecikmesi ve market bodrum katlarında bağlantı kopması demektir.
* **Cihaz İçi Ön İşleme:** Metin önce Apple'ın optimize `VNRecognizeTextRequest` API'siyle cihazda okunur.
* **Akıllı Doğrulama:** Regex ile ayrıştırılan adaylar, internet erişimi olduğunda Google Gemini 2.5 Flash'a bağlam (context) olarak iletilir. Model yalnızca nihai anlamsal eşleştirmeyi (satış fiyatı, ürün adı, marka) JSON formatında onaylar.

---

## ✨ Temel Özellikler (Key Features)

- ⚡ **Non-Blocking Asenkron Tarama:** Fotoğraf çekiminde tam ekran yükleme animasyonuyla ekran kilitlenmez. Kullanıcı art arda ürün okutabilir.
- 🎯 **Akıllı Fiyat & Birim Fiyat Ayrımı:** Raf etiketlerindeki birim fiyatları (örn. `140 TL/KG`) eler, asıl satış fiyatını (`35,00 TL`) tespit eder.
- 🏷️ **2400+ Marka Tanıma Kütüphanesi:** `brands.json` kaynak entegrasyonu ve Levenshtein toleranslı marka normalizasyonu.
- 📶 **Çevrimdışı Dayanıklılık (Offline-First):** İnternet kesilse bile uygulama çökmez; yerel tahmin `.needsReview` bayrağıyla sepette tutulur, kullanıcıya manuel onay imkânı sunar.
- 🛒 **Güvenli Sepet Onayı (ShoppingCartSummary):** Analizi devam eden veya şüpheli ürünler varken alışverişin yanlış eksik toplamla bitirilmesi engellenir.
- 📊 **Harcama Grafikleri & Analitik:** `Swift Charts` ile haftalık harcama dökümü, en çok tercih edilen markalar dağılımı (Donut Chart) ve bütçe içgörüleri.
- 🛠️ **OCR Log & Debugging:** Hatalı okumaları tespit etmek amacıyla `OCRLog` modeli üzerinden tüm denemeler ve karar adımları kaydedilir; `ShareLink` ile dışa aktarılabilir.
- 🔒 **KVKK & Veri Gizliliği:** Kişisel veri toplanmaz, tüm alışveriş geçmişi `SettingsView` üzerinden tek tıkla cihazdan kalıcı olarak silinebilir.

---

## 📂 Proje Klasör Yapısı (Directory Structure)

```text
CepSepetiApp/
├── Models/
│   ├── ShoppingSession.swift         # Alışveriş oturumu kalıcı modeli (Cascade delete)
│   ├── ShoppingItem.swift            # Sepet ürünü, scanJobID ve durum modeli
│   ├── ItemProcessingStatus.swift    # queued, processing, needsReview, completed, failed
│   ├── ShoppingCartSummary.swift     # Kesinleşen vs tahmini sepet toplam hesaplamaları
│   ├── ScanProcessingResult.swift    # Pipeline sonuç DTO'su
│   ├── PriceTagData.swift            # Ayrıştırılmış etiket verisi
│   └── OCRLog.swift                  # SwiftData debug log kaydı
├── Services/
│   ├── CameraService.swift           # AVFoundation kamera akışı, fener ve odak kilitleme
│   ├── OCRService.swift              # Apple Vision Framework metin tanıma
│   ├── LocalOCRParserService.swift   # Yerel Regex, birim fiyat filtresi ve marka normalizasyonu
│   ├── GeminiService.swift           # Google Gemini 2.5 Flash REST istemcisi
│   ├── ImageProcessingPipeline.swift # OCR, Local Parser ve Gemini orkestrasyonu
│   ├── ScanProcessingCoordinator.swift# SwiftUI - Queue - SwiftData köprüsü
│   ├── ScanProcessingQueue.swift     # Swift Actor tabanlı eşzamanlı iş kuyruğu (max 2)
│   ├── AIResultValidator.swift       # AI çıktısı sınır & saçmalık denetimi
│   ├── OCRPreflightValidator.swift   # Boş/anlamsız görüntü ön filtreleme
│   └── ImageStorageService.swift     # Çekilen fotoğrafların yerel disk önbelleği
├── ViewModels/
│   ├── AddItemViewModel.swift        # Deklanşör tetikleme ve UI durum yönetimi
│   ├── HomeViewModel.swift           # Aylık toplam harcama ve oturum yaşam döngüsü
│   └── StatisticsViewModel.swift     # Swift Charts analitik hesaplamaları
├── Views/
│   ├── MainTabView.swift             # Kök sekme navigasyonu
│   ├── Scanner/
│   │   ├── ScannerView.swift         # Canlı kamera vizörü, dinamik sepet rozeti
│   │   ├── CameraPreview.swift       # AVCaptureVideoPreviewLayer UIViewRepresentable sarmalayıcısı
│   │   └── AddProductView.swift      # Manuel ürün düzenleme ve onay formu
│   ├── Components/
│   │   └── CartSheetView.swift       # Dinamik durumlu sepet listesi ve onay akışı
│   ├── Home/
│   │   ├── HomeView.swift            # Ana dashboard ve geçmiş alışverişler
│   │   └── SessionDetailView.swift   # Tamamlanmış sepet salt-okunur detay ekranı
│   ├── OCRLogView.swift              # Hata ayıklama logları ve dışa aktarım
│   └── SettingsView.swift            # Veri silme ve yasal bağlantılar
├── Standalone-HybridVisionPipeline/   # Çekirdek pipeline mantığının modüler Swift Paketi
└── CepSepetiAppTests/                # XCTest birim test paketi
```

---

## 🔍 Mevcut Durum & Olası Hatalar (Current Status & Known Edge Cases)

Teknik mülakatlarda ve gerçek saha testlerinde şeffaflık önemlidir. Uygulamanın bilinen sınırları ve gelecekte geliştirilebilecek alanları şunlardır:

### 1. Çoklu & İndirimli Fiyat Etiketleri (Conflicting Prices)
- **Durum:** Bazı market etiketlerinde aynı anda *Eski Fiyat*, *İndirimli Fiyat*, *Sadakat Kartı Fiyatı* ve *Birim Fiyat (KG/LT)* yan yana yer alır.
- **Mevcut Davranış:** Yerel parser birim fiyatları filtreler ve en olası satış fiyatını arar; Gemini AI ise bağlamdan asıl satış fiyatını seçer.
- **Olası Hata:** Etiket üzerindeki çizili eski fiyat ile indirimli fiyatın font boyutları birbirine çok yakınsa veya OCR satırları birbirine girdiyse nadiren eski fiyat okunabilir. Böyle durumlarda güven skoru düşürülerek ürün `.needsReview` ("Kontrol Bekliyor") durumuna alınır.

### 2. Bodrum Katı / Zayıf Hücresel Bağlantı (Underground Connectivity)
- **Durum:** Süpermarketler sıklıkla alışveriş merkezlerinin veya binaların bodrum katlarındadır.
- **Mevcut Davranış:** `ImageProcessingPipeline`, `NWPathMonitor` ve URLSession zaman aşımı kontrolleriyle internetin olmadığını anında fark eder ve beklemeden `.localOffline` sonucuna döner.
- **Olası Hata:** Yerel parser, AI kadar güçlü bir anlamsal düzeltme yeteneğine sahip olmadığı için Türkçe karakter bozulmalarını her zaman kusursuz toparlayamayabilir.

### 3. Işık Yansıması & Barkod Paraziti
- **Durum:** Parlak kuşe kağıda basılmış etiketlerde veya plastik etiketliklerde kamera flaşı parlama yapabilir.
- **Mevcut Davranış:** `OCRNoiseCleaner` uzun barkod dizilerini ve sistem loglarını temizler. `CameraService` ise deklanşöre basıldığı an donanım odağını ve pozlamasını kilitler.

---

## 🚀 Kurulum & Çalıştırma (Getting Started)

### Gereksinimler
- **macOS Sequoia 15.0+**
- **Xcode 16.0+**
- **iOS 18.0+** (Kamera ve Vision doğrulaması için fiziksel cihaz önerilir)
- Ücretsiz bir **[Google AI Studio Gemini API Key](https://aistudio.google.com/)**

### Adım Adım Kurulum

1. **Repoyu Klonlayın:**
   ```bash
   git clone https://github.com/korkuteryigit/CepSepetiApp.git
   cd CepSepetiApp
   ```

2. **API Anahtarını Yapılandırın:**
   Repo gizliliği gereği gerçek `Secrets.plist` Git takibinde değildir. Proje kökündeki örnek dosyayı kopyalayın:
   ```bash
   cp Secrets.example.plist Secrets.plist
   ```
   `Secrets.plist` dosyasını açıp kendi Gemini API anahtarınızı yapıştırın:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>GEMINI_API_KEY</key>
       <string>BURAYA_GEMINI_API_ANAHTARINIZI_YAZIN</string>
   </dict>
   </plist>
   ```

3. **Projeyi Açın ve Çalıştırın:**
   ```bash
   open CepSepetiApp.xcodeproj
   ```
   - Hedef simülatör veya cihazı seçin (Örn: `iPhone 16 Pro`).
   - `Cmd + B` ile projeyi derleyin, `Cmd + R` ile çalıştırın.

---

## 🧪 Test Stratejisi (Testing)

Proje, kritik veri ayrıştırma ve sepet güvenliği mantıklarını güvence altına alan birim testlerine sahiptir:
- `AIResultValidatorTests.swift`: Negatif fiyatlar, boş ürün isimleri ve sınır durum testleri.
- `ShoppingCartSummaryTests.swift`: Analiz edilen veya onay bekleyen ürünlerin kesinleşen toplama sızmadığının doğrulanması.
- `OCRNoiseCleanerTests.swift`: Sistem logları, barkodlar ve etiket dipnotlarının filtrelenme testleri.
- `LocalOCRParserServiceTests.swift`: Farklı market senaryolarında birim fiyat / satış fiyatı ayrıştırma testleri.

Testleri çalıştırmak için Xcode menüsünden **Product -> Test** (`Cmd + U`) seçeneğini kullanabilirsiniz.

---

## 📄 Lisans (License)

Bu proje eğitim, portföy ve açık kaynak paylaşım amacıyla geliştirilmiştir. MIT Lisansı kapsamında lisanslanmıştır. Detaylar için [LICENSE](CepSepetiApp/Standalone-HybridVisionPipeline/LICENSE) dosyasına göz atabilirsiniz.
