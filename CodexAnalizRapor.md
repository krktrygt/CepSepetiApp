# CepSepetiApp Codex Analiz Raporu

Tarih: 12 Temmuz 2026

Bu rapor, `codex.md` dosyasindaki baslangic talimatina uygun olarak kod degisikligi yapmadan once mevcut durumu analiz etmek icin hazirlandi. Analiz sirasinda mevcut kullanici degisikliklerine dokunulmadi.

## 1. Incelenen Dosyalar

- `CepSepetiApp/Models/ShoppingItem.swift`
- `CepSepetiApp/Models/ShoppingSession.swift`
- `CepSepetiApp/Models/PriceTagData.swift`
- `CepSepetiApp/Models/OCRResult.swift`
- `CepSepetiApp/ViewModels/AddItemViewModel.swift`
- `CepSepetiApp/Services/ImageProcessingPipeline.swift`
- `CepSepetiApp/Services/CameraService.swift`
- `CepSepetiApp/Services/OCRService.swift`
- `CepSepetiApp/Services/GeminiService.swift`
- `CepSepetiApp/Services/LocalOCRParserService.swift`
- `CepSepetiApp/Views/Scanner/ScannerView.swift`
- `CepSepetiApp/Views/Scanner/AddProductView.swift`
- `CepSepetiApp/Views/Components/CartSheetView.swift`
- `CepSepetiApp/CepSepetiAppApp.swift`
- `CepSepetiApp.xcodeproj/project.pbxproj`
- `CepSepetiAppTests/LocalOCRParserServiceTests.swift`
- `CepSepetiAppTests/OCRNoiseCleanerTests.swift`

## 2. Mevcut Veri Akisi

Mevcut akista kullanici tarama butonuna bastiginda `ScannerView`, `AddItemViewModel.captureAndProcess(context:)` fonksiyonunu cagiriyor. Bu fonksiyon ayni anda ikinci isleme izin vermemek icin `isProcessing` bayragini kullaniyor.

Akis su sekilde:

1. `CameraService.capturePhoto()` ile fotograf cekiliyor.
2. Fotograf `ImageProcessingPipeline.process(image:context:)` fonksiyonuna veriliyor.
3. `OCRService` Vision OCR ile metni cikariyor.
4. `LocalOCRParserService` metinden urun adi, fiyat ve marka tahmini uretiyor.
5. Local parser confidence degeri `0.5` ve ustundeyse local sonuc dogrudan kabul ediliyor.
6. Confidence dusukse internet kontrol ediliyor.
7. Internet varsa `GeminiService.parse(ocrText:)` cagriliyor.
8. Sonuc `AddProductView` icinde kullaniciya onay icin gosteriliyor.
9. Kullanici "Ekle" dediginde `AddItemViewModel.confirmItem(...)` yeni `ShoppingItem` olusturuyor.

Bu akista kullanici OCR/AI sonucu bitmeden yeni urun tarayamiyor. `ScannerView` islem sirasinda tam ekran loading gosteriyor ve tarama butonunu disable ediyor.

## 3. Kritik Bulgular

### 3.1. Marka Kaydi Eksik

`ShoppingItem` modelinde `brand` alani zaten var. Ancak `AddItemViewModel.confirmItem(...)` yeni urun olustururken `brand:` parametresini gecmiyor.

`AddProductView` marka bilgisini ek bilgi olarak gosteriyor, fakat `confirmItem` cagrisi sirasinda bu bilgi kayit akisina tasinmiyor.

Sonuc:

- OCR veya Gemini sonucu `brand = "Sleepy"` donse bile `ShoppingItem.brand` nil kalabilir.
- Asema 1 kapsamindaki en net hata budur.

### 3.2. brands.json Resource Entegrasyonu Eksik

Kok dizinde `brands.json` dosyasi var ve `jq empty brands.json` ile gecerli JSON oldugu dogrulandi. Ancak dosya git tarafindan izlenmiyor ve Xcode resource build phase icinde gorunmuyor.

`project.pbxproj` icinde yalnizca `Secrets.plist` explicit resource olarak ekli gorunuyor. `brands.json` icin herhangi bir `PBXFileReference` veya `PBXBuildFile` kaydi bulunmadi.

Not:

- Projede `BrandDatabase` veya `Bundle.main.url(forResource: "brands", withExtension: "json")` kullanan bir kod parcasi bulunamadi.
- Bu nedenle Asema 1'de iki konu ayrilmali: dosyayi app bundle'a eklemek ve ileride kullanilacak brand database entegrasyonunu planlamak.

### 3.3. Pipeline AI Merkezli Degil

`ImageProcessingPipeline` icinde local parser birincil karar verici olarak kullaniliyor. Confidence esigi gecilirse Gemini hic cagrilmiyor.

Bu mevcut durum, `codex.md` hedefiyle uyusmuyor. Hedef sistemde local parser yalnizca hizli on tahmin uretmeli, internet varsa AI nihai dogrulama motoru olmali.

Bu Asema 5 kapsaminda ele alinmali; Asema 1'de degistirilmemeli.

### 3.4. Kullanici AI Sonucunu Bekliyor

`ScannerView` icinde `viewModel.isProcessing` true oldugunda tam ekran loading gosteriliyor. Tarama butonu disabled oluyor.

Sonuc:

- Kullanici ilk urunun sonucu gelmeden ikinci urunu tarayamiyor.
- Gecici `ShoppingItem` veya queued/processing UI durumu yok.

Bu Asema 2, Asema 3 ve Asema 4 ile cozulecek.

### 3.5. Kalici Kuyruk Yok

Mevcut sistemde tarama isi SwiftData icinde kalici bir is olarak tutulmuyor. Fotograf yerel dosyaya kaydedilmiyor, `scanJobID` yok, queued/processing/completed/failed status yok.

Uygulama kapanirsa devam eden OCR/AI gorevinin guvenli sekilde yeniden baslatilmasini saglayan bir mekanizma bulunmuyor.

### 3.6. API Anahtari Bundle Icinde

`GeminiService`, Gemini API anahtarini `Secrets.plist` icinden okuyor. `Secrets.plist`, app resource build phase icinde yer aliyor.

Bu gelistirme asamasi icin calisabilir, ancak uretim hedefi icin riskli. `codex.md` uretim oncesi backend zorunlulugu belirtiyor.

Bu konu Asema 8 kapsaminda ele alinmali; Asema 1'de mevcut API mimarisi degistirilmemeli.

### 3.7. Testlerde Eksik Tip Riski

`CepSepetiAppTests/OCRNoiseCleanerTests.swift`, `OCRNoiseCleaner` tipini kullaniyor. App kaynaklari icinde `OCRNoiseCleaner` sinifi veya struct'i bulunamadi.

Bu nedenle testler calistirildiginda mevcut durumda derleme hatasi alinabilir. Asema 1 sonunda test calistirilirken bu risk acikca raporlanmali.

## 4. SwiftData Migration Riski

Asema 1 icin migration riski yok. Marka kaydi, mevcut `ShoppingItem.brand` alani kullanilarak duzeltilebilir.

Asema 2 ve sonrasi icin migration riski vardir. `ShoppingItem` modeline su alanlar eklendiginde mevcut kullanici verileri icin varsayilan degerler ve migration stratejisi gerekir:

- `processingStatusRaw`
- `scanJobID`
- `capturedImagePath`
- `rawOCRText`
- `localProductName`
- `localBrand`
- `localPrice`
- `aiConfidence`
- `processingError`
- `retryCount`
- `processingStartedAt`
- `processingCompletedAt`

Ozellikle `processingStatusRaw` ve `retryCount` gibi non-optional alanlar icin default deger planlanmadan model degisikligi yapilmamali.

## 5. MainActor ve Actor Izolasyonu Riskleri

`AddItemViewModel` `@MainActor` olarak isaretli. SwiftData `ModelContext` su anda bu view model ve UI akisi icinden kullaniliyor.

Gelecek kuyruk mimarisinde `ScanProcessingQueue` actor olarak tasarlanirsa actor icinden dogrudan `ModelContext` kullanilmamali. SwiftData islemleri `@MainActor` bir coordinator veya repository uzerinden yapilmali.

Mevcut `ImageProcessingPipeline.logOCR(...)` fonksiyonu async pipeline icinden `ModelContext` alarak insert/save yapiyor. Bu yapi yeni actor tabanli kuyruga tasinirken yeniden ele alinmali.

## 6. Gorsel Saklama Durumu

Mevcut sistemde kamera fotograflari kalici dosyaya yazilmiyor. `CameraService.capturePhoto()` sadece `UIImage` donduruyor ve pipeline bu image uzerinden calisiyor.

Yeni sistem icin fotograf cekildikten hemen sonra app'in yerel storage alanina kaydedilmeli. `ShoppingItem.capturedImagePath` veya job ID ile iliskili dosya yolu saklanmali. Bu, uygulama kapanip acildiginda yarim kalan islerin yeniden islenebilmesi icin gerekli.

## 7. Yanlis Eslesme ve Cift Isleme Riskleri

Mevcut akista is sonucu liste sirasi ile eslesmiyor; cunku ayni anda yalnizca tek is var ve urun kullanici onayindan sonra olusturuluyor.

Yeni sistemde ayni anda birden fazla is calisacagi icin sonuc mutlaka benzersiz `scanJobID` veya `ShoppingItem` ID'si ile eslestirilmeli. Liste sirasi veya aktif secim state'i uzerinden sonuc yazmak yanlis urune yazma riski dogurur.

## 8. Kirli Calisma Agaci

Analiz sirasinda `git status --short` su izlenmeyen ogeleri gosterdi:

- `.antigravitycli/`
- `OCRExamples.txt`
- `brands.json`
- `codex.md`

Bu dosyalara analiz sirasinda dokunulmadi. Bu rapor olusturulduktan sonra yeni izlenmeyen dosya olarak `CodexAnalizRapor.md` de calisma agacina eklenecektir.

## 9. Degistirilmesi Gereken Dosyalar

### Asema 1

- `CepSepetiApp/ViewModels/AddItemViewModel.swift`
- `CepSepetiApp/Views/Scanner/AddProductView.swift`
- `CepSepetiApp.xcodeproj/project.pbxproj` veya Xcode'un file system synchronized resource ayarina uygun proje konfigurasyonu
- Gerekirse `CepSepetiAppTests` altinda marka kaydini dogrulayan dar kapsamli test

### Asema 2 ve Sonrasi

- `CepSepetiApp/Models/ShoppingItem.swift`
- `CepSepetiApp/CepSepetiAppApp.swift`
- `CepSepetiApp/Views/Components/CartSheetView.swift`
- `CepSepetiApp/Views/Scanner/ScannerView.swift`
- `CepSepetiApp/ViewModels/AddItemViewModel.swift`
- `CepSepetiApp/Services/ImageProcessingPipeline.swift`
- `CepSepetiApp/Services/GeminiService.swift`
- `CepSepetiApp/Services/OCRService.swift`
- `CepSepetiApp/ViewModels/StatisticsViewModel.swift`
- `CepSepetiApp/Views/Home/SessionDetailView.swift`

## 10. Yeni Olusturulmasi Gereken Dosyalar

Yeni sistem ilerledikce su dosyalar gerekecek:

- `CepSepetiApp/Models/ItemProcessingStatus.swift`
- `CepSepetiApp/Models/ScanProcessingResult.swift`
- `CepSepetiApp/Models/ResultSource.swift`
- `CepSepetiApp/Services/ScanProcessingQueue.swift`
- `CepSepetiApp/Services/ScanProcessingCoordinator.swift`
- `CepSepetiApp/Services/Parsing/AIResultValidator.swift`
- `CepSepetiApp/Services/ImageStorageService.swift`
- Gerekirse `CepSepetiApp/Services/BrandDatabase.swift`

## 11. Uygulanabilir Ilk Asema Plani

Yalnizca Asema 1 uygulanmali:

1. `brands.json` dosyasinin app bundle resource listesine eklendigini garanti et.
2. OCR veya Gemini sonucundaki `brand` alaninin `ShoppingItem.brand` icine kaydedilmesini sagla.
3. Mevcut parser davranisini degistirme.
4. Kuyruk, status modeli veya SwiftData model migration baslatma.
5. Mevcut testleri silme veya zayiflatma.
6. Build veya test calistir.
7. Build/test calismazsa gercek nedeni raporla.

## 12. Asema 1 Kabul Kriterleri

- AI veya local parser sonucu `brand = "Sleepy"` ise kaydedilen `ShoppingItem.brand` de `"Sleepy"` olmali.
- `brands.json`, `Bundle.main.url(forResource: "brands", withExtension: "json")` ile app bundle icinden bulunabilir olmali.
- Mevcut parser testleri korunmali.
- Asema 2 kapsamindaki queue/status/model degisiklikleri yapilmamali.
- Degistirilen dosyalar ve build/test sonucu net sekilde raporlanmali.

---

## 13. Uygulama Guncellemesi: Asema 1-5

Tarih: 12 Temmuz 2026

Kullanicinin yeni talimatiyla sub-agent destekli inceleme yapildi ve Asema 5'e kadar olan cekirdek mimari uygulanmaya baslandi. Sub-agent'lar uc ayrik hatta inceleme yapti:

- SwiftData model ve migration riski
- Scanner, sepet UI ve gecici urun akisi
- Pipeline, Gemini ve local parser karar agaci

Kod degisiklikleri ana hatta entegre edildi.

### 13.1. Asema 1 Sonucu

- `brands.json` app bundle resource listesine eklendi.
- OCR/AI sonucundaki `brand`, `ShoppingItem.brand` alanina kaydediliyor.
- Mevcut parser testleri silinmedi veya zayiflatilmadi.
- Eksik `OCRNoiseCleaner` tipi eklendi ve mevcut testlerin derlenmesi saglandi.

### 13.2. Asema 2 Sonucu

`ShoppingItem` su isleme alanlariyla genisletildi:

- `processingStatusRaw`
- `scanJobID`
- `capturedImagePath`
- `rawOCRText`
- `localProductName`
- `localBrand`
- `localPrice`
- `aiConfidence`
- `processingError`
- `retryCount`
- `processingStartedAt`
- `processingCompletedAt`

`ItemProcessingStatus` enum'u eklendi:

- `queued`
- `processing`
- `completed`
- `needsReview`
- `failed`

Mevcut initializer cagrilarinin bozulmamasi icin default durum `completed` olarak tutuldu. Bu, mevcut kayitlarin yanlislikla pending/queued gorunmesini engellemek icin secildi.

Migration notu:

- Alanlar modele eklendi, ancak explicit `SchemaMigrationPlan` henuz yazilmadi.
- Uygulama daha once kalici kullanici verisiyle dagitildiysa, uretim oncesinde versioned schema ve migration plan ayrica ele alinmali.

### 13.3. Asema 3 Sonucu

Yeni tarama akisi su hale getirildi:

1. Kullanici fotograf ceker.
2. Fotograf yerel dosya sistemine kaydedilir.
3. `ShoppingItem` hemen `queued` durumuyla sepete eklenir.
4. Kamera AI sonucunu beklemeden yeniden kullanilabilir olur.
5. Sonuc arka planda ayni `scanJobID` uzerinden item'a yazilir.

`ImageStorageService`, tarama gorsellerini `Documents/ScanImages` altina JPEG olarak kaydeder.

### 13.4. Asema 4 Sonucu

Kalici kaynak `ShoppingItem` olacak sekilde kuyruk mimarisi eklendi:

- `ScanProcessingQueue` actor olarak eklendi.
- Ayni anda en fazla iki is calistiracak sekilde tasarlandi.
- Ayni `scanJobID` icin duplicate calisma engellendi.
- `ScanProcessingCoordinator`, SwiftData yazimlarini `@MainActor` sinirinda tutar.
- Uygulama/ekran acilisinda `queued` ve `processing` item'lar tekrar kuyruğa alinabilir.

Not:

- Kuyrugun RAM kismi yalnizca calisan/pending job siralamasini tutar.
- Kalici yeniden baslatma bilgisi `ShoppingItem.scanJobID`, `capturedImagePath` ve `processingStatusRaw` alanlarinda saklanir.

### 13.5. Asema 5 Sonucu

`ImageProcessingPipeline` karar agaci degistirildi:

Eski davranis:

- Local parser confidence >= 0.5 ise Gemini cagrilmiyordu.

Yeni davranis:

1. Vision OCR ham metni uretir.
2. Local parser hizli aday uretir.
3. Internet varsa Gemini her zaman nihai dogrulama icin cagrilir.
4. Internet yoksa veya Gemini hata verirse local sonuc `localOffline` olarak kullanilir ve inceleme gerektirir.

`GeminiService.parse(...)` geriye uyumlu kalacak sekilde `localCandidate` parametresi alabilir hale getirildi. AI prompt'una local aday baglami eklendi.

### 13.6. Sepet UI Guncellemesi

`CartSheetView` artik item durumuna gore farkli gosterim yapar:

- `queued`: Sirada
- `processing`: Analiz ediliyor
- `needsReview`: Sonucu kontrol edin
- `failed`: Urun analiz edilemedi
- `completed`: Normal urun satiri

Toplam tutar yalnizca `completed` item'lardan hesaplanir. Pending/failed/needsReview item varken alisverisi bitirme butonu pasif tutulur.

### 13.7. Degisen Dosyalar

Degistirilen mevcut dosyalar:

- `CepSepetiApp.xcodeproj/project.pbxproj`
- `CepSepetiApp/Models/ShoppingItem.swift`
- `CepSepetiApp/Services/GeminiService.swift`
- `CepSepetiApp/Services/ImageProcessingPipeline.swift`
- `CepSepetiApp/Services/LocalOCRParserService.swift`
- `CepSepetiApp/ViewModels/AddItemViewModel.swift`
- `CepSepetiApp/Views/Components/CartSheetView.swift`
- `CepSepetiApp/Views/Scanner/AddProductView.swift`
- `CepSepetiApp/Views/Scanner/ScannerView.swift`

Yeni dosyalar:

- `CepSepetiApp/Models/ItemProcessingStatus.swift`
- `CepSepetiApp/Models/ResultSource.swift`
- `CepSepetiApp/Models/ScanProcessingResult.swift`
- `CepSepetiApp/Services/ImageStorageService.swift`
- `CepSepetiApp/Services/OCRNoiseCleaner.swift`
- `CepSepetiApp/Services/ScanProcessingCoordinator.swift`
- `CepSepetiApp/Services/ScanProcessingQueue.swift`

### 13.8. Dogrulama Sonuclari

Calistirilan komutlar:

- `jq empty brands.json`
- `xcodebuild build -scheme CepSepetiApp -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/CepSepetiAppDerivedData`
- `xcodebuild build-for-testing -scheme CepSepetiApp -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/CepSepetiAppDerivedData`
- `xcodebuild test -scheme CepSepetiApp -destination 'id=A2EDD404-3BC3-4D2D-BB98-F4ED3B5C3482' -derivedDataPath /private/tmp/CepSepetiAppDerivedData`

Sonuc:

- Build basarili.
- Test build basarili.
- Tam test kosusu basarili.
- `LocalOCRParserServiceTests` basarili.
- `OCRNoiseCleanerTests` basarili.

Bilinen uyari:

- Xcode asset catalog uyarisi devam ediyor: `Accent color 'AccentColor' is not present in any asset catalogs.`

### 13.9. Kalan Riskler

- Explicit SwiftData migration plan henuz eklenmedi.
- `needsReview` ve `failed` durumlari gorunur, ancak manuel duzenleme/retry UI akisi Asema 6 kapsaminda gelistirilmeli.
- AI sonucu validator katmani henuz eklenmedi; Asema 6'da `AIResultValidator` ile tamamlanmali.
- Backend/API anahtari guvenligi Asema 8 kapsaminda aynen acik risk olarak duruyor.
